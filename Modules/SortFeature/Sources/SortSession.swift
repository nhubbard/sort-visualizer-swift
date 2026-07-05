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
    private let audio: any AudioPlaying
    private let analytics: AnalyticsService
    private let settings: AppSettings

    /// Stashed when a confirmation gate blocks `start(values:)`, so `acceptWarning()` can resume
    /// recording with the same array once the user says yes.
    private var pendingValues: [Int]?

    public init(
        algorithm: any SortAlgorithm,
        audio: any AudioPlaying = NoOpAudioService(),
        analytics: AnalyticsService = AnalyticsService(),
        settings: AppSettings = .shared
    ) {
        self.algorithm = algorithm
        self.audio = audio
        self.analytics = analytics
        self.settings = settings
    }

    public func start(values: [Int]) async {
        if let warning = algorithm.metadata.confirmationWarning, gate != .accepted {
            pendingValues = values
            gate = .needsConfirmation(warning)
            return
        }
        await performRecording(values: values)
    }

    /// Called after the user accepts a `.needsConfirmation` dialog — resumes recording with the
    /// array `start(values:)` stashed when it was blocked.
    public func acceptWarning() async {
        gate = .accepted
        guard let values = pendingValues else { return }
        pendingValues = nil
        await performRecording(values: values)
    }

    public func declineWarning() {
        gate = .declined
        phase = .idle
        pendingValues = nil
    }

    private func performRecording(values: [Int]) async {
        phase = .recording

        let algorithm = self.algorithm
        let tape = await Task.detached(priority: .userInitiated) {
            let recordingStart = Date()
            var engine = RecordingEngine(values: values)
            algorithm.record(into: &engine)
            let (operations, compareCount, swapCount, _) = engine.finish()
            return Tape(
                header: TapeHeader(
                    algorithmID: algorithm.id.rawValue,
                    initialValues: values,
                    visualSeed: UInt64.random(in: .min ... .max),
                    compareCount: compareCount,
                    swapCount: swapCount,
                    recordingDuration: Date().timeIntervalSince(recordingStart),
                    recordedAt: Date()
                ),
                operations: operations
            )
        }.value

        phase = .ready(tape)
        startReplay(tape)
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
