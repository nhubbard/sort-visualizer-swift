import Foundation
import Metal
import MetalKit
import QuartzCore
import SortEngineKit

/// The TARGET raw value + color-ingredients a `MetalTriangleLayout` computes for one slot — plain
/// resolved values, NOT the GPU buffer's own layout (see `MetalTriangleGPUInstance` for that).
/// Every `MetalTriangleLayout` conformance in `MetalPolygonVisualizerLayouts.swift` returns one of
/// these; `MetalTriangleRenderer.writeInstance` is the only place that turns it into the animated
/// triples the GPU buffer actually holds.
///
/// No `p0`/`p1`/`p2` fields anymore: `triangle_vertex` now derives the actual 3 points itself
/// (`resolveTriangleGeometry`, selected per draw call by `MetalTriangleLayout.geometryKind`) —
/// a layout's `instance(...)` only ever needs to supply its slot's raw underlying value, the same
/// way `MetalShapeInstance` already does.
struct MetalTriangleInstance {
  var value: Float
  var colorValue: Float
  var colorMarker: Int32
}

/// GPU-buffer layout, matched exactly to `PolygonRenderer.metal`'s `TriangleInstance` struct —
/// `value`/`previousValue` each an unresolved `(from, to, startTime)` triple, resolved every frame
/// by `triangle_vertex` itself via `resolveAnimated`/`resolveTriangleGeometry`/
/// `resolveAnimatedColorSource` (`AnimatedField.h`). `previousValue` is supplied for EVERY layout,
/// not just `DisparityCircle`/`Spiral` — `ColorCircle`'s branch of `resolveTriangleGeometry` simply
/// never reads it. `arrayIndex` is a plain, unanimated `Int32`, same rationale as
/// `MetalShapeGPUInstance.arrayIndex`.
struct MetalTriangleGPUInstance {
  var arrayIndex: Int32
  var value: AnimatedFloat
  var previousValue: AnimatedFloat
  var color: AnimatedColorSource
}

/// Per-visualizer geometry contract for `MetalTriangleRenderer<Self>` — the triangle-wedge sibling
/// of `MetalShapeLayout`, same design. `DisparityCircleMetalLayout`/`SpiralMetalLayout`'s wedge `i`
/// uses both point `i-1` and point `i`, so touching index `i` must repaint wedges `i` AND `i+1` —
/// hence the same `arrayIndex(forSlot:)`/`slots(forIndex:)` split as `MetalShapeLayout`.
///
/// Deliberately NOT `@MainActor`, same reasoning as `MetalShapeLayout`.
protocol MetalTriangleLayout {
  /// Which `AnimatedField.h`/`MetalShapeGeometry.swift` position formula `triangle_vertex` applies
  /// for this layout — see `MetalShapeLayout.geometryKind`'s identical doc comment.
  static var geometryKind: MetalTriangleGeometryKind { get }

  static func instanceCount(for count: Int) -> Int
  static func arrayIndex(forSlot slot: Int, count: Int) -> Int
  static func slots(forIndex index: Int, count: Int) -> [Int]

  /// No `canvasSize`/`count` parameters anymore — see `MetalShapeLayout.instance(...)`'s identical
  /// doc comment on why.
  static func instance(
    atSlot slot: Int, arrayIndex: Int, values: [Int], valueRange: ClosedRange<Int>,
    markers: [Int: Set<Int>]
  ) -> MetalTriangleInstance
}

extension MetalTriangleLayout {
  static func instanceCount(for count: Int) -> Int { count }
  static func arrayIndex(forSlot slot: Int, count: Int) -> Int { slot }
  static func slots(forIndex index: Int, count: Int) -> [Int] { [index] }
}

/// The triangle-wedge sibling of `MetalShapeRenderer<Layout>` — identical GPU plumbing (persistent
/// instance buffer, one instanced draw call, incremental per-touched-index writes), just with 3
/// explicit points per instance instead of a bounding box, and `.triangle` primitives (3
/// vertices/instance, no shared strip corner) instead of `.triangleStrip`.
@MainActor
final class MetalTriangleRenderer<Layout: MetalTriangleLayout>: NSObject, MetalIncrementalRenderer {
  private let device: MTLDevice
  private let commandQueue: MTLCommandQueue
  private let pipelineState: MTLRenderPipelineState
  private var instanceBuffer: MTLBuffer?
  private var slotCount = 0
  private var arrayCount = 0
  private var lastCanvasSize: CGSize = .zero
  private var lastScale: CGFloat = 1
  private var pixelSize: CGSize = .zero
  /// See `MetalShapeRenderer.lastValueRange`'s identical doc comment.
  private var lastValueRange: ClosedRange<Int> = 0...0

  private let colorTransitions = MetalColorSourceTracker()
  private let valueTransitions = MetalScalarTransitionTracker()
  private let previousValueTransitions = MetalScalarTransitionTracker()
  /// See `MetalBarRenderer.timeEpoch`/`now()`'s doc comments.
  private var timeEpoch: CFTimeInterval = CACurrentMediaTime()
  private func now() -> Float { Float(CACurrentMediaTime() - timeEpoch) }

