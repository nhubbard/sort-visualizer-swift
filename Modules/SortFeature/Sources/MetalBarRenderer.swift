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
  struct BarInstance {
    var origin: SIMD2<Float>
    var size: SIMD2<Float>
    var color: SIMD4<Float>
  }

  private let device: MTLDevice
  private let commandQueue: MTLCommandQueue
  private let pipelineState: MTLRenderPipelineState
  private var instanceBuffer: MTLBuffer?
  private var count = 0
  private var lastCanvasSize: CGSize = .zero
  private var lastScale: CGFloat = 1
  /// Pixel-space canvas size — `lastCanvasSize (points) * lastScale`, recomputed on every
  /// `reset`. All bar geometry and the shader's viewport uniform work in this space directly.
  private var pixelSize: CGSize = .zero

  private let colorTransitions = MetalColorTransitionTracker()
  private let originTransitions = MetalTransitionTracker<SIMD2<Float>>()
  private let sizeTransitions = MetalTransitionTracker<SIMD2<Float>>()
  /// Wall-clock timestamp of the last `draw(in:)` call, for computing `advanceTransitions`'s
  /// `elapsed` — `nil` before the first draw (treated as 0 elapsed, matching
  /// `CADisplayLinkDriver`'s own first-tick convention).
  private var lastFrameTimestamp: CFTimeInterval?

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
    pixelSize = CGSize(width: canvasSize.width * scale, height: canvasSize.height * scale)
    count = values.count
    // A fresh full repaint (new run, resize, scrub) is a one-time state reset, not the
    // rapid-flashing case these trackers exist to smooth — start them clean too.
    colorTransitions.reset()
    originTransitions.reset()
    sizeTransitions.reset()

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

  private func writeBar(
    index: Int, values: [Int], valueRange: ClosedRange<Int>, markers: [Int: Set<Int>]
  ) {
    guard let instanceBuffer, count > 0 else { return }
    let barWidth = Float(pixelSize.width / Double(count))
    let spanLength = Double(valueRange.upperBound - valueRange.lowerBound)
    let normalizedHeight =
      spanLength > 0
      ? Double(values[index] - valueRange.lowerBound) / spanLength
      : 1.0
    let height = Float(pixelSize.height * normalizedHeight)
    // Top-left origin, bars anchored at the bottom — matches `BarGraphVisualizer` exactly
    // (see `BarRenderer.metal`'s vertex shader for how this point space maps to Metal's own
    // +Y-up NDC).
    let originY = Float(pixelSize.height) - height

    let bar = BarInstance(
      origin: originTransitions.valueToWrite(
        forSlot: index, target: SIMD2(Float(index) * barWidth, originY)),
      size: sizeTransitions.valueToWrite(forSlot: index, target: SIMD2(barWidth, height)),
      color: colorTransitions.valueToWrite(
        forSlot: index, target: color(forIndex: index, in: markers))
    )
    instanceBuffer.contents()
      .advanced(by: index * MemoryLayout<BarInstance>.stride)
      .storeBytes(of: bar, as: BarInstance.self)
  }

  private func color(forIndex index: Int, in markers: [Int: Set<Int>]) -> SIMD4<Float> {
    let indexMarkers = markers[index] ?? []
    if indexMarkers.contains(Marker.primary) { return Self.primaryColor }
    if indexMarkers.contains(Marker.secondary) { return Self.secondaryColor }
    return Self.defaultColor
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

      let now = CACurrentMediaTime()
      let elapsed = lastFrameTimestamp.map { now - $0 } ?? 0
      lastFrameTimestamp = now
      advanceTransitions(elapsed: elapsed)

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
      if colorTransitions.isActive || originTransitions.isActive || sizeTransitions.isActive {
        if view.isPaused { view.isPaused = false }
      } else if !view.isPaused {
        view.isPaused = true
      }
    }
  }

  /// Advances every transition tracker and patches whichever fields moved this tick directly
  /// into the live GPU buffer — pulled out of `draw(in:)` so a test can drive it directly against
  /// `debugInstances()`/`encodeDraw`'s own offscreen-texture seam, without a live `MTKView` draw
  /// loop. Reads `displayed(forSlot:)` from EVERY tracker (not just whichever ones changed this
  /// tick) for any slot the union touched, since a complete `BarInstance` write needs all three
  /// fields together.
  func advanceTransitions(elapsed: TimeInterval) {
    guard let instanceBuffer, count > 0 else { return }
    let colorChanges = colorTransitions.advance(elapsed: elapsed)
    let originChanges = originTransitions.advance(elapsed: elapsed)
    let sizeChanges = sizeTransitions.advance(elapsed: elapsed)
    let changedSlots = Set(colorChanges.keys).union(originChanges.keys).union(sizeChanges.keys)
    guard !changedSlots.isEmpty else { return }
    let pointer = instanceBuffer.contents().assumingMemoryBound(to: BarInstance.self)
    for slot in changedSlots {
      if let color = colorTransitions.displayed(forSlot: slot) { pointer[slot].color = color }
      if let origin = originTransitions.displayed(forSlot: slot) { pointer[slot].origin = origin }
      if let size = sizeTransitions.displayed(forSlot: slot) { pointer[slot].size = size }
    }
  }

  /// The actual draw-call encoding, pulled out of `draw(in:)` so it can be driven against an
  /// offscreen render target in a test — no `MTKView`/live drawable required — for empirical,
  /// pixel-readback diagnosis instead of guessing from GPU pipeline setup alone. Not `private`
  /// for exactly that reason: `@testable import` can see `internal`, never `private`.
  func encodeDraw(into passDescriptor: MTLRenderPassDescriptor, commandBuffer: MTLCommandBuffer) {
    guard
      let buffer = instanceBuffer, count > 0,
      let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: passDescriptor)
    else { return }

    encoder.setRenderPipelineState(pipelineState)
    encoder.setVertexBuffer(buffer, offset: 0, index: 0)
    var viewport = SIMD2<Float>(Float(pixelSize.width), Float(pixelSize.height))
    encoder.setVertexBytes(&viewport, length: MemoryLayout<SIMD2<Float>>.size, index: 1)
    encoder.drawPrimitives(
      type: .triangleStrip, vertexStart: 0, vertexCount: 4, instanceCount: count)
    encoder.endEncoding()
  }
}
