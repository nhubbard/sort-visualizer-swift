import AudioKit
import AudioKitEX
import Foundation
import SettingsKit
import SoundpipeAudioKit

/// AudioKit-backed `AudioPlaying`, replacing `Legacy/Shared/Data/Primary/Synthesizer.swift`'s
/// graph (`Oscillator` → `AmplitudeEnvelope` → `Fader` → `AudioEngine`) with the same shape, minus
/// the parts that no longer apply in v2's tape-based model (§3.1 of ARCHITECTURE_V2.md).
@MainActor
public final class AudioService: AudioPlaying {
    public static let shared = AudioService()

    private let engine = AudioEngine()
    private let osc: Oscillator
    private let env: AmplitudeEnvelope
    private let fader: Fader
    private let settings: AppSettings
    private var isStarted = false
    private var currentFrequency: Float = 0

    public init(settings: AppSettings = .shared) {
        self.settings = settings
        // Every AUValue parameter is passed explicitly here, matching each type's own documented
        // default — NOT relying on Oscillator/AmplitudeEnvelope's own default argument values
        // (e.g. `frequency: AUValue = frequencyDef.defaultValue`). Those defaults are evaluated by
        // the *caller*, before the callee's own `avAudioNode` property initializer has run, which
        // is what actually registers the underlying Audio Unit's parameters — so touching
        // `frequencyDef` (or any of its siblings) before that registration crashes at AudioKitEX's
        // native layer ("akGetParameterAddress: parameter map not initialized"). Passing explicit
        // values sidesteps evaluating those defaults at the call site entirely.
        let osc = Oscillator(frequency: 440.0, amplitude: 1.0, detuningOffset: 0.0, detuningMultiplier: 1.0)
        let env = AmplitudeEnvelope(osc, attackDuration: 0.1, decayDuration: 0.1, sustainLevel: 1.0, releaseDuration: 0.1)
        let fader = Fader(env)
        self.osc = osc
        self.env = env
        self.fader = fader
        engine.output = fader
    }

    public func start() throws {
        guard !isStarted else { return }
        osc.start()
        try engine.start()
        isStarted = true
    }

    public func stop() {
        guard isStarted else { return }
        osc.stop()
        engine.stop()
        isStarted = false
    }

    /// Self-starts on first call so composition-root code doesn't need to remember to call
    /// `start()` — a caller that never plays a note never pays for a running engine.
    ///
    /// Retriggers the envelope on a pitch change (matching `Synthesizer.swift`'s behavior), then
    /// schedules the gate's close via a **fire-and-forget** `Task`, not a blocking `Task.sleep` in
    /// this call — v1's blocking version is exactly the bug §3.1 calls out ("a fast algorithm...
    /// can outrun AudioKit's note-scheduling and glitch, because note-firing is woven into the
    /// algorithm's own timing"). This method returns immediately regardless of hold duration, so
    /// `ReplayEngine`'s playback loop is never slowed down by audio.
    public func play(value: Int, in range: ClosedRange<Int>) {
        if !isStarted { try? start() }
        guard isStarted else { return }

        let frequency = Self.frequency(forValue: value, in: range, noteRange: settings.synthNoteRange)
        if frequency != currentFrequency {
            env.closeGate()
        }
        currentFrequency = frequency
        osc.frequency = frequency
        env.openGate()

        let holdSeconds = max(1.0 / settings.playbackSpeed, 0.03)
        let env = self.env
        Task {
            try? await Task.sleep(for: .seconds(holdSeconds))
            env.closeGate()
        }
    }

    /// Pure value→pitch mapping, pulled out of the AudioKit side effects above so it's testable
    /// without a running engine (`nonisolated` since it touches no actor state at all — otherwise
    /// it'd inherit `AudioService`'s `@MainActor` isolation for no reason). Linearly maps
    /// `value`'s position in `range` onto `noteRange` (MIDI note numbers), then converts to Hz via
    /// the standard equal-tempered formula.
    nonisolated static func frequency(forValue value: Int, in range: ClosedRange<Int>, noteRange: ClosedRange<Int>) -> Float {
        let span = range.upperBound - range.lowerBound
        let ratio: Float = span > 0 ? Float(value - range.lowerBound) / Float(span) : 0.5
        let note = Float(noteRange.lowerBound) + ratio * Float(noteRange.upperBound - noteRange.lowerBound)
        return 440.0 * pow(2.0, (note - 69.0) / 12.0)
    }
}
