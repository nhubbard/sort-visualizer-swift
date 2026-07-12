import Foundation
import os
import SettingsKit
import ToneKit

/// Labels the two spots that were, historically, the actual bottleneck behind "recording is fast
/// but playback is slow" symptoms (see `ReplayEngine`'s own signposter doc comment) — a per-note
/// `play()` call taking longer than expected, or the gate-closer task waking up far more often
/// than "once per held note" would predict (a regression back toward the fixed per-note `Task`
/// churn `scheduleGateClose`'s own doc comment describes as already-fixed).
private let audioSignposter = OSSignposter(subsystem: "com.nhubbard.Sort2.AudioEngineKit", category: "AudioService")

/// `ToneKit`-backed `AudioPlaying`, replacing `Legacy/Shared/Data/Primary/Synthesizer.swift`'s
/// graph (`Oscillator` → `AmplitudeEnvelope` → `Fader` → `AudioEngine`, originally AudioKit-backed)
/// with the same shape minus `Fader` — it was never touched past its default gain of 1, a pure
/// passthrough, so `env` connects directly to `engine.output` — and minus the parts that no
/// longer apply in v2's tape-based model (§3.1 of ARCHITECTURE_V2.md).
@MainActor
public final class AudioService: AudioPlaying {
    public static let shared = AudioService()

    private let engine = AudioEngine()
    private let osc: Oscillator
    private let env: AmplitudeEnvelope
    private let settings: AppSettings
    private var isStarted = false
    private var currentFrequency: Float = 0

    public init(settings: AppSettings = .shared) {
        self.settings = settings
        let osc = Oscillator(
            frequency: 440.0, amplitude: 1.0, detuningOffset: 0.0, detuningMultiplier: 1.0
        )
        let env = AmplitudeEnvelope(
            osc, attackDuration: 0.1, decayDuration: 0.1, sustainLevel: 1.0, releaseDuration: 0.1
        )
        self.osc = osc
        self.env = env
        engine.output = env
    }

    public func start() throws {
        guard !isStarted else { return }
        try engine.start()
        isStarted = true
    }

    public func stop() {
        guard isStarted else { return }
        engine.stop()
        isStarted = false
    }

    /// Deadline the currently-open gate should close at — updated on every `play()` call.
    /// `gateCloserTask`, once running, re-reads this after every wake rather than being torn down
    /// and recreated per note (see `play()`'s doc comment: that per-note `Task` churn was the
    /// actual throughput ceiling on replay, not the `speed`/render-rate math).
    private var nextGateCloseDeadline: ContinuousClock.Instant?
    private var gateCloserTask: Task<Void, Never>?

    /// Self-starts on first call so composition-root code doesn't need to remember to call
    /// `start()` — a caller that never plays a note never pays for a running engine.
    ///
    /// Retriggers the envelope on a pitch change (matching `Synthesizer.swift`'s behavior), then
    /// pushes the gate's close deadline out via `scheduleGateClose`, not a blocking `Task.sleep` in
    /// this call — v1's blocking version is exactly the bug §3.1 calls out ("a fast algorithm...
    /// can outrun AudioKit's note-scheduling and glitch, because note-firing is woven into the
    /// algorithm's own timing"). This method returns immediately regardless of hold duration, so
    /// `ReplayEngine`'s playback loop is never slowed down by audio.
    public func play(value: Int, in range: ClosedRange<Int>, holdSeconds: Double) {
        let interval = audioSignposter.beginInterval("PlayNote", id: audioSignposter.makeSignpostID())
        defer { audioSignposter.endInterval("PlayNote", interval) }

        if !isStarted { try? start() }
        guard isStarted else { return }

        let frequency = Self.frequency(forValue: value, in: range, noteRange: settings.synthNoteRange)
        if frequency != currentFrequency {
            env.closeGate()
        }
        currentFrequency = frequency
        osc.frequency = frequency
        env.openGate()

        scheduleGateClose(after: holdSeconds)
    }

    /// Pushes `nextGateCloseDeadline` out to `holdSeconds` from now, and — only if no closer is
    /// currently running — starts the one `gateCloserTask` that will ever exist for this
    /// `AudioService`. A note arriving mid-hold (the common case at real playback speeds) just
    /// moves the deadline; it never spawns a second `Task`. Without the "already running" guard,
    /// this degenerates back into one `Task` per note — exactly the per-op Swift Concurrency
    /// scheduling churn that capped replay throughput far below its theoretical ops/sec.
    private func scheduleGateClose(after holdSeconds: Double) {
        let deadline = ContinuousClock.now.advanced(by: .seconds(holdSeconds))
        nextGateCloseDeadline = deadline
        guard gateCloserTask == nil else { return }

        gateCloserTask = Task { [weak self] in
            while let self {
                guard let deadline = self.nextGateCloseDeadline else { break }
                let wait = audioSignposter.beginInterval("GateCloseWait", id: audioSignposter.makeSignpostID())
                try? await Task.sleep(until: deadline, clock: .continuous)
                audioSignposter.endInterval("GateCloseWait", wait)
                // A newer note pushed the deadline out while we were asleep — sleep again instead
                // of closing the gate early.
                if let latest = self.nextGateCloseDeadline, latest > deadline { continue }
                self.env.closeGate()
                self.nextGateCloseDeadline = nil
                break
            }
            self?.gateCloserTask = nil
        }
    }

    /// Pure value→pitch mapping, pulled out of the AudioKit side effects above so it's testable
    /// without a running engine (`nonisolated` since it touches no actor state at all — otherwise
    /// it'd inherit `AudioService`'s `@MainActor` isolation for no reason). Linearly maps
    /// `value`'s position in `range` onto `noteRange` (MIDI note numbers), then converts to Hz via
    /// the standard equal-tempered formula.
    nonisolated static func frequency(
        forValue value: Int, in range: ClosedRange<Int>, noteRange: ClosedRange<Int>
    ) -> Float {
        let span = range.upperBound - range.lowerBound
        let ratio: Float = span > 0 ? Float(value - range.lowerBound) / Float(span) : 0.5
        let note = Float(noteRange.lowerBound) + ratio * Float(noteRange.upperBound - noteRange.lowerBound)
        return 440.0 * pow(2.0, (note - 69.0) / 12.0)
    }
}
