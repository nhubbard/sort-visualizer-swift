import AlgorithmKit
import Foundation
import SortEngineKit
import Testing
import VisualizationKit

@testable import SortFeature

/// Uses small synthetic registries to verify enumeration and durable progress. The run-loop test
/// resolves `SortCoordinator`'s pending actions as a mounted sort view would, so it can exercise
/// cancellation and resume without waiting for animated playback.
private struct SweepTestAlgorithm: SortAlgorithm {
  let id = AlgorithmID(rawValue: "sweep-test-algorithm")
  var metadata: AlgorithmMetadata {
    AlgorithmMetadata(
      displayName: "Sweep Test", category: .exchange, sizeRange: 1...32,
      growthModel: .unconstrained, implementationComplexity: 0, stable: true,
      timeComplexity: ComplexityBounds(best: "O(n)", average: "O(n)", worst: "O(n)"),
      spaceComplexity: "O(1)", iconName: "square")
  }
  func record(into engine: inout RecordingEngine) {}
}

private struct SweepTestShuffle: ShuffleAlgorithm {
  let id = ShuffleID(rawValue: "sweep-test-shuffle")
  let metadata = ShuffleMetadata(displayName: "Sweep Test Shuffle")
  func record(into engine: inout RecordingEngine) {}
}

private struct SweepTestVisualizer: Visualizer {
  let id: VisualizerID
  var metadata: VisualizerMetadata {
    VisualizerMetadata(displayName: id.rawValue, supportsAuxArrays: false, iconName: "square")
  }
  func draw(_ context: VisualizationContext) -> [DrawCommand] { [] }
}

@Suite(.serialized)
struct CoverageSweepDriverTests {
  private static let a1 = AlgorithmID(rawValue: "alg1")
  private static let a2 = AlgorithmID(rawValue: "alg2")
  private static let s1 = ShuffleID(rawValue: "shuffle1")
  private static let s2 = ShuffleID(rawValue: "shuffle2")
  private static let v1 = VisualizerID(rawValue: "vis1")
  private static let v2 = VisualizerID(rawValue: "vis2")

  @Test
  func keyIsTabSeparatedAndRoundTripsThroughParseLog() {
    let combo = CoverageSweepEnumerator.Combo(algorithmID: Self.a1, shuffleID: Self.s1, visualizerID: Self.v1)
    let key = CoverageSweepEnumerator.key(for: combo)
    #expect(key == "alg1\tshuffle1\tvis1")

    let parsed = CoverageSweepEnumerator.parseLog(key + "\n")
    #expect(parsed == [key])
  }

  @Test
  func parseLogDropsMalformedAndBlankLines() {
    // A truncated trailing line (the signature of a crash mid-append) and a stray blank line
    // must both be silently dropped rather than treated as parse errors — losing at most the one
    // in-flight line is the whole point of appending one line at a time.
    let contents = "alg1\tshuffle1\tvis1\n\nalg2\tshuffle1\n\talg3-not-enough-fields\nalg2\tshuffle2\tvis2\n"
    let parsed = CoverageSweepEnumerator.parseLog(contents)
    #expect(parsed == ["alg1\tshuffle1\tvis1", "alg2\tshuffle2\tvis2"])
  }

  @Test
  func nextUncoveredReturnsFirstComboInNestedOrder() {
    let combo = CoverageSweepEnumerator.nextUncovered(
      algorithmIDs: [Self.a1, Self.a2], shuffleIDs: [Self.s1, Self.s2],
      visualizerIDs: [Self.v1, Self.v2], completedKeys: [])
    #expect(combo == CoverageSweepEnumerator.Combo(algorithmID: Self.a1, shuffleID: Self.s1, visualizerID: Self.v1))
  }

  @Test
  func nextUncoveredSkipsAlreadyCompletedKeys() {
    let firstThree: Set<String> = [
      "alg1\tshuffle1\tvis1",
      "alg1\tshuffle1\tvis2",
      "alg1\tshuffle2\tvis1",
    ]
    let combo = CoverageSweepEnumerator.nextUncovered(
      algorithmIDs: [Self.a1, Self.a2], shuffleIDs: [Self.s1, Self.s2],
      visualizerIDs: [Self.v1, Self.v2], completedKeys: firstThree)
    #expect(combo == CoverageSweepEnumerator.Combo(algorithmID: Self.a1, shuffleID: Self.s2, visualizerID: Self.v2))
  }

