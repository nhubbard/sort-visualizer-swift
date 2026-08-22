import Metal
import Testing

@testable import SortEngineKit
@testable import SortFeature

@Suite
struct MetalHanoiTowersRendererTests {
  @Test
  func towerAssignmentIsMonotonicAndContiguous() {
    let count = 40
    let towers = MetalHanoiTowersRenderer.towerCount(for: count)
    var lastTower = 0
    for index in 0..<count {
      let tower = MetalHanoiTowersRenderer.tower(forIndex: index, count: count, towerCount: towers)
      #expect(tower >= lastTower)
      lastTower = tower
    }
  }

  @Test
  func depthIncreasesByOneWithinATowerAndResetsAtTheNextOne() {
    let count = 12
    let towers = MetalHanoiTowersRenderer.towerCount(for: count)
    var previousTower = -1
    var expectedDepth = 0
    for index in 0..<count {
      let tower = MetalHanoiTowersRenderer.tower(forIndex: index, count: count, towerCount: towers)
      let depth = MetalHanoiTowersRenderer.depth(forIndex: index, count: count, towerCount: towers)
      if tower != previousTower {
        expectedDepth = 0
        previousTower = tower
      }
      #expect(depth == expectedDepth)
      expectedDepth += 1
    }
  }

  @Test
  func obstaclesAreExactlyTheIndicesAboveInTheSameTower() {
    let count = 12
    let towers = MetalHanoiTowersRenderer.towerCount(for: count)
    // Tower 0 spans indices [0, firstIndexOfTower(1)) — pick an index in the middle of it.
    let firstOfTowerOne = MetalHanoiTowersRenderer.firstIndex(ofTower: 1, count: count, towerCount: towers)
    guard firstOfTowerOne > 1 else { return }  // guard: only meaningful if tower 0 has >1 member
    let target = 0
    let obstacles = MetalHanoiTowersRenderer.obstacles(above: target, count: count, towerCount: towers)
    #expect(obstacles == 1..<firstOfTowerOne)
    for obstacle in obstacles {
      #expect(
        MetalHanoiTowersRenderer.tower(forIndex: obstacle, count: count, towerCount: towers)
          == MetalHanoiTowersRenderer.tower(forIndex: target, count: count, towerCount: towers))
    }
  }

  @Test
  func lastIndexInATowerHasNoObstacles() {
    let count = 12
    let towers = MetalHanoiTowersRenderer.towerCount(for: count)
    let lastOfTowerZero = MetalHanoiTowersRenderer.firstIndex(ofTower: 1, count: count, towerCount: towers) - 1
    #expect(
      MetalHanoiTowersRenderer.obstacles(above: lastOfTowerZero, count: count, towerCount: towers)
        .isEmpty)
  }

  @MainActor
  @Test
  func resetPlacesEveryIndexAtItsOwnHomePosition() throws {
    let device = try #require(MTLCreateSystemDefaultDevice())
    let renderer = try #require(MetalHanoiTowersRenderer(device: device))
    let values = Array(1...12)
    renderer.reset(
      values: values, valueRange: 1...12, markers: [:], canvasSize: CGSize(width: 400, height: 400),
      scale: 1)

    // Fresh off `reset()` — `origin.leg0From == leg0To == leg1To` for every slot (a first-ever
    // paint shows immediately, no fade in flight yet), so `resolvedInstances(at:)` gives the
    // actual pixel home position for every slot regardless of which `currentTime` is passed.
    let instances = renderer.resolvedInstances(at: 0)
    #expect(instances.count == 12)
    // Every tower's bottom-most (depth 0) block should sit at the same PIXEL Y — the canvas floor
    // minus one block height — regardless of which tower it's in, once `resolveHanoiGeometry`
    // turns each one's (tower, depth) coordinate into an actual on-screen rect.
    let towers = MetalHanoiTowersRenderer.towerCount(for: 12)
    var bottomYs: Set<Float> = []
    for index in 0..<12 where MetalHanoiTowersRenderer.depth(forIndex: index, count: 12, towerCount: towers) == 0 {
      bottomYs.insert(instances[index].origin.y)
    }
    #expect(bottomYs.count == 1, "every tower's floor block should be at the same height")
  }

  @MainActor
  @Test
  func crossTowerSwapSettlesBothSlotsBackAtTheirOwnHomeWithSwappedColors() throws {
    let device = try #require(MTLCreateSystemDefaultDevice())
    let renderer = try #require(MetalHanoiTowersRenderer(device: device))
    // A small array with several towers so index 0 and its swap partner land in different towers.
    var values = Array(1...9)
    renderer.reset(
      values: values, valueRange: 1...9, markers: [:], canvasSize: CGSize(width: 300, height: 300),
      scale: 1)
    // Fresh off `reset()`, every slot's fully settled — `resolvedInstances(at:)` gives the actual
    // PIXEL home position (`debugInstances()`'s raw `.origin.leg0To` is now an abstract (tower,
    // depth) coordinate, not comparable to `resolvedInstances(at:)`'s pixel-space output below).
    let homeOrigins = renderer.resolvedInstances(at: 0).map(\.origin)

    let towers = MetalHanoiTowersRenderer.towerCount(for: 9)
    // Find two indices in different towers to swap.
    let i = 0
    guard
      let j = (0..<9).first(where: {
        MetalHanoiTowersRenderer.tower(forIndex: $0, count: 9, towerCount: towers)
          != MetalHanoiTowersRenderer.tower(forIndex: i, count: 9, towerCount: towers)
      })
    else {
      Issue.record("test setup: need at least 2 towers for this array size")
      return
    }

    values.swapAt(i, j)
    renderer.apply(.swap(i, j), values: values, valueRange: 1...9, markers: [:])

    // A large sentinel probe time, comfortably past both legs' hold durations plus their own
    // fades regardless of how much real wall-clock time this test took to reach this line — see
    // `MetalShapeRendererBufferConsistencyTests`'s own comment on this same sentinel pattern.
    let finalInstances = renderer.resolvedInstances(at: 1000)
    #expect(
      finalInstances[i].origin == homeOrigins[i],
      "slot \(i) must settle back at its own home position, not \(j)'s")
    #expect(
      finalInstances[j].origin == homeOrigins[j],
      "slot \(j) must settle back at its own home position, not \(i)'s")
  }

  @MainActor
  @Test
  func crossTowerSwapReturnsObstaclesToTheirOwnHome() throws {
    let device = try #require(MTLCreateSystemDefaultDevice())
    let renderer = try #require(MetalHanoiTowersRenderer(device: device))
    var values = Array(1...9)
    renderer.reset(
      values: values, valueRange: 1...9, markers: [:], canvasSize: CGSize(width: 300, height: 300),
      scale: 1)
    // Fresh off `reset()` — see `crossTowerSwapSettlesBothSlotsBackAtTheirOwnHomeWithSwappedColors`'s
    // own comment on why `resolvedInstances(at:)`, not raw `debugInstances()`, gives the pixel
    // home position now.
    let homeOrigins = renderer.resolvedInstances(at: 0).map(\.origin)

    let towers = MetalHanoiTowersRenderer.towerCount(for: 9)
    // Pick the FIRST index of some tower with at least one obstacle above it, so a swap on it
    // actually exercises the obstacle-lifting path.
    guard
      let i = (0..<9).first(where: {
        !MetalHanoiTowersRenderer.obstacles(above: $0, count: 9, towerCount: towers).isEmpty
      }),
      let j = (0..<9).first(where: {
        MetalHanoiTowersRenderer.tower(forIndex: $0, count: 9, towerCount: towers)
          != MetalHanoiTowersRenderer.tower(forIndex: i, count: 9, towerCount: towers)
      })
    else {
      Issue.record("test setup: need an index with an obstacle and a different-tower partner")
      return
    }
    // `.lowerBound`, not `[0]` — `obstacles(above:)` returns a `Range<Int>` now, whose `Index` IS
    // the element type itself, so `[0]` would mean "the element AT position 0" (a trap unless the
    // range happens to start at 0), not "the first element."
    let obstacle = MetalHanoiTowersRenderer.obstacles(above: i, count: 9, towerCount: towers).lowerBound

    values.swapAt(i, j)
    renderer.apply(.swap(i, j), values: values, valueRange: 1...9, markers: [:])

    // See `crossTowerSwapSettlesBothSlotsBackAtTheirOwnHomeWithSwappedColors`'s own comment on
    // this sentinel probe time — comfortably past an obstacle's (longer, `legDuration * 2`) hold.
    #expect(renderer.resolvedInstances(at: 1000)[obstacle].origin == homeOrigins[obstacle])
  }

  /// Guards `maxAnimatedObstaclesPerSwap`'s own doc comment claim directly: above that many
  /// combined obstacles, `choreographSwap` must skip `scheduleObstacle` entirely for BOTH sides
  /// (not just cap how many animate) — verified by asserting an obstacle's raw `HanoiOrigin`
  /// (`startTime` included) is byte-identical before and after the swap, which is only true if
  /// `HanoiMoveScheduler.schedule` was never called for it at all. `i`/`j` themselves must still
  /// get scheduled regardless — the swap's own animation isn't gated by this threshold, only the
  /// obstacle-lifting dance around it.
  @MainActor
  @Test
  func crossTowerSwapWithManyObstaclesSkipsTheLiftAnimationEntirely() throws {
    let device = try #require(MTLCreateSystemDefaultDevice())
    let renderer = try #require(MetalHanoiTowersRenderer(device: device))
    // towerCount(for: 1200) == 16 (round(sqrt(1200)) == 35, clamped), so depth-0 members of
    // adjacent towers each have ~74 other members as obstacles — comfortably past the 32 combined
    // threshold, the same adversarial shape `HanoiStressHarnessTests.adversarialSwapSequence` uses.
    let count = 1200
    var values = Array(1...count)
    renderer.reset(
      values: values, valueRange: 1...count, markers: [:],
      canvasSize: CGSize(width: 1600, height: 1200), scale: 1)

    let towers = MetalHanoiTowersRenderer.towerCount(for: count)
    let i = MetalHanoiTowersRenderer.firstIndex(ofTower: 0, count: count, towerCount: towers)
    let j = MetalHanoiTowersRenderer.firstIndex(ofTower: 1, count: count, towerCount: towers)
    let obstacleCount =
      MetalHanoiTowersRenderer.obstacles(above: i, count: count, towerCount: towers).count
      + MetalHanoiTowersRenderer.obstacles(above: j, count: count, towerCount: towers).count
    #expect(obstacleCount > 32, "test setup: this scenario must actually exceed the threshold")
    let obstacle = MetalHanoiTowersRenderer.obstacles(above: i, count: count, towerCount: towers)
      .lowerBound

    let beforeObstacleOrigin = renderer.debugInstances()[obstacle].origin
    let beforeSwapOrigin = renderer.debugInstances()[i].origin

    values.swapAt(i, j)
    renderer.apply(.swap(i, j), values: values, valueRange: 1...count, markers: [:])

    let afterObstacleOrigin = renderer.debugInstances()[obstacle].origin
    let afterSwapOrigin = renderer.debugInstances()[i].origin
    #expect(
      afterObstacleOrigin.startTime == beforeObstacleOrigin.startTime,
      "an obstacle past the threshold must never be scheduled at all, not just settle quickly")
    #expect(
      afterObstacleOrigin.leg0To == beforeObstacleOrigin.leg0To,
      "an unscheduled obstacle's coordinate must stay exactly at its own home")
    #expect(
      afterSwapOrigin.startTime != beforeSwapOrigin.startTime,
      "the swapped pair's own animation must still be scheduled regardless of obstacle count")
  }
}
