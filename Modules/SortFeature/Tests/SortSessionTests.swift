import AlgorithmKit
import AudioEngineKit
import Foundation
import SettingsKit
import SortAudioCore
import SwiftData
import SwiftUI
import Testing

@testable import PersistenceKit
@testable import SortEngineKit
@testable import SortFeature

/// Test-only stand-in for `ReplayEngine`'s internal `DisplayLinkDriving` seam (see
/// `ReplayEngineTests.swift`'s identical `ManualTickDriver` in `SortEngineKit`'s own test target —
/// duplicated here rather than shared because test targets can't import each other's test code)
/// — gives a test full, instant control over "how much time just passed" via `fireTick(elapsed:)`
/// instead of racing a real `CADisplayLink`, which has no guaranteed tick latency in this
/// module's host-less `.unitTests` bundle.
private final class ManualTickDriver: DisplayLinkDriving {
  private var onTick: ((TimeInterval) -> Void)?

  func start(onTick: @escaping (TimeInterval) -> Void) {
    self.onTick = onTick
  }

  func stop() {
    onTick = nil
  }

  func fireTick(elapsed: TimeInterval) {
    onTick?(elapsed)
  }
}

/// Bubble sort — mirrors `Legacy/.../BubbleSortImpl.swift`'s logic, duplicated here (rather than
/// depending on `BuiltInAlgorithms`) so this test target only needs `AlgorithmKit`/`SortEngineKit`.
private struct FakeAlgorithm: SortAlgorithm {
  let id = AlgorithmID(rawValue: "fake")
  // 513, not 512: `effectiveSizeRange` now rounds its computed max down to the nearest size-step
  // multiple from `sizeRange.lowerBound`, so the range's width (`upperBound - lowerBound`) needs
  // to itself be an exact multiple of the step (16) for the "reproduces plain sizeRange exactly"
  // comment below to actually hold -- 1...513 has width 512 (16 * 32); 1...512 (width 511) would
  // silently get rounded down to 1...497.
  var sizeRange: ClosedRange<Int> = 1...513
  var metadata: AlgorithmMetadata {
    AlgorithmMetadata(
      displayName: "Fake",
      category: .exchange,
      sizeRange: sizeRange,
      // A curve that only reaches any realistic operation cap at an enormous size, with
      // `measuredSafeCeiling` pinned to this fixture's own (test-varied) `sizeRange.upperBound` --
      // so `effectiveSizeRange` always reproduces plain `sizeRange` regardless of
      // `recordingOperationCap`, and tests that deliberately set a tiny cap (see the "Recording
      // size cap" tests below) exercise `RecordingEngine`'s own mid-recording cap check instead of
      // getting silently pre-clamped before recording ever starts.
      growthModel: OperationGrowthModel(
        anchorSize: 0, coefficients: [0, 1e-9], measuredSafeCeiling: sizeRange.upperBound),
      stable: true,
      timeComplexity: ComplexityBounds(best: "O(n)", average: "O(n^2)", worst: "O(n^2)"),
      spaceComplexity: "O(1)",
      iconName: "fake"
    )
  }

  func record(into engine: inout RecordingEngine) {
    guard engine.count > 1 else { return }
    for i in 1..<engine.count {
      for j in 0..<(engine.count - i) where engine.compare(j, j + 1) {
        engine.swap(j, j + 1)
      }
    }
  }
}

/// Emits exactly `auxWriteCount` `.auxWrite` operations and nothing else audible-adjacent — a
/// minimal fixture for testing `SortSession.makeOnStepClosure`'s `.auxWrite` throttling in
/// isolation, without any real algorithm's `.compare`/`.swap` traffic muddying the count.
private struct FakeAuxWritingAlgorithm: SortAlgorithm {
  let id = AlgorithmID(rawValue: "fake-auxwrite")
  let auxWriteCount: Int
  var metadata: AlgorithmMetadata {
    AlgorithmMetadata(
      displayName: "Fake Aux Writing",
      category: .exchange,
      sizeRange: 2...16,
      growthModel: OperationGrowthModel(
        anchorSize: 0, coefficients: [0, 1e-9], measuredSafeCeiling: 16),
      stable: true,
      timeComplexity: ComplexityBounds(best: "O(n)", average: "O(n)", worst: "O(n)"),
      spaceComplexity: "O(1)",
      iconName: "fake"
    )
  }

