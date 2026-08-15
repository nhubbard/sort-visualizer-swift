import Foundation
import Metal
import MetalKit
import QuartzCore
import SortEngineKit
import VisualizationKit

/// GPU-buffer layout, matched exactly to `ShapeRenderer.metal`'s `HanoiInstance` struct — `origin`
/// is the fixed 2-leg `HanoiOrigin` (`HanoiMoveScheduler.swift`), `size` stays a plain unanimated
/// value (Hanoi never eases block size, only position and color), `color` is the usual
/// `AnimatedColorSource` (Hanoi hue-ramps like every renderer except `MetalBarRenderer`).
struct HanoiInstance {
  var origin: HanoiOrigin
  var size: SIMD2<Float>
  var color: AnimatedColorSource
}

/// The Metal counterpart to `HanoiTowersVisualizer` (`Modules/BuiltInVisualizers/Sources/`) — that
/// type only describes the static resting layout; this renderer adds the actual lift-obstacles/
/// carry/place/restore choreography on top of it, driven by the raw `SortOperation`s
/// `apply(_:values:valueRange:markers:)` already receives (§2A's `MetalIncrementalRenderer` seam).
///
/// Not a `MetalShapeRenderer<Layout>` parametrization — its needs (per-slot multi-waypoint
/// choreography, obstacle discovery) diverge enough from that shared, single-target-per-field
/// abstraction to warrant a fully bespoke type, the same precedent `MetalBarRenderer`/
/// `MetalDisparityChordsRenderer` already set. Its own `hanoi_vertex` function (`ShapeRenderer
/// .metal`, alongside `shape_vertex`/`rect_fragment` which it still reuses for fragment output) —
/// the fixed 2-leg origin math genuinely differs from every other renderer's single-target fade,
/// even though the rest (unit-corner quad, NDC flip, fill) is identical.
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

  private let colorTransitions = MetalColorSourceTracker()
  private let positions = HanoiMoveScheduler()
  /// See `MetalBarRenderer.timeEpoch`/`now()`'s doc comments.
  private var timeEpoch: CFTimeInterval = CACurrentMediaTime()
  private func now() -> Float { Float(CACurrentMediaTime() - timeEpoch) }

  /// How long a leg of the choreography (lift, carry, restore) takes before advancing to the
  /// next waypoint — independent of `MetalColorSourceTracker`'s own fixed 0.12s
  /// `transitionDuration`, just long enough for that fade to visually complete before the next
  /// leg starts. MUST stay `>= transitionDuration` — see `HanoiOrigin`'s own doc comment for why
  /// a smaller value would make leg 1 visibly pop instead of continuing from leg 0's target.
  private static let legDuration: TimeInterval = 0.15

  init?(device: MTLDevice, sampleCount: Int = 1) {
    guard let queue = device.makeCommandQueue() else { return nil }
    guard let library = try? device.makeDefaultLibrary(bundle: Bundle(for: Self.self)) else {
      return nil
    }
    guard
      let vertexFunction = library.makeFunction(name: "hanoi_vertex"),
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
    assert(
      Self.legDuration >= transitionDuration,
      "leg0Hold must be >= transitionDuration or leg 1 will visibly pop instead of continuing "
        + "from leg 0's settled target — see HanoiOrigin's doc comment")
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
    timeEpoch = CACurrentMediaTime()

    guard count > 0, pixelSize.width > 0, pixelSize.height > 0 else {
      instanceBuffer = nil
      return
    }
    guard
      let buffer = device.makeBuffer(
        length: MemoryLayout<HanoiInstance>.stride * count, options: .storageModeShared)
    else {
      instanceBuffer = nil
      return
    }
    instanceBuffer = buffer

    let n = now()
    for index in values.indices {
      positions.setDirect(slot: index, target: homePosition(forIndex: index), now: n)
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
      let n = now()
      for index in touched where values.indices.contains(index) {
        positions.setDirect(slot: index, target: homePosition(forIndex: index), now: n)
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

    let n = now()
    guard towerI != towerJ else {
      for index in [i, j] {
        positions.setDirect(slot: index, target: homePosition(forIndex: index), now: n)
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
      slot: i, leg0Target: homePosition(forIndex: j), leg0Hold: Self.legDuration,
      leg1Target: homePosition(forIndex: i), now: n)
    positions.schedule(
      slot: j, leg0Target: homePosition(forIndex: i), leg0Hold: Self.legDuration,
      leg1Target: homePosition(forIndex: j), now: n)
    writeInstance(slot: i, values: values, valueRange: valueRange, markers: markers)
    writeInstance(slot: j, values: values, valueRange: valueRange, markers: markers)
  }

  private func scheduleObstacle(
    _ index: Int, spare: Int, rank: Int, values: [Int], valueRange: ClosedRange<Int>,
    markers: [Int: Set<Int>]
  ) {
    positions.schedule(
      slot: index, leg0Target: parkedPosition(inTower: spare, rank: rank),
      leg0Hold: Self.legDuration * 2, leg1Target: homePosition(forIndex: index), now: now())
    writeInstance(slot: index, values: values, valueRange: valueRange, markers: markers)
  }

  private func writeInstance(
    slot: Int, values: [Int], valueRange: ClosedRange<Int>, markers: [Int: Set<Int>]
  ) {
    guard let instanceBuffer, values.indices.contains(slot) else { return }
    let normalized = MetalShapeColor.normalized(value: values[slot], in: valueRange)
    let n = now()
    let home = homePosition(forIndex: slot)

    let instance = HanoiInstance(
      origin: positions.origin(forSlot: slot)
        ?? HanoiOrigin(leg0From: home, leg0To: home, leg1To: home, leg0Hold: 0, startTime: n),
      size: blockSize(),
      color: colorTransitions.valueToWrite(
        forSlot: slot, value: Float(normalized),
        marker: MetalShapeColor.markerKind(forIndex: slot, in: markers), now: n)
    )
    instanceBuffer.contents()
      .advanced(by: slot * MemoryLayout<HanoiInstance>.stride)
      .storeBytes(of: instance, as: HanoiInstance.self)
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

      encodeDraw(into: passDescriptor, commandBuffer: commandBuffer)
      commandBuffer.present(drawable)
      commandBuffer.commit()

      let n = now()
      if colorTransitions.isActive(now: n) || positions.isActive(now: n) {
        if view.isPaused { view.isPaused = false }
      } else if !view.isPaused {
        view.isPaused = true
      }
    }
  }

  /// Test seam: the RAW current instance buffer contents — see `MetalShapeRenderer
  /// .debugInstances`'s doc comment.
  func debugInstances() -> [HanoiInstance] {
    guard let instanceBuffer else { return [] }
    let pointer = instanceBuffer.contents().assumingMemoryBound(to: HanoiInstance.self)
    return (0..<count).map { pointer[$0] }
  }

  /// Test seam: `debugInstances()`'s raw origin/color resolved to plain displayed values at a
  /// pinned `currentTime` (`size` passes through unchanged, never animated) — see
  /// `MetalShapeRenderer.resolvedInstances(at:)`'s doc comment. Origin resolution uses
  /// `HanoiMoveScheduler`'s own `resolvedOrigin`-equivalent math directly on the raw triple
  /// (not through the scheduler instance, which only knows about slots it currently tracks) so
  /// this works uniformly even for a slot whose `HanoiOrigin` came from the `?? homePosition`
  /// fallback in `writeInstance`.
  struct ResolvedHanoiInstance {
    var origin: SIMD2<Float>
    var size: SIMD2<Float>
    var color: SIMD4<Float>
  }

  func resolvedInstances(at currentTime: Float) -> [ResolvedHanoiInstance] {
    debugInstances().map { instance in
      let origin = instance.origin
      let t = currentTime - origin.startTime
      let resolvedOrigin: SIMD2<Float>
      if t < origin.leg0Hold {
        let localT = min(max(t / Float(transitionDuration), 0), 1)
        let eased = easeInOutCubic(localT)
        resolvedOrigin = origin.leg0From + (origin.leg0To - origin.leg0From) * SIMD2<Float>(repeating: eased)
      } else {
        let localT = min(max((t - origin.leg0Hold) / Float(transitionDuration), 0), 1)
        let eased = easeInOutCubic(localT)
        resolvedOrigin = origin.leg0To + (origin.leg1To - origin.leg0To) * SIMD2<Float>(repeating: eased)
      }
      return ResolvedHanoiInstance(
        origin: resolvedOrigin, size: instance.size,
        color: resolveAnimatedColorSource(
          instance.color, at: currentTime, useHueRamp: true, primaryColor: MetalShapeColor.primary,
          secondaryColor: MetalShapeColor.secondary, neutralColor: MetalShapeColor.neutral))
    }
  }

  func encodeDraw(into passDescriptor: MTLRenderPassDescriptor, commandBuffer: MTLCommandBuffer) {
    encodeDraw(into: passDescriptor, commandBuffer: commandBuffer, currentTime: now())
  }

  /// Test-only overload — see `MetalBarRenderer`'s own overload of the same name for why.
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
    // `useHueRamp: 1` unconditionally — Hanoi always hue-ramps.
    var uniforms = MetalAnimationUniforms(
      viewportSize: SIMD2(Float(pixelSize.width), Float(pixelSize.height)),
      currentTime: currentTime, transitionDuration: Float(transitionDuration), useHueRamp: 1,
      primaryColor: MetalShapeColor.primary, secondaryColor: MetalShapeColor.secondary,
      neutralColor: MetalShapeColor.neutral)
    encoder.setVertexBytes(&uniforms, length: MemoryLayout<MetalAnimationUniforms>.size, index: 1)
    encoder.drawPrimitives(
      type: .triangleStrip, vertexStart: 0, vertexCount: 4, instanceCount: count)
    encoder.endEncoding()
  }
}
