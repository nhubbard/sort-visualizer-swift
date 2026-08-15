import Foundation
import Metal
import MetalKit
import QuartzCore
import SortEngineKit

enum MetalShapeKind {
  case rect
  case ellipse
}

/// The TARGET geometry/color-ingredients a `MetalShapeLayout` computes for one slot, in points,
/// before scaling to pixels or being fed through a transition tracker — plain resolved values, NOT
/// the GPU buffer's own layout (see `MetalShapeGPUInstance` for that). Every `MetalShapeLayout`
/// conformance in `MetalVisualizerLayouts.swift` returns one of these; `MetalShapeRenderer
/// .writeInstance` is the only place that turns it into the animated triples the GPU buffer
/// actually holds.
///
/// `colorValue`/`colorMarker` — NOT a resolved `SIMD4<Float>` color — since `shape_vertex` now
/// computes the actual hue-ramp/marker-override color itself (`AnimatedField.h`'s
/// `resolveColorSource`); a layout only ever needs to supply the raw ingredients
/// (`MetalShapeColor.normalized(value:in:)`/`.markerKind(forIndex:in:)`), never call `.hueRamp`/
/// `.marker` directly anymore.
struct MetalShapeInstance {
  var origin: SIMD2<Float>
  var size: SIMD2<Float>
  var colorValue: Float
  var colorMarker: Int32
}

/// GPU-buffer layout, matched exactly to `ShapeRenderer.metal`'s `ShapeInstance` struct — each
/// field an unresolved `(from, to, startTime)`-shaped triple, resolved every frame by
/// `shape_vertex` itself via `resolveAnimated2`/`resolveAnimatedColorSource` (`AnimatedField.h`)
/// rather than by a CPU-side per-frame sweep. See `MetalColorSourceTracker`'s doc comment for the
/// full rationale behind resolving color on the GPU, and `MetalPositionTransitionTracker`'s for
/// position.
struct MetalShapeGPUInstance {
  var origin: AnimatedFloat2
  var size: AnimatedFloat2
  var color: AnimatedColorSource
}

/// Per-visualizer geometry contract for `MetalShapeRenderer<Self>` — mirrors that `Visualizer`'s
/// own `draw(_:) -> [DrawCommand]` math, computing one GPU instance at a time in POINTS (matching
/// `Visualizer.context.canvasSize`); `MetalShapeRenderer` converts to pixel space generically.
///
/// `arrayIndex(forSlot:)`/`slots(forIndex:)` are separate because most visualizers are 1:1 (the
/// defaults below), but `PixelMeshMetalLayout` resamples indices across a differently-sized grid
/// and `HoopStackMetalLayout` reverses draw order — both need the exact slot(s) a changed index
/// maps to for incremental `apply`.
///
/// Deliberately NOT `@MainActor`: pure value computation, so `MetalShapeLayoutTests` can call it
/// directly without an actor hop.
protocol MetalShapeLayout {
  static var shapeKind: MetalShapeKind { get }

  /// Whether this layout's non-marker default color is a hue-ramp of `colorValue` (`true`, most
  /// layouts) or a flat neutral color (`false` — `ScatterPlotMetalLayout`/`WaveDotsMetalLayout`
  /// only). A marker (primary/secondary) always overrides either way. Read once per `reset()` and
  /// passed to the shader via `AnimationUniforms.useHueRamp` — fixed for a given `Layout`, not
  /// something that varies per instance/frame.
  static var usesHueRamp: Bool { get }

  /// Total GPU instance count for a given array length. Default: one instance per index.
  static func instanceCount(for count: Int) -> Int

  /// Which array index feeds a given instance slot's value/markers — the inverse of
  /// `slots(forIndex:count:)`. Default: identity.
  static func arrayIndex(forSlot slot: Int, count: Int) -> Int

  /// Which instance slot(s) must be repainted when a given array index changes. Default:
  /// identity (one slot per index).
  static func slots(forIndex index: Int, count: Int) -> [Int]

  /// `arrayIndex` is always `Self.arrayIndex(forSlot: slot, count: count)`, precomputed by the
  /// caller so conformances don't each have to call it again themselves.
  static func instance(
    atSlot slot: Int, arrayIndex: Int, values: [Int], valueRange: ClosedRange<Int>,
    markers: [Int: Set<Int>], canvasSize: CGSize, count: Int
  ) -> MetalShapeInstance
}

extension MetalShapeLayout {
  static var usesHueRamp: Bool { true }
  static func instanceCount(for count: Int) -> Int { count }
  static func arrayIndex(forSlot slot: Int, count: Int) -> Int { slot }
  static func slots(forIndex index: Int, count: Int) -> [Int] { [index] }
}

