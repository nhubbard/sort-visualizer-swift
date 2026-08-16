import Foundation
import Metal
import MetalKit
import QuartzCore
import SortEngineKit

/// Persistent `MTLBuffer` of per-bar instance data (`BarInstance`, layout-matched to
/// `BarRenderer.metal`'s struct of the same name) written incrementally — only touched indices'
/// slots — then drawn with one instanced draw call per frame. The GPU still redraws every bar
/// every frame regardless (no partial-redraw concept for a draw call); the incrementality is
/// purely in the CPU-side write.
///
/// Works in PIXEL space throughout, not points (unlike `MetalShapeRenderer`'s layouts): `MTKView`'s
/// drawable is sized in backing-store pixels, so `reset`/`apply` take points + scale and convert
/// internally to match.
@MainActor
final class MetalBarRenderer: NSObject, MetalIncrementalRenderer {
  /// `value` is the bar's raw underlying value (eased, not a precomputed screen position) —
  /// `bar_vertex` derives `barWidth`/`height`/`origin`/`size` itself from this plus
  /// `MetalAnimationUniforms`'s `arrayCount`/`valueRangeLowerBound`/`valueRangeSpan`, the same
  /// formula `writeBar` used to compute on the CPU once per touched index per operation. First of
  /// this app's per-operation geometry-layout formulas moved fully onto the GPU — see
  /// `general_renderer_optimization_and_gpu_offload_scope`'s scoping notes for why Bar (no trig,
  /// position depends only on its own index/value, no cross-slot dependency) was chosen as the
  /// proof of concept ahead of the other 14 visualizer layouts.
  struct BarInstance {
    var value: AnimatedFloat
    var color: AnimatedMarkerColor
  }

  private let device: MTLDevice
  private let commandQueue: MTLCommandQueue
  private let pipelineState: MTLRenderPipelineState
  private var instanceBuffer: MTLBuffer?
  private var count = 0
  private var lastCanvasSize: CGSize = .zero
  private var lastScale: CGFloat = 1
  /// Persisted so `encodeDraw` can fill `MetalAnimationUniforms.valueRangeLowerBound`/`.valueRangeSpan`
  /// at DRAW time — now that geometry is resolved in the shader (not precomputed per-write on the
  /// CPU), `valueRange` has to survive from `reset`/`apply` until the next actual draw call.
  private var lastValueRange: ClosedRange<Int> = 0...0
  /// Pixel-space canvas size — `lastCanvasSize (points) * lastScale`, recomputed on every
  /// `reset`. All bar geometry and the shader's viewport uniform work in this space directly.
  private var pixelSize: CGSize = .zero

  private let colorTransitions = MetalMarkerColorTracker()
  private let valueTransitions = MetalScalarTransitionTracker()
  /// Session-relative clock, reset alongside every tracker in `reset()` — see `now()`'s own doc
  /// comment for why this isn't raw `CACurrentMediaTime()`.
  private var timeEpoch: CFTimeInterval = CACurrentMediaTime()

  /// Seconds since this renderer's last `reset()`, fed to both `MetalPositionTransitionTracker`/
  /// `MetalMarkerColorTracker` (to stamp `startTime`) and the vertex shader's `currentTime`
  /// uniform. NOT raw `CACurrentMediaTime()`: that's seconds-since-boot, which on a
  /// long-uptime device can be a six-digit number — `Float`'s ~7 significant digits would then
  /// leave a `currentTime - startTime` subtraction with precision comparable to the 0.12s
  /// transition duration itself, causing visible jitter. Resetting the epoch on every `reset()`
  /// keeps the magnitude small for the common case (a run lasting seconds to a couple minutes).
  private func now() -> Float { Float(CACurrentMediaTime() - timeEpoch) }

  /// `var`, not `let`: `MetalRendererView.Coordinator.setColorScheme` flips this between a
  /// light-mode and dark-mode value, since a near-white "no marker" default vanishes into a
  /// light-mode canvas the same way it would have vanished into the transparent-canvas bug Light
  /// Mode support fixed. `primaryColor`/`secondaryColor` stay fixed — both are saturated enough
  /// to read against either backdrop.
  static var defaultColor = SIMD4<Float>(0.82, 0.82, 0.86, 1)
  private static let primaryColor = SIMD4<Float>(0.95, 0.38, 0.38, 1)
  private static let secondaryColor = SIMD4<Float>(0.38, 0.58, 0.95, 1)

