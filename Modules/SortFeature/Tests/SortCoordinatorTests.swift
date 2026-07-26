import AlgorithmKit
import Foundation
import SettingsKit
import Testing

@testable import SortEngineKit
@testable import SortFeature

/// Minimal fakes, duplicated from `SortSessionTests.swift` rather than shared — that file's own
/// `FakeAlgorithm`/`FakeReverseShuffle`/`makeFastSettings()` are `private`, so a second test file
/// in the same target can't see them either.
private struct FakeAlgorithm: SortAlgorithm {
  let id = AlgorithmID(rawValue: "coordinator-fake")
  var metadata: AlgorithmMetadata {
    AlgorithmMetadata(
      displayName: "Coordinator Fake", category: .exchange, sizeRange: 1...64,
      growthModel: .unconstrained,
      stable: true,
      timeComplexity: ComplexityBounds(best: "O(n)", average: "O(n^2)", worst: "O(n^2)"),
      spaceComplexity: "O(1)", iconName: "fake")
  }
  func record(into engine: inout RecordingEngine) {}
}

private struct FakeShuffle: ShuffleAlgorithm {
  let id = ShuffleID(rawValue: "coordinator-fake-shuffle")
  let metadata = ShuffleMetadata(displayName: "Coordinator Fake Shuffle")
  func record(into engine: inout RecordingEngine) {}
}

@MainActor
private func makeFastSettings() -> AppSettings {
  let store = UserDefaults(suiteName: "SortCoordinatorTests.\(UUID().uuidString)")!
  let settings = AppSettings(store: store)
  settings.playbackSpeed = 100_000
  return settings
}

@MainActor
@Suite
struct SortCoordinatorTests {
  @Test
  func registeringAndUnregisteringActiveSessionTracksTheRightAlgorithm() {
    let coordinator = SortCoordinator()
    let session = SortSession(
      algorithm: FakeAlgorithm(), shuffle: FakeShuffle(), settings: makeFastSettings())
    let algorithmID = AlgorithmID(rawValue: "coordinator-fake")

    #expect(coordinator.activeSortSession == nil)

    coordinator.registerActiveSession(session, for: algorithmID)
    #expect(coordinator.activeSortSession === session)

    // A mismatched algorithm ID (e.g. a stale unregister from a view that already lost the
    // race to a newer one mounting) must not clear a still-current registration.
    coordinator.unregisterActiveSession(for: AlgorithmID(rawValue: "someone-else"))
    #expect(coordinator.activeSortSession === session)

    coordinator.unregisterActiveSession(for: algorithmID)
    #expect(coordinator.activeSortSession == nil)
  }

  @Test
  func pendingActionAndShuffleOverrideAreConsumedExactlyOnce() async {
    let coordinator = SortCoordinator()
    let algorithm = FakeAlgorithm()
    let shuffle = FakeShuffle()

    let runTask = Task {
      await coordinator.runSort(
        algorithm: algorithm, visualizerID: nil, shuffleID: shuffle.id, size: 12)
    }
    // `runSort` suspends on its own continuation — give its synchronous prefix (through
    // `beginRun`) a chance to run before inspecting coordinator state.
    await Task.yield()

    #expect(coordinator.selectedAlgorithmID == algorithm.id)
    #expect(coordinator.pendingShuffleOverride(for: algorithm.id) == shuffle.id)

    guard
      case .run(let visualizerID, let size) = coordinator.consumePendingAction(for: algorithm.id)
    else {
      Issue.record("expected a .run pending action")
      coordinator.resolveCompletion(token: coordinator.runToken)
      await runTask.value
      return
    }
    #expect(visualizerID == nil)
    #expect(size == 12)

    // Consumed: a second read finds nothing left, for either the action or its shuffle override.
    #expect(coordinator.consumePendingAction(for: algorithm.id) == nil)
    #expect(coordinator.pendingShuffleOverride(for: algorithm.id) == nil)

    coordinator.resolveCompletion(token: coordinator.runToken)
    await runTask.value  // proves runSort() was still suspended until resolveCompletion above
  }

  @Test
  func runAutomationSelectsTheAlgorithmAndAwaitsResolveCompletion() async {
    let coordinator = SortCoordinator()
    let algorithm = FakeAlgorithm()
    let automationID = AutomationID(rawValue: "coordinator-fake-automation")

    var resumed = false
    let runTask = Task {
      await coordinator.runAutomation(algorithm: algorithm, automationID: automationID)
      resumed = true
    }
    await Task.yield()

    #expect(coordinator.selectedAlgorithmID == algorithm.id)
    #expect(!resumed)  // still suspended: resolveCompletion hasn't been called yet

    guard case .automation(let resolvedID) = coordinator.consumePendingAction(for: algorithm.id)
    else {
      Issue.record("expected an .automation pending action")
      coordinator.resolveCompletion(token: coordinator.runToken)
      await runTask.value
      return
    }
    #expect(resolvedID == automationID)

    coordinator.resolveCompletion(token: coordinator.runToken)
    await runTask.value
    #expect(resumed)
  }

