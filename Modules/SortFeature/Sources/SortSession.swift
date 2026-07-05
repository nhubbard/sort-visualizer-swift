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
    public private(set) var gate: SortGate = .clear

    public let algorithm: any SortAlgorithm
    public let shuffle: any ShuffleAlgorithm
    private let audio: any AudioPlaying
    private let analytics: AnalyticsService
    private let settings: AppSettings

    /// Stashed when a confirmation gate blocks `start(size:)`, so `acceptWarning()` can resume
    /// recording with the same size once the user says yes.
    private var pendingSize: Int?

    public init(
        algorithm: any SortAlgorithm,
        shuffle: any ShuffleAlgorithm,
        audio: any AudioPlaying = NoOpAudioService(),
        analytics: AnalyticsService = AnalyticsService(),
        settings: AppSettings = .shared
    ) {
        self.algorithm = algorithm
        self.shuffle = shuffle
        self.audio = audio
        self.analytics = analytics
        self.settings = settings
    }

    public func start(size: Int) async {
        if let warning = algorithm.metadata.confirmationWarning, gate != .accepted {
            pendingSize = size
            gate = .needsConfirmation(warning)
            return
        }
        await performRecording(size: size)
    }

    /// Called after the user accepts a `.needsConfirmation` dialog — resumes recording with the
    /// size `start(size:)` stashed when it was blocked.
    public func acceptWarning() async {
        gate = .accepted
        guard let size = pendingSize else { return }
        pendingSize = nil
        await performRecording(size: size)
    }

    public func declineWarning() {
        gate = .declined
        phase = .idle
        pendingSize = nil
    }

    private func performRecording(size: Int) async {
        phase = .recording

        let algorithm = self.algorithm
        let shuffle = self.shuffle
        let tape = await Task.detached(priority: .userInitiated) {
            SortSession.makeTape(algorithm: algorithm, shuffle: shuffle, size: size)
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
        let playbackTask = replay.play(operationsPerSecond: settings.playbackSpeed)
        Task {
            await playbackTask.value
            phase = .complete(replay)
            try? await analytics.record(tape.header, algorithmID: algorithm.id)
        }
    }
}