  /// `nil` if this device can't build the pipeline (no Metal support, or a missing shader
  /// function). Callers should fall back to a different backend rather than force-unwrap.
  ///
  /// `sampleCount` defaults to `1` (no MSAA) so tests driving `encodeDraw` against a plain,
  /// non-multisampled offscreen texture keep working — a pipeline's `rasterSampleCount` must
  /// exactly match whatever render pass it's encoded into, or Metal fails validation.
  /// `MetalRendererView` is the only caller that passes a real value.
  init?(device: MTLDevice, sampleCount: Int = 1) {
    guard let queue = device.makeCommandQueue() else { return nil }
    // `device.makeDefaultLibrary()` (no bundle argument) looks in `Bundle.main` — the host app's
    // bundle, not the framework's. `BarRenderer.metal` compiles into `SortFeature.framework`'s own
    // bundle, so that overload always returns `nil` here; `makeDefaultLibrary(bundle:)` with this
    // type's own bundle is required instead.
    guard
      let library = try? device.makeDefaultLibrary(bundle: Bundle(for: MetalBarRenderer.self)),
      let vertexFunction = library.makeFunction(name: "bar_vertex"),
      let fragmentFunction = library.makeFunction(name: "bar_fragment")
    else { return nil }

    let descriptor = MTLRenderPipelineDescriptor()
    descriptor.vertexFunction = vertexFunction
    descriptor.fragmentFunction = fragmentFunction
    descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
    descriptor.colorAttachments[0].isBlendingEnabled = true
    descriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
    descriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
    descriptor.rasterSampleCount = sampleCount

    guard let pipelineState = try? device.makeRenderPipelineState(descriptor: descriptor) else {
      return nil
    }

    self.device = device
    self.commandQueue = queue
    self.pipelineState = pipelineState
    super.init()
  }

  func reset(
    values: [Int], valueRange: ClosedRange<Int>, markers: [Int: Set<Int>],
    canvasSize: CGSize, scale: CGFloat
  ) {
    lastCanvasSize = canvasSize
    lastScale = scale
    lastValueRange = valueRange
    pixelSize = CGSize(width: canvasSize.width * scale, height: canvasSize.height * scale)
    count = values.count
    // A fresh full repaint (new run, resize, scrub) is a one-time state reset, not the
    // rapid-flashing case these trackers exist to smooth — start them clean too.
    colorTransitions.reset()
    valueTransitions.reset()
    timeEpoch = CACurrentMediaTime()

    guard count > 0, pixelSize.width > 0, pixelSize.height > 0 else {
      instanceBuffer = nil
      return
    }
    guard
      let buffer = device.makeBuffer(
        length: MemoryLayout<BarInstance>.stride * count, options: .storageModeShared)
    else {
      instanceBuffer = nil
      return
    }
    instanceBuffer = buffer

    for index in values.indices {
      writeBar(index: index, values: values, valueRange: valueRange, markers: markers)
    }
  }

  func apply(
    _ operation: SortOperation, values: [Int], valueRange: ClosedRange<Int>,
    markers: [Int: Set<Int>]
  ) {
    guard instanceBuffer != nil, values.count == count else { return }
    lastValueRange = valueRange

    guard let touched = operation.touchedIndices else {
      // `.unmark`/`.unmarkAll` — could affect any index; only a full repaint is correct.
      // `lastCanvasSize`/`lastScale` (not `pixelSize` — that's already the derived product
      // of the two, and can't be un-multiplied back into them) are exactly what the
      // previous `reset` call was given, so this reproduces it unchanged.
      reset(
        values: values, valueRange: valueRange, markers: markers, canvasSize: lastCanvasSize,
        scale: lastScale)
      return
    }
    guard !touched.isEmpty else { return }

    for index in touched where values.indices.contains(index) {
      writeBar(index: index, values: values, valueRange: valueRange, markers: markers)
    }
  }

  /// Only eases the bar's raw underlying VALUE now — `bar_vertex` (`BarRenderer.metal`) derives
  /// `barWidth`/`normalizedHeight`/`height`/`origin`/`size` itself from that value plus
  /// `MetalAnimationUniforms`'s `arrayCount`/`valueRangeLowerBound`/`valueRangeSpan`
  /// (`encodeDraw` fills those from `count`/`lastValueRange`), the exact formula this method used
  /// to compute on the CPU. Bars anchored at the bottom in a top-left-origin, +Y-down point space
  /// — see `BarRenderer.metal`'s own comment for how that maps to Metal's +Y-up NDC.
  private func writeBar(
    index: Int, values: [Int], valueRange: ClosedRange<Int>, markers: [Int: Set<Int>]
  ) {
    guard let instanceBuffer, count > 0 else { return }
    let n = now()

    let bar = BarInstance(
      value: valueTransitions.valueToWrite(forSlot: index, target: Float(values[index]), now: n),
      color: colorTransitions.valueToWrite(
        forSlot: index, marker: MetalShapeColor.markerKind(forIndex: index, in: markers), now: n)
    )
    instanceBuffer.contents()
      .advanced(by: index * MemoryLayout<BarInstance>.stride)
      .storeBytes(of: bar, as: BarInstance.self)
  }

