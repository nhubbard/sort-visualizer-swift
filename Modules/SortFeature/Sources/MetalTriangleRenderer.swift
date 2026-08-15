import Foundation
import Metal
import MetalKit
import QuartzCore
import SortEngineKit

/// The TARGET geometry/color a `MetalTriangleLayout` computes for one slot, in points — plain
/// resolved values, NOT the GPU buffer's own layout (see `MetalTriangleGPUInstance` for that).
/// Every `MetalTriangleLayout` conformance in `MetalPolygonVisualizerLayouts.swift` returns one of
/// these; `MetalTriangleRenderer.writeInstance` is the only place that turns it into the animated
/// triples the GPU buffer actually holds.
struct MetalTriangleInstance {
  var p0: SIMD2<Float>
  var p1: SIMD2<Float>
  var p2: SIMD2<Float>
  var color: SIMD4<Float>
}

/// GPU-buffer layout, matched exactly to `PolygonRenderer.metal`'s `TriangleInstance` struct —
/// each field an unresolved `(from, to, startTime)` triple. `p0`/`p1`/`p2` each get an
/// INDEPENDENT `AnimatedFloat2` (not one shared triple) because `MetalTriangleLayout.slots
/// (forIndex:)` can touch a wedge where only one of its 3 points actually moved — see that
/// protocol's own doc comment.
struct MetalTriangleGPUInstance {
  var p0: AnimatedFloat2
  var p1: AnimatedFloat2
  var p2: AnimatedFloat2
  var color: AnimatedFloat4
}

/// Per-visualizer geometry contract for `MetalTriangleRenderer<Self>` — the triangle-wedge sibling
/// of `MetalShapeLayout`, same design, in points (this renderer converts to pixels generically).
/// `DisparityCircleMetalLayout`/`SpiralMetalLayout`'s wedge `i` uses both point `i-1` and point
/// `i`, so touching index `i` must repaint wedges `i` AND `i+1` — hence the same
/// `arrayIndex(forSlot:)`/`slots(forIndex:)` split as `MetalShapeLayout`.
///
/// Deliberately NOT `@MainActor`, same reasoning as `MetalShapeLayout`.
protocol MetalTriangleLayout {
  static func instanceCount(for count: Int) -> Int
  static func arrayIndex(forSlot slot: Int, count: Int) -> Int
  static func slots(forIndex index: Int, count: Int) -> [Int]

  static func instance(
    atSlot slot: Int, arrayIndex: Int, values: [Int], valueRange: ClosedRange<Int>,
    markers: [Int: Set<Int>], canvasSize: CGSize, count: Int
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

  private let colorTransitions = MetalColorTransitionTracker()
  private let p0Transitions = MetalPositionTransitionTracker()
  private let p1Transitions = MetalPositionTransitionTracker()
  private let p2Transitions = MetalPositionTransitionTracker()
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
    pixelSize = CGSize(width: canvasSize.width * scale, height: canvasSize.height * scale)
    arrayCount = values.count
    slotCount = Layout.instanceCount(for: arrayCount)
    colorTransitions.reset()
    p0Transitions.reset()
    p1Transitions.reset()
    p2Transitions.reset()
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
    // pixels here, once, generically, same as `MetalShapeRenderer.writeInstance` does.
    let n = now()
    let instance = MetalTriangleGPUInstance(
      p0: p0Transitions.valueToWrite(forSlot: slot, target: target.p0 * Float(lastScale), now: n),
      p1: p1Transitions.valueToWrite(forSlot: slot, target: target.p1 * Float(lastScale), now: n),
      p2: p2Transitions.valueToWrite(forSlot: slot, target: target.p2 * Float(lastScale), now: n),
      color: colorTransitions.valueToWrite(forSlot: slot, target: target.color, now: n)
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
        colorTransitions.isActive(now: n) || p0Transitions.isActive(now: n)
        || p1Transitions.isActive(now: n) || p2Transitions.isActive(now: n)
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
  /// .resolvedInstances(at:)`'s doc comment.
  func resolvedInstances(at currentTime: Float) -> [MetalTriangleInstance] {
    debugInstances().map {
      MetalTriangleInstance(
        p0: resolveAnimated2($0.p0, at: currentTime),
        p1: resolveAnimated2($0.p1, at: currentTime),
        p2: resolveAnimated2($0.p2, at: currentTime),
        color: resolveAnimated4($0.color, at: currentTime))
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
    var uniforms = MetalAnimationUniforms(
      viewportSize: SIMD2(Float(pixelSize.width), Float(pixelSize.height)),
      currentTime: currentTime, transitionDuration: Float(transitionDuration))
    encoder.setVertexBytes(&uniforms, length: MemoryLayout<MetalAnimationUniforms>.size, index: 1)
    encoder.drawPrimitives(
      type: .triangle, vertexStart: 0, vertexCount: 3, instanceCount: slotCount)
    encoder.endEncoding()
  }
}