/// The generic sibling of `MetalBarRenderer` for every OTHER incrementally-portable visualizer —
/// identical GPU plumbing (persistent instance buffer, one instanced draw call, incremental
/// per-touched-index writes), parametrized by `Layout` for the one thing that actually differs
/// per visualizer: how to turn an array index into on-screen geometry. `MetalBarRenderer` itself
/// stays a separate, untouched type rather than becoming `MetalShapeRenderer<BarGraphLayout>` —
/// it's already shipped and user-verified; no reason to risk it for a cosmetic unification.
@MainActor
final class MetalShapeRenderer<Layout: MetalShapeLayout>: NSObject, MetalIncrementalRenderer {
  private let device: MTLDevice
  private let commandQueue: MTLCommandQueue
  private let pipelineState: MTLRenderPipelineState
  private var instanceBuffer: MTLBuffer?
  private var slotCount = 0
  private var arrayCount = 0
  private var lastCanvasSize: CGSize = .zero
  private var lastScale: CGFloat = 1
  private var pixelSize: CGSize = .zero

  private let colorTransitions = MetalColorSourceTracker()
  private let originTransitions = MetalPositionTransitionTracker()
  private let sizeTransitions = MetalPositionTransitionTracker()
  /// See `MetalBarRenderer.timeEpoch`/`now()`'s doc comments.
  private var timeEpoch: CFTimeInterval = CACurrentMediaTime()
  private func now() -> Float { Float(CACurrentMediaTime() - timeEpoch) }

  /// `nil` under the same conditions `MetalBarRenderer.init?` can be — see that initializer's
  /// own doc comment for why `makeDefaultLibrary(bundle:)` (this type's own framework bundle),
  /// not the bundle-less overload, is required here too. `sampleCount` — see
  /// `MetalSampleCount`'s own doc comment for why this defaults to `1` (no MSAA) rather than
  /// hardcoding real antialiasing in here directly.
  init?(device: MTLDevice, sampleCount: Int = 1) {
    guard let queue = device.makeCommandQueue() else { return nil }
    guard let library = try? device.makeDefaultLibrary(bundle: Bundle(for: Self.self)) else {
      return nil
    }
    let fragmentFunctionName = Layout.shapeKind == .rect ? "rect_fragment" : "ellipse_fragment"
    guard
      let vertexFunction = library.makeFunction(name: "shape_vertex"),
      let fragmentFunction = library.makeFunction(name: fragmentFunctionName)
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
    arrayCount = values.count
    slotCount = Layout.instanceCount(for: arrayCount)
    colorTransitions.reset()
    originTransitions.reset()
    sizeTransitions.reset()

    guard slotCount > 0, pixelSize.width > 0, pixelSize.height > 0 else {
      instanceBuffer = nil
      return
    }
    timeEpoch = CACurrentMediaTime()
    guard
      let buffer = device.makeBuffer(
        length: MemoryLayout<MetalShapeGPUInstance>.stride * slotCount, options: .storageModeShared)
    else {
      instanceBuffer = nil
      return
    }
    instanceBuffer = buffer

    for slot in 0..<slotCount {
      writeInstance(slot: slot, values: values, valueRange: valueRange, markers: markers)
    }
  }

  func apply(
    _ operation: SortOperation, values: [Int], valueRange: ClosedRange<Int>,
    markers: [Int: Set<Int>]
  ) {
    guard instanceBuffer != nil, values.count == arrayCount else { return }

    guard let touched = operation.touchedIndices else {
      reset(
        values: values, valueRange: valueRange, markers: markers, canvasSize: lastCanvasSize,
        scale: lastScale)
      return
    }
    guard !touched.isEmpty else { return }

    for index in touched where values.indices.contains(index) {
      for slot in Layout.slots(forIndex: index, count: arrayCount)
      where (0..<slotCount).contains(slot) {
        writeInstance(slot: slot, values: values, valueRange: valueRange, markers: markers)
      }
    }
  }

