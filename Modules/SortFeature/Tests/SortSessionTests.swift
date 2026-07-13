import AlgorithmKit
import Foundation
import PersistenceKit
import SettingsKit
import SwiftData
import Testing
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
    var sizeRange: ClosedRange<Int> = 1...512
    var metadata: AlgorithmMetadata {
        AlgorithmMetadata(
            displayName: "Fake",
            category: .exchange,
            sizeRange: sizeRange,
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
    let schema = Schema([BigORecord.self])
    let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try ModelContainer(for: schema, configurations: [configuration])
    return AnalyticsService(modelContainer: container)
}

@MainActor
@Suite
struct SortSessionTests {
    @Test
    func sortEndToEndProducesCorrectlySortedFrame() async throws {
        let session = SortSession(
            algorithm: FakeAlgorithm(),
            shuffle: FakeReverseShuffle(),
            settings: makeFastSettings())
        let size = 9

        await session.start(size: size)
        try await waitUntilTerminal(session)

        guard case let .complete(replay) = session.phase else {
            Issue.record("expected .complete, got \(session.phase)")
            return
        }
        #expect(replay.frame.map(\.value) == Array(1...size))
    }

    /// Regression test for the reported bug: `FakeAlgorithm` (a bubble-sort shape) always ends on
    /// a bare `.compare` that returns `false` — no trailing `.swap` ever comes along to retract the
    /// primary/secondary pair that final `.compare` marked, since `RecordingEngine`'s auto-
    /// retraction (`markPrimarySecondary`) only clears the *previous* pair right before marking a
    /// new one. Without `SortSession.makeTape`'s trailing `unmarkAll()`, the completed, fully-
    /// sorted frame would show one index still highlighted red and another still blue, forever.
    @Test
    func completedFrameHasNoLingeringPrimaryOrSecondaryMarkers() async throws {
        let session = SortSession(
            algorithm: FakeAlgorithm(),
            shuffle: FakeReverseShuffle(),
            settings: makeFastSettings())

        await session.start(size: 9)
        try await waitUntilTerminal(session)

        guard case let .complete(replay) = session.phase else {
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

        guard case let .complete(replay) = session.phase else {
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
            settings.playbackSpeed = 20.0 // slow enough that playback is still mid-flight below
            let session = SortSession(algorithm: FakeAlgorithm(), shuffle: FakeReverseShuffle(), settings: settings)
            weakSession = session

            await session.start(size: 12)
            guard case let .replaying(replay) = session.phase else {
                Issue.record("expected .replaying immediately after start, got \(session.phase)")
                return
            }
            weakReplay = replay

            try await Task.sleep(for: .milliseconds(50)) // genuinely mid-flight, not yet complete
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

    /// Regression test for the pause/resume redesign: pausing mid-replay must not prematurely
    /// flip `phase` to `.complete` (the old one-shot "await the first playbackTask" design would
    /// have, since a cancelled task's `.value` still resolves), and resuming must continue from
    /// where it left off rather than restarting or getting stuck.
    ///
    /// Drives a `ManualTickDriver` directly instead of sleeping and hoping enough real
    /// `CADisplayLink` ticks land in the window — this test used to sleep 50ms at `speed: 20`
    /// (1 op/50ms) and assert `stepIndexAtPause > 0`, which depended on a real display link
    /// ticking at least once in that window. In this module's host-less `.unitTests` bundle a real
    /// `CADisplayLink` has no guaranteed tick latency, so that assertion failed outright rather
    /// than flaking occasionally — the fix is determinism, not a longer sleep.
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
        guard case let .replaying(replay) = session.phase else {
            Issue.record("expected .replaying immediately after start, got \(session.phase)")
            return
        }
        // `ReplayEngine.opsToApply` clamps a tick's elapsed time to `maxCatchUpInterval` (0.25s)
        // before multiplying by speed, so `speed` must be high enough that even the clamped
        // elapsed still yields a whole, nonzero op count — a slow speed here would silently
        // round down to 0 regardless of how large `elapsed` is.
        replay.speed = 20.0

        driver.fireTick(elapsed: 0) // the very first tick always carries zero elapsed time
        driver.fireTick(elapsed: 1.0) // clamped to 0.25s * 20 ops/sec = 5 ops due — partway through
        try await Task.sleep(for: .milliseconds(20)) // let play()'s Task actually process the tick
        #expect(replay.isPlaying)

        session.togglePlayback() // pause
        #expect(!replay.isPlaying)
        let stepIndexAtPause = replay.stepIndex
        #expect(stepIndexAtPause > 0)
        #expect(stepIndexAtPause < replay.totalOperationCount)

        driver.fireTick(elapsed: 1.0) // fired while paused — pause() already stopped the driver
        try await Task.sleep(for: .milliseconds(20))
        #expect(replay.stepIndex == stepIndexAtPause) // nothing advances while paused

        replay.speed = 100_000.0 // finish quickly once resumed
        session.togglePlayback() // resume — starts a fresh play() Task against the same driver
        driver.fireTick(elapsed: 0) // the very first tick of this new play() also carries zero elapsed time
        driver.fireTick(elapsed: 1.0) // hugely overdue at the new speed — the rest of the tape in one tick
        try await waitUntilTerminal(session)

        guard case let .complete(finished) = session.phase else {
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

        guard case let .complete(replay) = session.phase else {
            Issue.record("expected .complete, got \(session.phase)")
            return
        }

        replay.seek(to: replay.header.sortStartIndex) // what the Reset button does
        #expect(replay.stepIndex < replay.totalOperationCount)

        session.togglePlayback()
        guard case .replaying = session.phase else {
            Issue.record("expected .replaying after resuming from a scrubbed-back .complete, got \(session.phase)")
            return
        }
        #expect(replay.isPlaying)

        try await waitUntilTerminal(session)
        guard case let .complete(finished) = session.phase else {
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
        let session = SortSession(algorithm: FakeAlgorithm(), shuffle: FakeReverseShuffle(), settings: settings)

        #expect(session.soundEnabled) // seeded from the global default at construction
        session.soundEnabled = false

        #expect(settings.soundEnabled) // toggling the session-local flag never touches the global default
    }

    // MARK: - Phase 6: shuffle+sort concatenation

    @Test
    func concatenatedTapeOperationCountEqualsShuffleLengthPlusSortLength() {
        let size = 20
        let algorithm = FakeAlgorithm()
        let shuffle = FakeReverseShuffle()

        var shuffleEngine = RecordingEngine(values: Array(1...size))
        shuffle.record(into: &shuffleEngine)
        shuffleEngine.unmarkAll() // mirrors makeTape's own trailing cleanup call
        let shuffleOperationCount = shuffleEngine.finish().tape.count

        var sortEngine = RecordingEngine(values: shuffleEngine.values)
        algorithm.record(into: &sortEngine)
        sortEngine.unmarkAll() // mirrors makeTape's own trailing cleanup call
        let sortOperationCount = sortEngine.finish().tape.count

        let tape = SortSession.makeTape(algorithm: algorithm, shuffle: shuffle, size: size)

        #expect(tape.operations.count == shuffleOperationCount + sortOperationCount)
        #expect(tape.header.sortStartIndex == shuffleOperationCount)
        #expect(tape.header.shuffleID == shuffle.id.rawValue)
        #expect(tape.header.initialValues == Array(1...size))
    }

    @Test(arguments: [
        FakeIdentityShuffle() as any ShuffleAlgorithm,
        FakeReverseShuffle() as any ShuffleAlgorithm,
        FakeRotateShuffle() as any ShuffleAlgorithm
    ])
    func replayingConcatenatedTapeProducesSortedFrameRegardlessOfShuffle(shuffle: any ShuffleAlgorithm) {
        let size = 15
        let tape = SortSession.makeTape(algorithm: FakeAlgorithm(), shuffle: shuffle, size: size)

        let replay = ReplayEngine(tape: tape)
        for _ in 0..<tape.operations.count { replay.stepForward() }

        #expect(replay.frame.map(\.value) == Array(1...size))
    }
}
