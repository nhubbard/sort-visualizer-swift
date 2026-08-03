import Foundation
import Metal
import MetalKit
import QuartzCore
import SortEngineKit
import VisualizationKit

/// The Metal counterpart to `HanoiTowersVisualizer` (`Modules/BuiltInVisualizers/Sources/`) — that
/// type only describes the static resting layout; this renderer adds the actual lift-obstacles/
/// carry/place/restore choreography on top of it, driven by the raw `SortOperation`s
/// `apply(_:values:valueRange:markers:)` already receives (§2A's `MetalIncrementalRenderer` seam).
///
/// Not a `MetalShapeRenderer<Layout>` parametrization — its needs (per-slot multi-waypoint
/// choreography, obstacle discovery) diverge enough from that shared, single-target-per-field
/// abstraction to warrant a fully bespoke type, the same precedent `MetalBarRenderer`/
/// `MetalDisparityChordsRenderer` already set. Reuses `MetalShapeInstance`
/// (`MetalShapeRenderer.swift`) and the existing `shape_vertex`/`rect_fragment` shader pair
/// unchanged — a Hanoi Towers block is just a rect, no new `.metal` shader needed.
///
/// Tower/depth assignment is a PURE function of index (`tower(forIndex:count:towerCount:)`/
/// `depth(forIndex:count:towerCount:)`, duplicated from `HanoiTowersVisualizer` rather than shared
/// across the module boundary — the same duplication every other `Visualizer`/`Metal*Layout` pair
/// already has, per `DrawCommand`'s own doc comment). A slot's HOME position never changes; what
/// this renderer adds is only the animated PATH a slot's on-screen block takes between operations,
/// via `HanoiMoveScheduler`.
@MainActor
final class MetalHanoiTowersRenderer: NSObject, MetalIncrementalRenderer {
  private let device: MTLDevice
  private let commandQueue: MTLCommandQueue
  private let pipelineState: MTLRenderPipelineState
  private var instanceBuffer: MTLBuffer?
  private var count = 0
  private var towerCount = 1
  private var lastCanvasSize: CGSize = .zero
  private var lastScale: CGFloat = 1
  private var pixelSize: CGSize = .zero

  private let colorTransitions = MetalColorTransitionTracker()
  private let positions = HanoiMoveScheduler()
  private var lastFrameTimestamp: CFTimeInterval?

  /// How long a leg of the choreography (lift, carry, restore) takes before advancing to the
  /// next waypoint — independent of `MetalTransitionTracker`'s own fixed 0.12s fade duration,
  /// just long enough for that fade to visually complete before the next leg starts.
  private static let legDuration: TimeInterval = 0.15