  func record(into engine: inout RecordingEngine) {
    let handle = engine.createAuxArray(length: max(auxWriteCount, 1))
    for i in 0..<auxWriteCount {
      engine.writeAux(handle, at: i % max(auxWriteCount, 1), value: i)
    }
    engine.deleteAuxArray(handle)
  }
}

/// Records every `play(...)` call's arguments — this test target has no `AudioPlaying`
/// conformance besides the real `AudioService`/`NoOpAudioService`, so a minimal spy is needed to
/// assert on `SortSession.makeOnStepClosure`'s actual sound dispatch (which operations trigger a
/// call, with what `operationKind`) rather than just the visual/tape-level behavior every other
/// test in this file checks.
@MainActor
private final class RecordingAudioService: AudioPlaying {
  struct Call: Equatable {
    let value: Int
    let index: Int
    let arraySize: Int
    let operationKind: SortOperationKind
  }
  private(set) var calls: [Call] = []

  func start() throws {}
  func stop() {}
  func play(
    value: Int, in range: ClosedRange<Int>, holdSeconds: Double, index: Int, arraySize: Int,
    operationKind: SortOperationKind
  ) {
    calls.append(Call(value: value, index: index, arraySize: arraySize, operationKind: operationKind))
  }
}

private struct FakeIdentityShuffle: ShuffleAlgorithm {
  let id = ShuffleID(rawValue: "fake-identity")
  let metadata = ShuffleMetadata(displayName: "Fake Identity")
  func record(into engine: inout RecordingEngine) {}
}

private struct FakeReverseShuffle: ShuffleAlgorithm {
  let id = ShuffleID(rawValue: "fake-reverse")
  let metadata = ShuffleMetadata(displayName: "Fake Reverse")
  func record(into engine: inout RecordingEngine) {
    for i in 0..<(engine.count / 2) {
      engine.swap(i, engine.count - 1 - i)
    }
  }
}

/// Records a fixed, non-identity, non-reverse permutation, so tests can prove sortedness holds
/// for an arrangement that isn't one of the two trivial cases above.
private struct FakeRotateShuffle: ShuffleAlgorithm {
  let id = ShuffleID(rawValue: "fake-rotate")
  let metadata = ShuffleMetadata(displayName: "Fake Rotate")
  func record(into engine: inout RecordingEngine) {
    guard engine.count > 1 else { return }
    for i in 0..<(engine.count - 1) {
      engine.swap(i, engine.count - 1)
    }
  }
}

@MainActor
private func waitUntilTerminal(_ session: SortSession, timeout: Duration = .seconds(5)) async throws {
  let deadline = ContinuousClock.now + timeout
  while ContinuousClock.now < deadline {
    switch session.phase {
    case .complete, .failed:
      return
    default:
      try await Task.sleep(for: .milliseconds(5))
    }
  }
  struct TimedOut: Error {}
  throw TimedOut()
}

/// Very fast playback so tests don't spend real wall-clock time watching bars animate.
@MainActor
private func makeFastSettings() -> AppSettings {
  let store = UserDefaults(suiteName: "SortSessionTests.\(UUID().uuidString)")!
  let settings = AppSettings(store: store)
  settings.playbackSpeed = 100_000
  return settings
}

/// Isolated, in-memory, non-CloudKit container per test — mirrors `AnalyticsServiceTests`'
/// `makeInMemoryService()` (duplicated rather than shared, same "test targets can't import each
/// other's test code" reason `ManualTickDriver` above is duplicated).
private func makeInMemoryAnalytics() throws -> AnalyticsService {
  let schema = Schema([BigORecord.self, RecordingCapExceededRecord.self])
  let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
  let container = try ModelContainer(for: schema, configurations: [configuration])
  return AnalyticsService(modelContainer: container)
}

