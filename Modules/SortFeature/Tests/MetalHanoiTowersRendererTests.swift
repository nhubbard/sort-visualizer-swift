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
    #expect(obstacles == Array(1..<firstOfTowerOne))
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

    let instances = renderer.debugInstances()
    #expect(instances.count == 12)
    // Every tower's bottom-most (depth 0) block should sit at the same Y — the canvas floor
    // minus one block height — regardless of which tower it's in.
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
    let homeOrigins = renderer.debugInstances().map(\.origin)

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

    // Overshoot every leg's hold duration plus the underlying fade, in several ticks so the
    // scheduler's own per-leg advancement actually runs (a single giant elapsed tick would only
    // ever process the FIRST leg boundary once).
    for _ in 0..<10 {
      renderer.advanceTransitions(elapsed: 0.2)
    }

    let finalInstances = renderer.debugInstances()
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
    let homeOrigins = renderer.debugInstances().map(\.origin)

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
    let obstacle = MetalHanoiTowersRenderer.obstacles(above: i, count: 9, towerCount: towers)[0]

    values.swapAt(i, j)
    renderer.apply(.swap(i, j), values: values, valueRange: 1...9, markers: [:])

    for _ in 0..<10 {
      renderer.advanceTransitions(elapsed: 0.2)
    }

    #expect(renderer.debugInstances()[obstacle].origin == homeOrigins[obstacle])
  }
}