  init?(device: MTLDevice, sampleCount: Int = 1) {
    guard let queue = device.makeCommandQueue() else { return nil }
    guard let library = try? device.makeDefaultLibrary(bundle: Bundle(for: Self.self)) else {
      return nil
    }
    guard
      let vertexFunction = library.makeFunction(name: "shape_vertex"),
      let fragmentFunction = library.makeFunction(name: "rect_fragment")
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

  // MARK: - Tower/depth math (pure, index-derived — see the type doc comment)

  nonisolated static func towerCount(for count: Int) -> Int {
    guard count > 0 else { return 1 }
    return max(3, min(8, Int(Double(count).squareRoot().rounded())))
  }

  nonisolated static func tower(forIndex index: Int, count: Int, towerCount: Int) -> Int {
    guard count > 0 else { return 0 }
    return min(towerCount - 1, index * towerCount / count)
  }

  /// The first index belonging to tower `tower` — indices in the same tower are always
  /// contiguous (tower assignment is monotonic in index), so this is a closed-form ceiling
  /// division rather than a scan.
  nonisolated static func firstIndex(ofTower tower: Int, count: Int, towerCount: Int) -> Int {
    (tower * count + towerCount - 1) / towerCount
  }

  nonisolated static func depth(forIndex index: Int, count: Int, towerCount: Int) -> Int {
    let tower = tower(forIndex: index, count: count, towerCount: towerCount)
    return index - firstIndex(ofTower: tower, count: count, towerCount: towerCount)
  }

  /// Every OTHER index sharing `index`'s tower and sitting above it (greater depth) — the blocks
  /// that must be lifted out of the way before `index`'s own block can be pulled out.
  nonisolated static func obstacles(above index: Int, count: Int, towerCount: Int) -> [Int] {
    let tower = tower(forIndex: index, count: count, towerCount: towerCount)
    let nextTowerStart = tower + 1 < towerCount
      ? firstIndex(ofTower: tower + 1, count: count, towerCount: towerCount) : count
    return Array((index + 1)..<nextTowerStart)
  }

  private func homePosition(forIndex index: Int) -> SIMD2<Float> {
    let tower = Self.tower(forIndex: index, count: count, towerCount: towerCount)
    let depth = Self.depth(forIndex: index, count: count, towerCount: towerCount)
    return blockPosition(tower: tower, depth: depth)
  }

  private var maxDepth: Int { max(1, (count + towerCount - 1) / towerCount) }
  private var towerWidth: Double { Double(pixelSize.width) / Double(towerCount) }
  private var blockHeight: Double { Double(pixelSize.height) / Double(maxDepth) }

  private func blockPosition(tower: Int, depth: Int) -> SIMD2<Float> {
    SIMD2(
      Float(Double(tower) * towerWidth + towerWidth * 0.1),
      Float(Double(pixelSize.height) - Double(depth + 1) * blockHeight))
  }

  private func blockSize() -> SIMD2<Float> {
    SIMD2(Float(towerWidth * 0.8), Float(blockHeight * 0.9))
  }

  /// A temporary "parked" spot for an obstacle block — stacked above the spare tower's own
  /// legitimate contents, rank `rank` deep, so several obstacles lifted at once don't overlap.
  private func parkedPosition(inTower tower: Int, rank: Int) -> SIMD2<Float> {
    SIMD2(
      Float(Double(tower) * towerWidth + towerWidth * 0.1),
      Float(Double(pixelSize.height) - Double(maxDepth + 1 + rank) * blockHeight))
  }

  private func spareTower(avoiding towers: Set<Int>) -> Int {
    (0..<towerCount).first { !towers.contains($0) } ?? 0
  }

  // MARK: - IncrementalBarRenderer

  func reset(
    values: [Int], valueRange: ClosedRange<Int>, markers: [Int: Set<Int>],
    canvasSize: CGSize, scale: CGFloat
  ) {
    lastCanvasSize = canvasSize
    lastScale = scale
    pixelSize = CGSize(width: canvasSize.width * scale, height: canvasSize.height * scale)
    count = values.count
    towerCount = Self.towerCount(for: count)
    colorTransitions.reset()
    positions.reset()

    guard count > 0, pixelSize.width > 0, pixelSize.height > 0 else {
      instanceBuffer = nil
      return
    }
    guard
      let buffer = device.makeBuffer(
        length: MemoryLayout<MetalShapeInstance>.stride * count, options: .storageModeShared)
    else {
      instanceBuffer = nil
      return
    }
    instanceBuffer = buffer

    for index in values.indices {
      positions.setDirect(slot: index, target: homePosition(forIndex: index))
      writeInstance(slot: index, values: values, valueRange: valueRange, markers: markers)
    }
  }

  func apply(
    _ operation: SortOperation, values: [Int], valueRange: ClosedRange<Int>,
    markers: [Int: Set<Int>]
  ) {
    guard instanceBuffer != nil, values.count == count else { return }

    switch operation {
    case .swap(let i, let j) where i != j:
      choreographSwap(i: i, j: j, values: values, valueRange: valueRange, markers: markers)
    default:
      guard let touched = operation.touchedIndices else {
        reset(
          values: values, valueRange: valueRange, markers: markers, canvasSize: lastCanvasSize,
          scale: lastScale)
        return
      }
      for index in touched where values.indices.contains(index) {
        positions.setDirect(slot: index, target: homePosition(forIndex: index))
        writeInstance(slot: index, values: values, valueRange: valueRange, markers: markers)
      }
    }
  }

  /// The choreography: cross-tower swaps lift each side's obstacles out to a spare tower while
  /// the two swapped blocks travel to visit each other's tower and back, settling at their own
  /// (unchanged) home position with their new color — same-tower swaps skip the obstacle dance
  /// (extracting from the middle of one stack is a fussier case, deliberately out of scope for a
  /// first version) and just let color fade in place.
  private func choreographSwap(
    i: Int, j: Int, values: [Int], valueRange: ClosedRange<Int>, markers: [Int: Set<Int>]
  ) {
    let towerI = Self.tower(forIndex: i, count: count, towerCount: towerCount)
    let towerJ = Self.tower(forIndex: j, count: count, towerCount: towerCount)

    guard towerI != towerJ else {
      for index in [i, j] {
        positions.setDirect(slot: index, target: homePosition(forIndex: index))
        writeInstance(slot: index, values: values, valueRange: valueRange, markers: markers)
      }
      return
    }

    let spare = spareTower(avoiding: [towerI, towerJ])
    let obstaclesI = Self.obstacles(above: i, count: count, towerCount: towerCount)
    let obstaclesJ = Self.obstacles(above: j, count: count, towerCount: towerCount)

    for (rank, obstacle) in obstaclesI.enumerated() {
      scheduleObstacle(obstacle, spare: spare, rank: rank, values: values, valueRange: valueRange, markers: markers)
    }
    for (rank, obstacle) in obstaclesJ.enumerated() {
      scheduleObstacle(
        obstacle, spare: spare, rank: obstaclesI.count + rank, values: values,
        valueRange: valueRange, markers: markers)
    }

    positions.schedule(
      slot: i,
      waypoints: [
        .init(target: homePosition(forIndex: j), holdDuration: Self.legDuration),
        .init(target: homePosition(forIndex: i), holdDuration: 0),
      ])
    positions.schedule(
      slot: j,
      waypoints: [
        .init(target: homePosition(forIndex: i), holdDuration: Self.legDuration),
        .init(target: homePosition(forIndex: j), holdDuration: 0),
      ])
    writeInstance(slot: i, values: values, valueRange: valueRange, markers: markers)
    writeInstance(slot: j, values: values, valueRange: valueRange, markers: markers)
  }

  private func scheduleObstacle(
    _ index: Int, spare: Int, rank: Int, values: [Int], valueRange: ClosedRange<Int>,
    markers: [Int: Set<Int>]
  ) {
    positions.schedule(
      slot: index,
      waypoints: [
        .init(target: parkedPosition(inTower: spare, rank: rank), holdDuration: Self.legDuration * 2),
        .init(target: homePosition(forIndex: index), holdDuration: 0),
      ])
    writeInstance(slot: index, values: values, valueRange: valueRange, markers: markers)
  }

  private func writeInstance(
    slot: Int, values: [Int], valueRange: ClosedRange<Int>, markers: [Int: Set<Int>]
  ) {
    guard let instanceBuffer, values.indices.contains(slot) else { return }
    let normalized = MetalShapeColor.normalized(value: values[slot], in: valueRange)
    let color = MetalShapeColor.marker(forIndex: slot, in: markers) ?? MetalShapeColor.hueRamp(normalized)

    let instance = MetalShapeInstance(
      origin: positions.displayed(forSlot: slot) ?? homePosition(forIndex: slot),
      size: blockSize(),
      color: colorTransitions.valueToWrite(forSlot: slot, target: color)
    )
    instanceBuffer.contents()
      .advanced(by: slot * MemoryLayout<MetalShapeInstance>.stride)
      .storeBytes(of: instance, as: MetalShapeInstance.self)
  }

  var onDrawableSizeChange: ((CGSize) -> Void)?

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

      if colorTransitions.isActive || positions.isActive {
        if view.isPaused { view.isPaused = false }
      } else if !view.isPaused {
        view.isPaused = true
      }
    }
  }

  func advanceTransitions(elapsed: TimeInterval) {
    guard let instanceBuffer, count > 0 else { return }
    let colorChanges = colorTransitions.advance(elapsed: elapsed)
    let positionChanges = positions.advance(elapsed: elapsed)
    let changedSlots = Set(colorChanges.keys).union(positionChanges.keys)
    guard !changedSlots.isEmpty else { return }
    let pointer = instanceBuffer.contents().assumingMemoryBound(to: MetalShapeInstance.self)
    for slot in changedSlots {
      if let color = colorTransitions.displayed(forSlot: slot) { pointer[slot].color = color }
      if let origin = positions.displayed(forSlot: slot) { pointer[slot].origin = origin }
    }
  }

  func debugInstances() -> [MetalShapeInstance] {
    guard let instanceBuffer else { return [] }
    let pointer = instanceBuffer.contents().assumingMemoryBound(to: MetalShapeInstance.self)
    return (0..<count).map { pointer[$0] }
  }

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