@MainActor
@Suite
struct SortSessionTests {
  /// Regression guard for a real, measured mount-race: without `startsAutomating`, a freshly
  /// constructed session always began `isAutomating == false` until its own `.task` actually
  /// reached `runSinglePass`/`runAutomationAndWait` — a window `ScrollingSortView` could render
  /// `AlgorithmDetailSection` (and start highlighting) in, on every Full Sweep combo, before that
  /// automating pass ever got a chance to flip the flag itself. `startsAutomating: true` must make
  /// `isAutomating` observably `true` immediately, with no `await`/suspension needed first.
  @Test
  func startsAutomatingSeedsIsAutomatingBeforeAnyAsyncWorkRuns() {
    let automating = SortSession(
      algorithm: FakeAlgorithm(), shuffle: FakeReverseShuffle(), settings: makeFastSettings(),
      startsAutomating: true)
    #expect(automating.isAutomating)

    let manual = SortSession(
      algorithm: FakeAlgorithm(), shuffle: FakeReverseShuffle(), settings: makeFastSettings())
    #expect(!manual.isAutomating, "the default must stay false for every existing caller")
  }

  @Test
  func sortEndToEndProducesCorrectlySortedFrame() async throws {
    let session = SortSession(
      algorithm: FakeAlgorithm(),
      shuffle: FakeReverseShuffle(),
      settings: makeFastSettings())
    let size = 9

    await session.start(size: size)
    try await waitUntilTerminal(session)

    guard case .complete(let replay) = session.phase else {
      Issue.record("expected .complete, got \(session.phase)")
      return
    }
    #expect(replay.frame.map(\.value) == Array(1...size))
  }

  /// Regression test for the reported bug: `FakeAlgorithm` (a bubble-sort shape) always ends on
  /// a bare `.compare` that returns `false` — no trailing `.swap` ever comes along to retract the
  /// primary/secondary pair that final `.compare` marked, since `RecordingEngine`'s auto-
  /// retraction (`markPrimarySecondary`) only clears the *previous* pair right before marking a
  /// new one. Without `TapeFactory.makeTape`'s trailing `unmarkAll()`, the completed, fully-
  /// sorted frame would show one index still highlighted red and another still blue, forever.
  @Test
  func completedFrameHasNoLingeringPrimaryOrSecondaryMarkers() async throws {
    let session = SortSession(
      algorithm: FakeAlgorithm(),
      shuffle: FakeReverseShuffle(),
      settings: makeFastSettings())

    await session.start(size: 9)
    try await waitUntilTerminal(session)

    guard case .complete(let replay) = session.phase else {
      Issue.record("expected .complete, got \(session.phase)")
      return
    }
    #expect(replay.frame.allSatisfy { $0.markers.isEmpty })
  }

  /// No confirmation dialog to opt out of anymore (§9 of ARCHITECTURE_V2.md — removed in favor
  /// of ArrayV's own `unreasonableLimit` precedent) — `start(size:)` itself is responsible for
  /// keeping a caller from ever requesting a size the algorithm can't reasonably handle.
  @Test
  func startClampsSizeIntoAlgorithmsSizeRange() async throws {
    let session = SortSession(
      algorithm: FakeAlgorithm(sizeRange: 5...8),
      shuffle: FakeReverseShuffle(),
      settings: makeFastSettings()
    )

    await session.start(size: 999)
    try await waitUntilTerminal(session)

    guard case .complete(let replay) = session.phase else {
      Issue.record("expected .complete, got \(session.phase)")
      return
    }
    #expect(replay.frame.count == 8)
    #expect(replay.frame.map(\.value) == Array(1...8))
  }