  /// `nil` under the same conditions `MetalBarRenderer.init?` can be — see that initializer's
  /// own doc comment for why `makeDefaultLibrary(bundle:)` is required. `sampleCount` defaults to
  /// `1` (no MSAA) for the same reason `MetalShapeRenderer`'s does — see `MetalSampleCount`.
  init?(device: MTLDevice, sampleCount: Int = 1) {
    guard let queue = device.makeCommandQueue() else { return nil }
    guard let library = try? device.makeDefaultLibrary(bundle: Bundle(for: Self.self)) else {
      return nil
    }
    guard
      let vertexFunction = library.makeFunction(name: "triangle_vertex"),
      let fragmentFunction = library.makeFunction(name: "triangle_fragment")
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
    arrayCount = values.count
    slotCount = Layout.instanceCount(for: arrayCount)
    colorTransitions.reset()
    valueTransitions.reset()
    previousValueTransitions.reset()
    timeEpoch = CACurrentMediaTime()

    guard slotCount > 0, pixelSize.width > 0, pixelSize.height > 0 else {
      instanceBuffer = nil
      return
    }
    guard
      let buffer = device.makeBuffer(
        length: MemoryLayout<MetalTriangleGPUInstance>.stride * slotCount,
        options: .storageModeShared)
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
    lastValueRange = valueRange

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
      atSlot: slot, arrayIndex: index, values: values, valueRange: valueRange, markers: markers
    )
    // Supplied generically for every layout, not just `DisparityCircle`/`Spiral` — see
    // `MetalTriangleGPUInstance.previousValue`'s doc comment.
    let previousIndex = (index - 1 + arrayCount) % arrayCount
    let previousValue = Float(values[previousIndex])
    let n = now()
    let instance = MetalTriangleGPUInstance(
      arrayIndex: Int32(index),
      value: valueTransitions.valueToWrite(forSlot: slot, target: target.value, now: n),
      previousValue: previousValueTransitions.valueToWrite(
        forSlot: slot, target: previousValue, now: n),
      color: colorTransitions.valueToWrite(
        forSlot: slot, value: target.colorValue, marker: target.colorMarker, now: n)
    )

    instanceBuffer.contents()
      .advanced(by: slot * MemoryLayout<MetalTriangleGPUInstance>.stride)
      .storeBytes(of: instance, as: MetalTriangleGPUInstance.self)
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
      let stillActive =
        colorTransitions.isActive(now: n) || valueTransitions.isActive(now: n)
        || previousValueTransitions.isActive(now: n)
      if stillActive {
        if view.isPaused { view.isPaused = false }
      } else if !view.isPaused {
        view.isPaused = true
      }
    }
  }

  /// Test seam: the RAW current instance buffer contents — see `MetalShapeRenderer
  /// .debugInstances`'s doc comment.
  func debugInstances() -> [MetalTriangleGPUInstance] {
    guard let instanceBuffer else { return [] }
    let pointer = instanceBuffer.contents().assumingMemoryBound(to: MetalTriangleGPUInstance.self)
    return (0..<slotCount).map { pointer[$0] }
  }

  /// Test seam: resolved displayed values at a pinned `currentTime` — see `MetalShapeRenderer
  /// .resolvedInstances(at:)`'s doc comment. Every `MetalTriangleLayout` hue-ramps (none use flat
  /// neutral, unlike two `MetalShapeLayout`s), so `useHueRamp` is unconditionally `true` here.
  struct ResolvedTriangleInstance {
    var p0: SIMD2<Float>
    var p1: SIMD2<Float>
    var p2: SIMD2<Float>
    var color: SIMD4<Float>
  }

  func resolvedInstances(at currentTime: Float) -> [ResolvedTriangleInstance] {
    let viewportSize = SIMD2(Float(pixelSize.width), Float(pixelSize.height))
    return debugInstances().map { instance in
      let value = resolveAnimated(instance.value, at: currentTime)
      let previousValue = resolveAnimated(instance.previousValue, at: currentTime)
      let geometry = resolveTriangleGeometry(
        kind: Layout.geometryKind, arrayIndex: instance.arrayIndex, value: value,
        previousValue: previousValue, arrayCount: Float(arrayCount),
        valueRangeLowerBound: Float(lastValueRange.lowerBound),
        valueRangeSpan: Float(lastValueRange.upperBound - lastValueRange.lowerBound),
        viewportSize: viewportSize)
      return ResolvedTriangleInstance(
        p0: geometry.p0, p1: geometry.p1, p2: geometry.p2,
        color: resolveAnimatedColorSource(
          instance.color, at: currentTime, useHueRamp: true, primaryColor: MetalShapeColor.primary,
          secondaryColor: MetalShapeColor.secondary, neutralColor: MetalShapeColor.neutral))
    }
  }

  /// Test seam, same shape as `MetalShapeRenderer.encodeDraw` — drives this against an offscreen
  /// texture instead of a live `MTKView`.
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
    // `useHueRamp: 1` unconditionally — every `MetalTriangleLayout` hue-ramps.
    var uniforms = MetalAnimationUniforms(
      viewportSize: SIMD2(Float(pixelSize.width), Float(pixelSize.height)),
      currentTime: currentTime, transitionDuration: Float(transitionDuration), useHueRamp: 1,
      primaryColor: MetalShapeColor.primary, secondaryColor: MetalShapeColor.secondary,
      neutralColor: MetalShapeColor.neutral, arrayCount: Float(arrayCount),
      valueRangeLowerBound: Float(lastValueRange.lowerBound),
      valueRangeSpan: Float(lastValueRange.upperBound - lastValueRange.lowerBound),
      scale: Float(lastScale), geometryKind: Layout.geometryKind.rawValue)
    encoder.setVertexBytes(&uniforms, length: MemoryLayout<MetalAnimationUniforms>.stride, index: 1)
    encoder.drawPrimitives(
      type: .triangle, vertexStart: 0, vertexCount: 3, instanceCount: slotCount)
    encoder.endEncoding()
  }
}
