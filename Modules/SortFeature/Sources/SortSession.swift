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

    public let algorithm: any SortAlgorithm
    public let shuffle: any ShuffleAlgorithm
    private let audio: any AudioPlaying
    private let analytics: AnalyticsService
    private let settings: AppSettings

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
        let (shuffleOperations, _, _, _) = shuffleEngine.finish()

        // recordingDuration measures only the sort, not the shuffle — it's the real algorithmic
        // performance number (§1.1), and a shuffle's cost isn't the algorithm's to answer for.
        let recordingStart = Date()
        var sortEngine = RecordingEngine(values: shuffleEngine.values)
        algorithm.record(into: &sortEngine)
        let recordingDuration = Date().timeIntervalSince(recordingStart)
        let (sortOperations, compareCount, swapCount, _) = sortEngine.finish()

        return Tape(
            header: TapeHeader(
                algorithmID: algorithm.id.rawValue,
                initialValues: identity,
                visualSeed: UInt64.random(in: .min ... .max),
                compareCount: compareCount,
                swapCount: swapCount,
                recordingDuration: recordingDuration,
                recordedAt: Date(),
                shuffleID: shuffle.id.rawValue,
                sortStartIndex: shuffleOperations.count
            ),
            operations: shuffleOperations + sortOperations
        )
    }

    private func startReplay(_ tape: Tape) {
        let replay = ReplayEngine(tape: tape)
        phase = .replaying(replay)
        let audio = self.audio
        let settings = self.settings
        let playbackTask = replay.play(operationsPerSecond: settings.playbackSpeed) { [weak replay] operation in
            guard settings.soundEnabled, let replay else { return }
            SortSession.playAudio(for: operation, frame: replay.frame, audio: audio)
        }
        Task {
            await playbackTask.value
            phase = .complete(replay)
            try? await analytics.record(tape.header, algorithmID: algorithm.id)
        }
    }

    /// One note per touched index, keyed on that index's **current** value (post-operation) —
    /// matches v1's "play a note per touched index" behavior (`compare`/`swap` both play both
    /// indices; `setValue` plays the one it touched), but pitch tracks value, not index (§3.1).
    private static func playAudio(for operation: SortOperation, frame: [ReplayEngine.BarState], audio: any AudioPlaying) {
        let range = 1...frame.count
        switch operation {
        case let .compare(i, j), let .swap(i, j):
            audio.play(value: frame[i].value, in: range)
            audio.play(value: frame[j].value, in: range)
        case let .setValue(i, _):
            audio.play(value: frame[i].value, in: range)
        default:
            break
        }
    }
}