  @Test
  func nextUncoveredReturnsNilOnceEveryComboIsCovered() {
    var completed: Set<String> = []
    for algorithmID in [Self.a1, Self.a2] {
      for shuffleID in [Self.s1, Self.s2] {
        for visualizerID in [Self.v1, Self.v2] {
          completed.insert(
            CoverageSweepEnumerator.key(
              for: CoverageSweepEnumerator.Combo(
                algorithmID: algorithmID, shuffleID: shuffleID, visualizerID: visualizerID)))
        }
      }
    }
    let combo = CoverageSweepEnumerator.nextUncovered(
      algorithmIDs: [Self.a1, Self.a2], shuffleIDs: [Self.s1, Self.s2],
      visualizerIDs: [Self.v1, Self.v2], completedKeys: completed)
    #expect(combo == nil)
  }

  /// The whole reason coverage is tracked by genuine ID strings rather than a positional cursor:
  /// a removed algorithm's completed keys should simply never come up again (no crash, no
  /// phantom re-run), and a newly-added algorithm should be picked up as uncovered immediately,
  /// even though it wasn't part of the registry when `completedKeys` was recorded.
  @Test
  func nextUncoveredIsRobustToRegistryCompositionChangesBetweenSessions() {
    let a3 = AlgorithmID(rawValue: "alg3-added-later")
    // `alg1` was fully covered against every shuffle/visualizer in an earlier "session" (before
    // `alg1` was itself removed from the registry) — its keys linger in the log but should never
    // be produced or consulted again since `alg1` is absent from the current registry.
    let staleCompletedKeys: Set<String> = [
      "alg1\tshuffle1\tvis1", "alg1\tshuffle1\tvis2", "alg1\tshuffle2\tvis1", "alg1\tshuffle2\tvis2",
    ]

    let combo = CoverageSweepEnumerator.nextUncovered(
      algorithmIDs: [Self.a2, a3], shuffleIDs: [Self.s1, Self.s2], visualizerIDs: [Self.v1, Self.v2],
      completedKeys: staleCompletedKeys)

    // Neither `alg2` nor the newly-added `alg3` has any completed keys, so the very first combo
    // in the (now `alg1`-free) registry order is uncovered.
    #expect(combo == CoverageSweepEnumerator.Combo(algorithmID: Self.a2, shuffleID: Self.s1, visualizerID: Self.v1))

    // Covering every `alg2`/`alg3` combo (but leaving the stale `alg1` keys untouched) must
    // report full coverage rather than getting stuck re-deriving something for `alg1`.
    var completed = staleCompletedKeys
    for algorithmID in [Self.a2, a3] {
      for shuffleID in [Self.s1, Self.s2] {
        for visualizerID in [Self.v1, Self.v2] {
          completed.insert(
            CoverageSweepEnumerator.key(
              for: CoverageSweepEnumerator.Combo(
                algorithmID: algorithmID, shuffleID: shuffleID, visualizerID: visualizerID)))
        }
      }
    }
    let none = CoverageSweepEnumerator.nextUncovered(
      algorithmIDs: [Self.a2, a3], shuffleIDs: [Self.s1, Self.s2], visualizerIDs: [Self.v1, Self.v2],
      completedKeys: completed)
    #expect(none == nil)
  }

  @MainActor
  @Test
  func loadProgressReadsAnExistingLogFileIntoCompletedCount() throws {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent(
      "CoverageSweepDriverTests-\(UUID().uuidString).tsv")
    defer { try? FileManager.default.removeItem(at: url) }
    try "alg1\tshuffle1\tvis1\nalg1\tshuffle1\tvis2\n".write(to: url, atomically: true, encoding: .utf8)

    let driver = CoverageSweepDriver(logURL: url)
    #expect(driver.completedCount == 0)
    driver.loadProgress()
    #expect(driver.completedCount == 2)
  }

  @MainActor
  @Test
  func loadProgressTreatsAMissingLogFileAsZeroProgress() {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent(
      "CoverageSweepDriverTests-missing-\(UUID().uuidString).tsv")
    let driver = CoverageSweepDriver(logURL: url)
    driver.loadProgress()
    #expect(driver.completedCount == 0)
  }