  /// Investigates whether `SortSession`/`ReplayEngine` genuinely leak when the last strong reference
  /// to them is dropped mid-playback — the scenario a user hits by switching detail pages (or
  /// algorithms) while a sort is actively running, not paused/complete. `beginPlayback`'s
  /// `monitorTask` and `ReplayEngine.play()`'s own loop both capture `self` as `[weak self]`, so
  /// nothing on this call chain should hold either object alive past the caller's own last strong
  /// reference — this proves that (or catches a regression if a future edit accidentally adds a
  /// strong capture back in).
  @Test
  func sortSessionAndReplayEngineDeallocateAfterLastReferenceDroppedMidPlayback() async throws {
    weak var weakSession: SortSession?
    weak var weakReplay: ReplayEngine?

    do {
      let settings = makeFastSettings()
      settings.playbackSpeed = 20.0  // slow enough that playback is still mid-flight below
      let session = SortSession(
        algorithm: FakeAlgorithm(), shuffle: FakeReverseShuffle(), settings: settings)
      weakSession = session

      await session.start(size: 12)
      guard case .replaying(let replay) = session.phase else {
        Issue.record("expected .replaying immediately after start, got \(session.phase)")
        return
      }
      weakReplay = replay

      try await Task.sleep(for: .milliseconds(50))  // genuinely mid-flight, not yet complete
      #expect(replay.isPlaying)
    }
    // `session`/`replay` were the only strong references in this test — both are now out of scope.

    // Give any already-suspended `Task` closures many chances to actually resume, notice
    // `self` is nil through their weak captures, and exit — poll instead of a single fixed
    // wait so this isn't sensitive to exactly how long that takes.
    let deadline = ContinuousClock.now + .seconds(3)
    while ContinuousClock.now < deadline, weakReplay != nil {
      try await Task.sleep(for: .milliseconds(20))
    }

    #expect(
      weakSession == nil,
      "SortSession should deallocate once nothing outside it holds a reference, even mid-playback")
    #expect(
      weakReplay == nil,
      "ReplayEngine should deallocate once nothing outside it holds a reference, even mid-playback")
  }

  /// Regression test for the pause/resume redesign: pausing mid-replay must not prematurely flip
  /// `phase` to `.complete` (the old one-shot "await the first playbackTask" design would have,
  /// since a cancelled task's `.value` still resolves), and resuming must continue from where it
  /// left off rather than restarting or getting stuck.
  ///
  /// Drives a `ManualTickDriver` directly instead of sleeping and hoping real `CADisplayLink`
  /// ticks land in the window — this module's host-less `.unitTests` bundle gives no guaranteed
  /// tick latency, so timing-dependent assertions need a deterministic driver instead.
  @Test
  func pausingThenResumingReachesCompletionWithoutLosingProgress() async throws {
    let settings = makeFastSettings()
    let driver = ManualTickDriver()
    let session = SortSession(
      algorithm: FakeAlgorithm(),
      shuffle: FakeReverseShuffle(),
      settings: settings,
      replayEngineFactory: { ReplayEngine(tape: $0, displayLinkFactory: { driver }) }
    )

    await session.start(size: 12)
    guard case .replaying(let replay) = session.phase else {
      Issue.record("expected .replaying immediately after start, got \(session.phase)")
      return
    }
    // `ReplayEngine.opsToApply` clamps a tick's elapsed time to `maxCatchUpInterval` (0.25s)
    // before multiplying by speed, so `speed` must be high enough that even the clamped
    // elapsed still yields a whole, nonzero op count — a slow speed here would silently
    // round down to 0 regardless of how large `elapsed` is.
    replay.speed = 20.0

    driver.fireTick(elapsed: 0)  // the very first tick always carries zero elapsed time
    driver.fireTick(elapsed: 1.0)  // clamped to 0.25s * 20 ops/sec = 5 ops due — partway through
    try await Task.sleep(for: .milliseconds(20))  // let play()'s Task actually process the tick
    #expect(replay.isPlaying)

    session.togglePlayback()  // pause
    #expect(!replay.isPlaying)
    let stepIndexAtPause = replay.stepIndex
    #expect(stepIndexAtPause > 0)
    #expect(stepIndexAtPause < replay.totalOperationCount)

    driver.fireTick(elapsed: 1.0)  // fired while paused — pause() already stopped the driver
    try await Task.sleep(for: .milliseconds(20))
    #expect(replay.stepIndex == stepIndexAtPause)  // nothing advances while paused

    replay.speed = 100_000.0  // finish quickly once resumed
    session.togglePlayback()  // resume — starts a fresh play() Task against the same driver
    driver.fireTick(elapsed: 0)  // the very first tick of this new play() also carries zero elapsed time
    driver.fireTick(elapsed: 1.0)  // hugely overdue at the new speed — the rest of the tape in one tick
    try await waitUntilTerminal(session)

    guard case .complete(let finished) = session.phase else {
      Issue.record("expected .complete, got \(session.phase)")
      return
    }
    #expect(finished.frame.map(\.value) == Array(1...12))
    #expect(finished.stepIndex >= stepIndexAtPause)
  }

  /// Regression test for the reset-then-play bug: Reset (and step-back, and the scrub slider)
  /// call `seek(to:)`/`stepBackward()` directly on `ReplayEngine`, bypassing `SortSession`
  /// entirely — so after a sort reaches `.complete`, scrubbing backward must still let
  /// `togglePlayback()` resume playback, not silently no-op forever because `phase` never left
  /// `.complete`.
  @Test
  func togglePlaybackResumesAfterScrubbingBackwardFromComplete() async throws {
    let session = SortSession(
      algorithm: FakeAlgorithm(),
      shuffle: FakeReverseShuffle(),
      settings: makeFastSettings())

    await session.start(size: 10)
    try await waitUntilTerminal(session)

    guard case .complete(let replay) = session.phase else {
      Issue.record("expected .complete, got \(session.phase)")
      return
    }

    replay.seek(to: replay.header.sortStartIndex)  // what the Reset button does
    #expect(replay.stepIndex < replay.totalOperationCount)

    session.togglePlayback()
    guard case .replaying = session.phase else {
      Issue.record(
        "expected .replaying after resuming from a scrubbed-back .complete, got \(session.phase)")
      return
    }
    #expect(replay.isPlaying)

    try await waitUntilTerminal(session)
    guard case .complete(let finished) = session.phase else {
      Issue.record("expected .complete again after replaying to the end, got \(session.phase)")
      return
    }
    #expect(finished.frame.map(\.value) == Array(1...10))
  }

  /// End-to-end check of the full pipeline the persisted-timing feature depends on: a genuinely
  /// completed run's `analytics.record` call must carry a real, positive `playbackDuration`
  /// (measured off `replay.elapsedPlaybackDuration` at the moment `monitorTask` observes genuine
  /// completion) and the exact `speed` the session's `AppSettings.playbackSpeed` was configured
  /// with — not the defaults `record`'s two playback parameters fall back to when omitted.
  @Test
  func completingASortRecordsAPositivePlaybackDurationAndTheConfiguredSpeed() async throws {
    // Deliberately reuses `makeFastSettings()` unmodified (100,000 ops/sec) rather than a
    // slower speed: this test uses the REAL production `ReplayEngine`/`CADisplayLink` (no
    // injected `replayEngineFactory`), and a slow speed here would need many real, closely-
    // spaced display-link ticks to accumulate enough operations — `sortEndToEndProducesCorrectlySortedFrame`
    // above already proves this exact real-driver setup completes reliably at this speed; a
    // sluggish speed made this test time out in practice.
    let settings = makeFastSettings()
    let analytics = try makeInMemoryAnalytics()
    let session = SortSession(
      algorithm: FakeAlgorithm(), shuffle: FakeReverseShuffle(),
      analytics: analytics, settings: settings
    )

    await session.start(size: 12)
    try await waitUntilTerminal(session)
    guard case .complete = session.phase else {
      Issue.record("expected .complete, got \(session.phase)")
      return
    }

    let rows = try await analytics.fetchSummaries(algorithmID: AlgorithmID(rawValue: "fake"))
    #expect(rows.count == 1)
    let playbackDuration = try #require(rows[0].playbackDuration)
    #expect(playbackDuration > 0)
    #expect(rows[0].playbackSpeed == settings.playbackSpeed)
    #expect(rows[0].recordingDuration >= 0)
  }

  @Test
  func soundEnabledIsLocalToTheSessionNotWrittenBackToSettings() {
    let settings = makeFastSettings()
    settings.soundEnabled = true
    let session = SortSession(
      algorithm: FakeAlgorithm(), shuffle: FakeReverseShuffle(), settings: settings)

    #expect(session.soundEnabled)  // seeded from the global default at construction
    session.soundEnabled = false

    #expect(settings.soundEnabled)  // toggling the session-local flag never touches the global default
  }

  /// `.auxWrite` operations do trigger sound (they used to be completely silent — see
  /// `SortOperationKind.auxWrite`'s own doc comment), but only every
  /// `SortSession.auxWriteThrottleInterval`th one, not every single occurrence — sonifying every
  /// aux write on an algorithm that does tens of thousands of them would overwhelm both the
  /// listener and `ToneCommandQueue`'s fixed capacity.
  @Test
  func auxWriteOperationsPlayThrottledNotEvery() async throws {
    let settings = makeFastSettings()
    settings.soundEnabled = true
    let audio = RecordingAudioService()
    let auxWriteCount = 40
    let session = SortSession(
      algorithm: FakeAuxWritingAlgorithm(auxWriteCount: auxWriteCount),
      shuffle: FakeIdentityShuffle(), audio: audio, settings: settings)

    await session.start(size: 2)
    try await waitUntilTerminal(session)

    #expect(audio.calls.allSatisfy { $0.operationKind == .auxWrite })
    #expect(audio.calls.count == auxWriteCount / SortSession.auxWriteThrottleInterval)
  }

  // MARK: - Recording size cap

  @Test
  func manualStartWithATinyOperationCapEndsInFailedInsteadOfReplaying() async throws {
    let settings = makeFastSettings()
    settings.recordingOperationCap = 5
    let session = SortSession(
      algorithm: FakeAlgorithm(), shuffle: FakeReverseShuffle(), settings: settings)

    await session.start(size: 12)

    guard case .failed(let error) = session.phase else {
      Issue.record("expected .failed, got \(session.phase)")
      return
    }
    guard case .recordingTooLarge = error else {
      Issue.record("expected .recordingTooLarge, got \(error)")
      return
    }
  }

  /// End-to-end proof of the manual/automation split: a size sweep with one oversized size in
  /// the middle must not hang on it (`waitUntilComplete()` would wait forever for a replay that
  /// never starts without the `lastRunWasSkipped` check in `runAutomation(sizes:runsPerSize:)`),
  /// must not leave `phase` on `.failed` (automation "pretends" a skipped run never happened —
  /// see `start(size:)`'s `previousPhase` revert), and must log exactly one write-only
  /// `RecordingCapExceededRecord` for the size that was actually skipped.
  @Test
  func automationSweepSkipsAnOversizedMiddleSizeWithoutHangingOrFailing() async throws {
    let settings = makeFastSettings()
    let analytics = try makeInMemoryAnalytics()

    // Real op counts for `FakeAlgorithm` (a bubble sort) against an already-identity array —
    // matches exactly what the sort phase inside `makeTape` records when paired with
    // `FakeIdentityShuffle` below, so the cap chosen from these is guaranteed to sit strictly
    // between the small and large sizes' real totals.
    func realSortTapeCount(size: Int) -> Int {
      var engine = RecordingEngine(values: Array(1...size))
      FakeAlgorithm().record(into: &engine)
      return engine.finish().tape.count
    }
    let smallCount = realSortTapeCount(size: 4)
    let largeCount = realSortTapeCount(size: 60)
    #expect(largeCount > smallCount, "sanity: the larger size must genuinely need more ops")
    settings.recordingOperationCap = smallCount + 10

    let session = SortSession(
      algorithm: FakeAlgorithm(), shuffle: FakeIdentityShuffle(),
      analytics: analytics, settings: settings)
    let automation = Automation(
      id: AutomationID(rawValue: "test-sweep"), displayName: "Test Sweep", iconName: "gearshape",
      key: "t", modifiers: [], runsPerSize: 1,
      sizes: { _ in [4, 60, 4] }
    )

    await session.runAutomationAndWait(automation)

    guard case .complete(let replay) = session.phase else {
      Issue.record(
        "expected the sweep to end on the final size's genuine .complete, got \(session.phase)")
      return
    }
    #expect(
      replay.frame.map(\.value) == Array(1...4),
      "the final (fitting) run should have completed normally")

    let capExceededRows = try await analytics.fetchCapExceededForTesting()
    #expect(capExceededRows.count == 1)
    #expect(capExceededRows.first?.algorithmID == "fake")
    #expect(capExceededRows.first?.arraySize == 60)
    #expect(capExceededRows.first?.operationCap == settings.recordingOperationCap)
  }
}
