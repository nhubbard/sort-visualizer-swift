import Metal
import Testing
import os

@testable import SortFeature

/// Throwaway profiling harness, NOT a correctness/regression test — investigating the user's
/// report that Hanoi Towers "regularly freezes during the shuffle visualization" at 1-second Fixed
/// Duration while every other visualizer stays smooth. Delete this file once that investigation is
/// closed out; it exists to give `xcrun xctrace`/Instruments a long, exclusively-Hanoi profiling
/// window to attach to, without needing Full Sweep to happen to be on `hanoisort` right now (it
/// already isn't — 690/690 of its combos are done) or GUI automation to force it back there
/// (unavailable in this sandbox).
///
/// Bypasses `ReplayEngine`/`CADisplayLink` entirely and drives `MetalHanoiTowersRenderer.apply`
/// directly, in the same `maxOperationsPerChunk`-sized synchronous chunks (see `ReplayEngine.play`)
/// real Fixed Duration playback would need to hit a 1s target on a long tape — that chunk-then-
/// `Task.yield()` shape, not real vsync timing, is the actual mechanism suspected of the freeze, so
/// reproducing it directly is both simpler and more reliable in a headless test bundle than routing
/// through a real `CADisplayLink` (which has no guaranteed tick latency here — see
/// `SortSessionTests`'s own doc comments on that).
@Suite
struct HanoiStressHarnessTests {
  /// Mirrors `ReplayEngine.maxOperationsPerChunk` (private there) — the batch size Fixed Duration
  /// playback can genuinely ask for in one synchronous burst on a tape long/fast enough to need it.
  private static let chunkSize = 2000

  private static let hanoiSignposter = OSSignposter(
    subsystem: "com.nhubbard.Sort2.mobile", category: "HanoiStressHarness")

  /// A `HanoiSort`-style cross-tower swap between the two towers' own bottom (depth-0) blocks —
  /// the worst case for `MetalHanoiTowersRenderer.choreographSwap`: a depth-0 index has every
  /// OTHER member of its tower as an obstacle above it (see `obstacles(above:count:towerCount:)`),
  /// so this is the maximum obstacle count `scheduleObstacle` can be asked to animate for a single
  /// swap at this array size.
  private static func adversarialSwapSequence(count: Int, towerCount: Int, length: Int) -> [(Int, Int)] {
    var pairs: [(Int, Int)] = []
    for tower in 0..<(towerCount - 1) {
      let i = MetalHanoiTowersRenderer.firstIndex(ofTower: tower, count: count, towerCount: towerCount)
      let j = MetalHanoiTowersRenderer.firstIndex(ofTower: tower + 1, count: count, towerCount: towerCount)
      guard i != j else { continue }
      pairs.append((i, j))
    }
    guard !pairs.isEmpty else { return [] }
    var sequence: [(Int, Int)] = []
    sequence.reserveCapacity(length)
    while sequence.count < length {
      sequence.append(contentsOf: pairs)
    }
    return Array(sequence.prefix(length))
  }

  /// Two same-tower swaps (depth-0/depth-1 within tower 0) — `choreographSwap`'s cheap path,
  /// skipping the obstacle dance entirely (see its own doc comment: "same-tower swaps skip the
  /// obstacle dance ... deliberately out of scope"). This is the control: whatever `apply` costs
  /// here is roughly what every OTHER renderer's swap costs, since none of them have a per-swap
  /// obstacle-lifting step at all.
  private static func cheapSwapSequence(count: Int, towerCount: Int, length: Int) -> [(Int, Int)] {
    let i = MetalHanoiTowersRenderer.firstIndex(ofTower: 0, count: count, towerCount: towerCount)
    let j = i + 1
    guard j < count else { return [] }
    return Array(repeating: (i, j), count: length)
  }

  @MainActor
  @Test(.timeLimit(.minutes(3)))
  func worstCaseCrossTowerSwapsAgainstCheapSameTowerSwaps() async throws {
    let device = try #require(MTLCreateSystemDefaultDevice())
    let renderer = try #require(MetalHanoiTowersRenderer(device: device))

    let count = 256
    var values = Array(1...count)
    let towerCount = MetalHanoiTowersRenderer.towerCount(for: count)
    renderer.reset(
      values: values, valueRange: 1...count, markers: [:],
      canvasSize: CGSize(width: 1600, height: 1200), scale: 2)

    // Run for a fixed wall-clock budget rather than a fixed op count, alternating adversarial and
    // cheap chunks so both show up side by side in the same trace for direct comparison — a real
    // Full Sweep run interleaves plenty of both kinds of swap within one algorithm's tape too.
    let budget = ContinuousClock.now + .seconds(75)
    var adversarialTotal: Duration = .zero
    var adversarialChunks = 0
    var cheapTotal: Duration = .zero
    var cheapChunks = 0

    while ContinuousClock.now < budget {
      let adversarial = Self.adversarialSwapSequence(count: count, towerCount: towerCount, length: Self.chunkSize)
      let adversarialElapsed = try await applyChunk(
        adversarial, label: "adversarial", renderer: renderer, values: &values, valueRange: 1...count)
      adversarialTotal += adversarialElapsed
      adversarialChunks += 1

      let cheap = Self.cheapSwapSequence(count: count, towerCount: towerCount, length: Self.chunkSize)
      let cheapElapsed = try await applyChunk(
        cheap, label: "cheap", renderer: renderer, values: &values, valueRange: 1...count)
      cheapTotal += cheapElapsed
      cheapChunks += 1
    }

    print("HANOI-STRESS adversarial chunks=\(adversarialChunks) total=\(adversarialTotal)")
    print("HANOI-STRESS cheap chunks=\(cheapChunks) total=\(cheapTotal)")
    if adversarialChunks > 0 {
      print("HANOI-STRESS adversarial avg/chunk=\(adversarialTotal / adversarialChunks)")
    }
    if cheapChunks > 0 {
      print("HANOI-STRESS cheap avg/chunk=\(cheapTotal / cheapChunks)")
    }
    #expect(adversarialChunks > 0)
  }

  @MainActor
  private func applyChunk(
    _ pairs: [(Int, Int)], label: String, renderer: MetalHanoiTowersRenderer, values: inout [Int],
    valueRange: ClosedRange<Int>
  ) async throws -> Duration {
    guard !pairs.isEmpty else { return .zero }
    let id = Self.hanoiSignposter.makeSignpostID()
    let interval = Self.hanoiSignposter.beginInterval(
      "HarnessChunkApply", id: id, "\(label) \(pairs.count) ops")
    let start = ContinuousClock.now
    for (i, j) in pairs {
      values.swapAt(i, j)
      renderer.apply(.swap(i, j), values: values, valueRange: valueRange, markers: [:])
    }
    let elapsed = ContinuousClock.now - start
    Self.hanoiSignposter.endInterval("HarnessChunkApply", interval)
    await Task.yield()
    return elapsed
  }
}