  @MainActor
  @Test
  func isRunningIsFalseAndEstimatedTimeRemainingIsNilBeforeStart() {
    let driver = CoverageSweepDriver(
      logURL: FileManager.default.temporaryDirectory.appendingPathComponent(
        "CoverageSweepDriverTests-idle-\(UUID().uuidString).tsv"))
    #expect(!driver.isRunning)
    #expect(driver.estimatedTimeRemaining() == nil)
    #expect(driver.currentCombo == nil)
  }

  @MainActor
  @Test
  func stoppedSweepLogsFinishedComboAndResumesAtNextVisualizer() async throws {
    let algorithms = AlgorithmRegistry.shared
    let shuffles = ShuffleRegistry.shared
    let visualizers = VisualizerRegistry.shared
    let restoreAlgorithms = algorithms.builtIns
    let restoreShuffles = shuffles.builtIns
    let restoreVisualizers = visualizers.builtIns
    let coordinator = SortCoordinator.shared
    let restoreSelection = coordinator.selectedAlgorithmID
    let url = FileManager.default.temporaryDirectory.appendingPathComponent(
      "CoverageSweepDriverTests-resume-\(UUID().uuidString).tsv")
    defer {
      coordinator.resolveCompletion(token: coordinator.runToken)
      coordinator.selectedAlgorithmID = restoreSelection
      algorithms.builtIns = restoreAlgorithms
      algorithms.discover()
      shuffles.builtIns = restoreShuffles
      shuffles.discover()
      visualizers.builtIns = restoreVisualizers
      visualizers.discover()
      try? FileManager.default.removeItem(at: url)
    }
    let algorithm = SweepTestAlgorithm()
    let shuffle = SweepTestShuffle()
    let firstStyle = SweepTestVisualizer(id: Self.v1)
    let secondStyle = SweepTestVisualizer(id: Self.v2)
    algorithms.builtIns = [algorithm]
    algorithms.discover()
    shuffles.builtIns = [shuffle]
    shuffles.discover()
    visualizers.builtIns = [firstStyle, secondStyle]
    visualizers.discover()

    let firstDriver = CoverageSweepDriver(logURL: url)
    #expect(firstDriver.totalCount == 2)
    firstDriver.start()
    let firstQueued = await waitUntil {
      coordinator.pendingActionWillAutomate(for: algorithm.id)
    }
    #expect(firstQueued)
    firstDriver.stop()
    guard case .run(let firstID, _) = coordinator.consumePendingAction(for: algorithm.id) else {
      Issue.record("first sweep combination was not queued")
      return
    }
    #expect(firstID == firstStyle.id)
    coordinator.resolveCompletion(token: coordinator.runToken)
    #expect(await waitUntil { !firstDriver.isRunning })
    #expect(firstDriver.completedCount == 1)
    #expect(firstDriver.estimatedTimeRemaining() != nil)

    let resumedDriver = CoverageSweepDriver(logURL: url)
    resumedDriver.loadProgress()
    #expect(resumedDriver.completedCount == 1)
    resumedDriver.start()
    let secondQueued = await waitUntil {
      coordinator.pendingActionWillAutomate(for: algorithm.id)
    }
    #expect(secondQueued)
    guard case .run(let secondID, _) = coordinator.consumePendingAction(for: algorithm.id) else {
      Issue.record("resumed sweep did not queue the remaining combination")
      return
    }
    #expect(secondID == secondStyle.id)
    coordinator.resolveCompletion(token: coordinator.runToken)
    #expect(await waitUntil { !resumedDriver.isRunning })
    #expect(resumedDriver.completedCount == 2)
    #expect(resumedDriver.estimatedTimeRemaining() == 0)
    let logged = try String(contentsOf: url, encoding: .utf8)
    #expect(CoverageSweepEnumerator.parseLog(logged).count == 2)
    #expect(logged.components(separatedBy: "\n").filter { !$0.isEmpty } == [
      "sweep-test-algorithm\tsweep-test-shuffle\tvis1",
      "sweep-test-algorithm\tsweep-test-shuffle\tvis2"
    ])
  }

  @MainActor
  private func waitUntil(_ condition: @MainActor () -> Bool) async -> Bool {
    let clock = ContinuousClock()
    let deadline = clock.now.advanced(by: .seconds(2))
    while !condition() && clock.now < deadline {
      try? await Task.sleep(for: .milliseconds(5))
    }
    return condition()
  }
}