  @Test
  func eachRunBumpsRunTokenEvenForTheSameAlgorithm() async {
    let coordinator = SortCoordinator()
    let algorithm = FakeAlgorithm()
    let firstToken = coordinator.runToken

    let firstRun = Task {
      await coordinator.runSort(algorithm: algorithm, visualizerID: nil, shuffleID: nil, size: nil)
    }
    await Task.yield()
    let tokenAfterFirstRun = coordinator.runToken
    #expect(tokenAfterFirstRun != firstToken)
    _ = coordinator.consumePendingAction(for: algorithm.id)
    coordinator.resolveCompletion(token: tokenAfterFirstRun)
    await firstRun.value

    // Re-running the *same* algorithm again must bump the token again — this is what forces
    // `ContentView`'s `.id(...)` to mount a genuinely fresh `SortSession` instead of no-op'ing.
    let secondRun = Task {
      await coordinator.runSort(algorithm: algorithm, visualizerID: nil, shuffleID: nil, size: nil)
    }
    await Task.yield()
    let tokenAfterSecondRun = coordinator.runToken
    #expect(tokenAfterSecondRun != tokenAfterFirstRun)
    _ = coordinator.consumePendingAction(for: algorithm.id)
    coordinator.resolveCompletion(token: tokenAfterSecondRun)
    await secondRun.value
  }

  @Test
  func stopDelegatesToTheActiveSessionsStopAutomation() async throws {
    let coordinator = SortCoordinator()
    let session = SortSession(
      algorithm: FakeAlgorithm(), shuffle: FakeShuffle(), settings: makeFastSettings())
    let algorithmID = AlgorithmID(rawValue: "coordinator-fake")
    coordinator.registerActiveSession(session, for: algorithmID)

    // No `await`/suspension point between these two calls: `runAutomation(_:)` only *spawns*
    // its automation `Task`, which can't get a chance to run its first iteration until this
    // synchronous stretch of MainActor code actually yields — so `stop()` here is guaranteed
    // to cancel it before that Task ever calls `start(size:)`, making this deterministic
    // regardless of scheduler timing (unlike driving a real `ReplayEngine`/`CADisplayLink` to
    // genuine completion, which `SortSessionTests.swift` documents as having no guaranteed
    // tick latency in this host-less `.unitTests` bundle).
    session.runAutomation(sampleAutomation())
    coordinator.stop()

    let deadline = ContinuousClock.now + .seconds(3)
    while ContinuousClock.now < deadline, session.isAutomating {
      try await Task.sleep(for: .milliseconds(5))
    }
    #expect(!session.isAutomating)
  }

  /// Regression test: `runAutomationAndWait` used to call the fire-and-forget
  /// `runAutomation(_:)` (which only *spawns* a `Task` doing the real work) and then immediately
  /// `guard isAutomating else { return }` with no intervening `await` — a freshly spawned
  /// `Task`'s body cannot possibly have run yet at that point, so `isAutomating` was always still
  /// `false` and this returned instantly, before the sweep did any real work. If this regresses,
  /// `session.phase` below would still read `.idle` (or `.recording`) the instant
  /// `runAutomationAndWait` returns, not `.complete`.
  @Test
  func runAutomationAndWaitDoesNotReturnBeforeTheSweepGenuinelyFinishes() async throws {
    let session = SortSession(
      algorithm: FakeAlgorithm(), shuffle: FakeShuffle(), settings: makeFastSettings())

    await session.runAutomationAndWait(sampleAutomation())

    #expect(!session.isAutomating)
    guard case .complete = session.phase else {
      Issue.record("expected .complete once runAutomationAndWait returns, got \(session.phase)")
      return
    }
  }
}

/// `AutomationRegistry.shared` is only populated by the real app's composition root — this test
/// doesn't depend on that having happened, so it builds its own throwaway `Automation` instead.
private func sampleAutomation() -> Automation {
  Automation(
    id: AutomationID(rawValue: "coordinator-fake-automation"), displayName: "Fake",
    iconName: "fake",
    key: "a", modifiers: [.command], runsPerSize: 3, sizes: { [$0.sizeRange.upperBound] })
}
