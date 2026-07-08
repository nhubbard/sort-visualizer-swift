import AlgorithmKit
import AudioEngineKit
import Foundation
import PersistenceKit
import SettingsKit
import SortEngineKit

public enum SortSessionError: Error, Equatable, Sendable {
    case recordingFailed(String)
}

/// The orchestrator — the *only* type that owns instances of `RecordingEngine`/`ReplayEngine`,
/// `AudioPlaying`, `AnalyticsService`, and `AppSettings` at once (§3.5). Each algorithm screen
/// constructs its own `SortSession`, matching v1's "each `SortView` gets its own `SortViewModel`"
/// behavior — there is no shared global sort state.
@Observable
@MainActor
public final class SortSession {
    public enum Phase {
        case idle
        case recording
        case ready(Tape)
        case replaying(ReplayEngine)
        case complete(ReplayEngine)
        case failed(SortSessionError)
    }

    public private(set) var phase: Phase = .idle

    /// Local to this session, seeded from `AppSettings.soundEnabled` at construction but never
    /// written back — the global setting is the *default* for new sessions, this is the
    /// currently-running sort's own on/off switch (a run-control-bar toggle, not a Settings toggle).
    public var soundEnabled: Bool

    public let algorithm: any SortAlgorithm
    public let shuffle: any ShuffleAlgorithm
    private let audio: any AudioPlaying
    private let analytics: AnalyticsService
    private let settings: AppSettings
    private var monitorTask: Task<Void, Never>?

    public init(
        algorithm: any SortAlgorithm,
        shuffle: any ShuffleAlgorithm,
        // NOT AudioService.shared: merely constructing AudioService builds a live AudioKit graph
        // (Oscillator/AmplitudeEnvelope's inits call into AudioKit's native parameter-map setup
        // unconditionally), which crashes outside a real running app with an active audio session
        // — see AudioServiceTests.swift's comment. Every test that constructs a SortSession without
        // overriding `audio:` would hit that crash if this defaulted to the real service. The real
        // app's composition root (ScrollingSortView) passes AudioService.shared explicitly instead.
        audio: any AudioPlaying = NoOpAudioService(),
        analytics: AnalyticsService = .shared,
        settings: AppSettings = .shared
    ) {
        self.algorithm = algorithm
        self.shuffle = shuffle
        self.audio = audio
        self.analytics = analytics
        self.settings = settings
        self.soundEnabled = settings.soundEnabled
    }

    /// Unconditionally clamps into `algorithm.metadata.sizeRange` rather than warning past it —
    /// this is ArrayV's own `unreasonableLimit` precedent (a per-sort size threshold, not a
    /// user-toggleable confirmation dialog), enforced here so every caller gets it, not just
    /// whichever view happens to clamp its own slider (§9 of ARCHITECTURE_V2.md).
    public func start(size: Int) async {
        let clampedSize = min(max(size, algorithm.metadata.sizeRange.lowerBound), algorithm.metadata.sizeRange.upperBound)
        phase = .recording

        let algorithm = self.algorithm
        let shuffle = self.shuffle
        let tape = await Task.detached(priority: .userInitiated) {
            SortSession.makeTape(algorithm: algorithm, shuffle: shuffle, size: clampedSize)
        }.value

        phase = .ready(tape)
        startReplay(tape)
    }

    /// Records the shuffle against an identity array, then the sort against the shuffle's output,
    /// concatenating both into one continuous `Tape` — from `ReplayEngine`'s point of view a
    /// shuffle-then-sort is just one longer tape (§2A.4). A free function (well, static method) on
    /// purpose: no `self`, no actor isolation, callable directly from a test or from inside
    /// `Task.detached` without capturing the session itself.
    nonisolated static func makeTape(algorithm: any SortAlgorithm, shuffle: any ShuffleAlgorithm, size: Int) -> Tape {
        let identity = Array(1...size)

        var shuffleEngine = RecordingEngine(values: identity)
        shuffle.record(into: &shuffleEngine)
        let shuffleSummary = shuffleEngine.finish()

        // recordingDuration measures only the sort, not the shuffle — it's the real algorithmic
        // performance number (§1.1), and a shuffle's cost isn't the algorithm's to answer for.
        let recordingStart = Date()
        var sortEngine = RecordingEngine(values: shuffleEngine.values)
        algorithm.record(into: &sortEngine)
        let recordingDuration = Date().timeIntervalSince(recordingStart)
        let sortSummary = sortEngine.finish()

        return Tape(
            header: TapeHeader(
                algorithmID: algorithm.id.rawValue,
                initialValues: identity,
                visualSeed: UInt64.random(in: .min ... .max),
                compareCount: sortSummary.compareCount,
                swapCount: sortSummary.swapCount,
                mainWriteCount: sortSummary.mainWriteCount,
                auxWriteCount: sortSummary.auxWriteCount,
                reversalCount: sortSummary.reversalCount,
                recordingDuration: recordingDuration,
                recordedAt: Date(),
                shuffleID: shuffle.id.rawValue,
                sortStartIndex: shuffleSummary.tape.count
            ),
            operations: shuffleSummary.tape + sortSummary.tape
        )
    }