  /// Fired from `mtkView(_:drawableSizeWillChange:)` below with the drawable's real pixel size
  /// — the authoritative "you now have somewhere real to render" signal, since
  /// `MetalRendererView.updateUIView` can run before `MTKView` has ever been laid out (drawable
  /// size still `.zero` at that point) with no guarantee SwiftUI calls it again once real
  /// layout happens. Relying on `updateUIView`'s own polling alone left the buffer permanently
  /// `nil` in exactly that case — nothing else drew on screen because nothing had ever `reset`.
  var onDrawableSizeChange: ((CGSize) -> Void)?

  // MARK: - MTKViewDelegate

  nonisolated func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
    MainActor.assumeIsolated {
      onDrawableSizeChange?(size)
    }
  }

  nonisolated func draw(in view: MTKView) {
    MainActor.assumeIsolated {
      guard
        let drawable = view.currentDrawable,
        let passDescriptor = view.currentRenderPassDescriptor,
        let commandBuffer = commandQueue.makeCommandBuffer()
      else { return }

      encodeDraw(into: passDescriptor, commandBuffer: commandBuffer)
      commandBuffer.present(drawable)
      commandBuffer.commit()

      // `MTKView` is normally `isPaused = true`/`enableSetNeedsDisplay = true` (see
      // `MetalRendererView`), redrawing only when told to. While a transition is in flight,
      // flip to MetalKit's own capped display link (`preferredFramesPerSecond`) instead of
      // manually re-arming `setNeedsDisplay()` every frame — unconditional re-arming redraws at
      // full uncapped refresh rate for the sort's whole duration, competing with SwiftUI's own
      // frame commits on the main thread and visibly slowing unrelated UI animations. Return to
      // paused once everything settles.
      let n = now()
      if colorTransitions.isActive(now: n) || valueTransitions.isActive(now: n) {
        if view.isPaused { view.isPaused = false }
      } else if !view.isPaused {
        view.isPaused = true
      }
    }
  }

  /// The actual draw-call encoding, pulled out of `draw(in:)` so it can be driven against an
  /// offscreen render target in a test — no `MTKView`/live drawable required — for empirical,
  /// pixel-readback diagnosis instead of guessing from GPU pipeline setup alone. Not `private`
  /// for exactly that reason: `@testable import` can see `internal`, never `private`.
  func encodeDraw(into passDescriptor: MTLRenderPassDescriptor, commandBuffer: MTLCommandBuffer) {
    encodeDraw(into: passDescriptor, commandBuffer: commandBuffer, currentTime: now())
  }

  /// Test-only overload: lets a shader-parity test pin `currentTime` to an exact probe value
  /// instead of racing a live wall clock, so it can assert the vertex shader's `resolveAnimated2`/
  /// `resolveAnimated4` resolve to the expected value at `t=startTime`, `t=startTime+duration/2`,
  /// and `t=startTime+duration` precisely.
  func encodeDraw(
    into passDescriptor: MTLRenderPassDescriptor, commandBuffer: MTLCommandBuffer,
    currentTime: Float
  ) {
    guard
      let buffer = instanceBuffer, count > 0,
      let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: passDescriptor)
    else { return }

    encoder.setRenderPipelineState(pipelineState)
    encoder.setVertexBuffer(buffer, offset: 0, index: 0)
    // `useHueRamp: 0` — Bar never hue-ramps, always one of primary/secondary/`defaultColor`
    // (`resolveAnimatedMarkerColor` in `AnimatedField.h`, not `resolveAnimatedColorSource`, is
    // what `bar_vertex` actually calls, so this uniform's `useHueRamp` field isn't even read on
    // this path — set for consistency with the shared struct, not because it's consulted).
    var uniforms = MetalAnimationUniforms(
      viewportSize: SIMD2(Float(pixelSize.width), Float(pixelSize.height)),
      currentTime: currentTime, transitionDuration: Float(transitionDuration), useHueRamp: 0,
      primaryColor: Self.primaryColor, secondaryColor: Self.secondaryColor,
      neutralColor: Self.defaultColor, arrayCount: Float(count),
      valueRangeLowerBound: Float(lastValueRange.lowerBound),
      valueRangeSpan: Float(lastValueRange.upperBound - lastValueRange.lowerBound),
      scale: Float(lastScale), geometryKind: -1)
    encoder.setVertexBytes(&uniforms, length: MemoryLayout<MetalAnimationUniforms>.stride, index: 1)
    encoder.drawPrimitives(
      type: .triangleStrip, vertexStart: 0, vertexCount: 4, instanceCount: count)
    encoder.endEncoding()
  }
}