  private func writeInstance(
    slot: Int, values: [Int], valueRange: ClosedRange<Int>, markers: [Int: Set<Int>]
  ) {
    guard let instanceBuffer, arrayCount > 0 else { return }
    let index = Layout.arrayIndex(forSlot: slot, count: arrayCount)
    guard values.indices.contains(index) else { return }

    let target = Layout.instance(
      atSlot: slot, arrayIndex: index, values: values, valueRange: valueRange,
      markers: markers, canvasSize: lastCanvasSize, count: arrayCount
    )
    // Layouts compute in points, matching every `Visualizer.draw`'s own convention — scale to
    // pixels here, once, generically, same as `MetalBarRenderer.writeBar` does inline.
    let n = now()
    let instance = MetalShapeGPUInstance(
      origin: originTransitions.valueToWrite(
        forSlot: slot, target: target.origin * Float(lastScale), now: n),
      size: sizeTransitions.valueToWrite(
        forSlot: slot, target: target.size * Float(lastScale), now: n),
      color: colorTransitions.valueToWrite(
        forSlot: slot, value: target.colorValue, marker: target.colorMarker, now: n)
    )

    instanceBuffer.contents()
      .advanced(by: slot * MemoryLayout<MetalShapeGPUInstance>.stride)
      .storeBytes(of: instance, as: MetalShapeGPUInstance.self)
  }

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

      // See `MetalBarRenderer.draw(in:)`'s own comment on why this uses MetalKit's own
      // capped internal display link instead of manually re-arming `setNeedsDisplay()`.
      let n = now()
      if colorTransitions.isActive(now: n) || originTransitions.isActive(now: n)
        || sizeTransitions.isActive(now: n) {
        if view.isPaused { view.isPaused = false }
      } else if !view.isPaused {
        view.isPaused = true
      }
    }
  }

  /// Test seam: the RAW current instance buffer contents, in slot order — unresolved `(from, to,
  /// startTime)` triples, exactly as the GPU sees them. Lets a shader-parity test assert the
  /// buffer holds the triple it expects, independent of when the shader itself would resolve it.
  func debugInstances() -> [MetalShapeGPUInstance] {
    guard let instanceBuffer else { return [] }
    let pointer = instanceBuffer.contents().assumingMemoryBound(to: MetalShapeGPUInstance.self)
    return (0..<slotCount).map { pointer[$0] }
  }

  /// Test seam: `debugInstances()`'s raw triples resolved to plain displayed values at an
  /// explicit, pinned `currentTime` — the direct replacement for the old `advanceTransitions
  /// (elapsed:); debugInstances()` pattern now that resolution happens in the shader, not on the
  /// CPU. Uses the same CPU reference math (`resolveAnimated2`/`resolveAnimatedColorSource`) the
  /// shader-parity tests independently verify against the real MSL implementation.
  struct ResolvedShapeInstance {
    var origin: SIMD2<Float>
    var size: SIMD2<Float>
    var color: SIMD4<Float>
  }

  func resolvedInstances(at currentTime: Float) -> [ResolvedShapeInstance] {
    debugInstances().map {
      ResolvedShapeInstance(
        origin: resolveAnimated2($0.origin, at: currentTime),
        size: resolveAnimated2($0.size, at: currentTime),
        color: resolveAnimatedColorSource(
          $0.color, at: currentTime, useHueRamp: Layout.usesHueRamp,
          primaryColor: MetalShapeColor.primary, secondaryColor: MetalShapeColor.secondary,
          neutralColor: MetalShapeColor.neutral))
    }
  }

  /// Same test seam as `MetalBarRenderer.encodeDraw` — lets a test drive this against an
  /// offscreen texture instead of a live `MTKView`.
  func encodeDraw(into passDescriptor: MTLRenderPassDescriptor, commandBuffer: MTLCommandBuffer) {
    encodeDraw(into: passDescriptor, commandBuffer: commandBuffer, currentTime: now())
  }

  /// Test-only overload — see `MetalBarRenderer`'s own overload of the same name for why.
  func encodeDraw(
    into passDescriptor: MTLRenderPassDescriptor, commandBuffer: MTLCommandBuffer,
    currentTime: Float
  ) {
    guard
      let buffer = instanceBuffer, slotCount > 0,
      let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: passDescriptor)
    else { return }

    encoder.setRenderPipelineState(pipelineState)
    encoder.setVertexBuffer(buffer, offset: 0, index: 0)
    var uniforms = MetalAnimationUniforms(
      viewportSize: SIMD2(Float(pixelSize.width), Float(pixelSize.height)),
      currentTime: currentTime, transitionDuration: Float(transitionDuration),
      useHueRamp: Layout.usesHueRamp ? 1 : 0, primaryColor: MetalShapeColor.primary,
      secondaryColor: MetalShapeColor.secondary, neutralColor: MetalShapeColor.neutral)
    encoder.setVertexBytes(&uniforms, length: MemoryLayout<MetalAnimationUniforms>.size, index: 1)
    encoder.drawPrimitives(
      type: .triangleStrip, vertexStart: 0, vertexCount: 4, instanceCount: slotCount)
    encoder.endEncoding()
  }
}