    private func startReplay(_ tape: Tape) {
        let replay = ReplayEngine(tape: tape)
        replay.speed = settings.playbackSpeed
        phase = .replaying(replay)
        beginPlayback(replay)
    }

    /// Starts (or resumes, after a `pause()`) the timed playback loop, and (re-)arms a monitor
    /// that only transitions `phase` to `.complete` — and records analytics — once the replay has
    /// *genuinely* finished (`stepIndex` reached the end), not merely whenever the current
    /// `playbackTask` stops running. A `pause()` also stops that task (by cancellation), so without
    /// this distinction, pausing would immediately look like completion and both mark the sort done
    /// early and double-record analytics on a later real completion.
    private func beginPlayback(_ replay: ReplayEngine) {
        let playbackTask = replay.play(onStep: makeOnStepClosure(for: replay))
        monitorTask?.cancel()
        // `replay` must be captured weakly, same as `self` — this closure `await`s the *entire*
        // remaining playback, however long that takes, so a strong capture here would keep the
        // whole `ReplayEngine` (its full tape, checkpoints, frame) alive for that entire duration
        // even after `self` (and whatever view owned it) is long gone — e.g. navigating away from
        // a still-playing sort. `SortSession`'s own `deinit` below cancels this promptly instead
        // of waiting on it to resolve on its own.
        monitorTask = Task { [weak self, weak replay] in
            await playbackTask.value
            guard let self, let replay, replay.stepIndex >= replay.totalOperationCount else { return }
            self.phase = .complete(replay)
            try? await self.analytics.record(replay.header, algorithmID: self.algorithm.id, speed: replay.speed)
        }
    }

    /// Toggles between playing and paused. In `.replaying`, this is a normal pause/resume.
    ///
    /// In `.complete`, it resumes only if `stepIndex` is no longer at the very end — the scrub
    /// slider, step-back, and Reset all call `seek(to:)`/`stepBackward()` directly on `replay`,
    /// bypassing `SortSession` entirely, so none of them ever transition `phase` back to
    /// `.replaying` on their own; without this case, scrubbing backward after a sort finishes
    /// would leave the play button looking enabled but silently doing nothing. A `.complete` sort
    /// still sitting at the very end remains a no-op — a stray tap on a play button the UI failed
    /// to disable can't re-trigger analytics recording.
    public func togglePlayback() {
        switch phase {
        case let .replaying(replay):
            if replay.isPlaying {
                replay.pause()
            } else {
                beginPlayback(replay)
            }
        case let .complete(replay) where replay.stepIndex < replay.totalOperationCount:
            phase = .replaying(replay)
            beginPlayback(replay)
        default:
            break
        }
    }

    /// One note per touched index, keyed on that index's **current** value (post-operation) —
    /// matches v1's "play a note per touched index" behavior (`compare`/`swap` both play both
    /// indices; `setValue` plays the one it touched), but pitch tracks value, not index (§3.1).
    /// Reads `soundEnabled`/`replay.speed` live on every call (both are `weak`/reference-captured),
    /// so toggling sound or adjusting speed mid-replay takes effect on the very next operation.
    private func makeOnStepClosure(for replay: ReplayEngine) -> (SortOperation) -> Void {
        let audio = self.audio
        return { [weak self, weak replay] operation in
            guard let self, self.soundEnabled, let replay else { return }
            let holdSeconds = max(1.0 / replay.speed, 0.03)
            let range = 1...replay.frame.count
            switch operation {
            case let .compare(i, j), let .swap(i, j):
                audio.play(value: replay.frame[i].value, in: range, holdSeconds: holdSeconds)
                audio.play(value: replay.frame[j].value, in: range, holdSeconds: holdSeconds)
            case let .setValue(i, _):
                audio.play(value: replay.frame[i].value, in: range, holdSeconds: holdSeconds)
            default:
                break
            }
        }
    }
}
