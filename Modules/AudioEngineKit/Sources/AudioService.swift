import Foundation
import SettingsKit
import SortAudioCore
import ToneKitAVFoundation
import ToneKitDSP

/// `ToneKitAVFoundation`-backed `AudioPlaying`, replacing `Legacy/Shared/Data/Primary/
/// Synthesizer.swift`'s graph (`Oscillator` → `AmplitudeEnvelope` → `Fader` → `AudioEngine`,
/// originally AudioKit-backed) with the same shape minus `Fader` — it was never touched past its
/// default gain of 1, a pure passthrough, so `voice` connects directly to `engine.output` — and
/// minus the parts that no longer apply in v2's tape-based model (§3.1 of ARCHITECTURE_V2.md).
///
/// As of Phase 2 (AUDIO_UNIT_PLAN.md §2), this class does almost nothing itself: the pitch
/// mapping, gate-retrigger, and deferred-gate-close logic that used to live directly in `play()`
/// now lives in `SortAudioCore.LocalToneEventSink`, shared with the future headless AU driver so
/// both hear identical sort-to-tone semantics. `AudioService` is left with exactly the pieces that
/// are genuinely specific to being the *standalone app's* voice: owning the `AVAudioEngine`
/// lifecycle (`start`/`stop`) and reading `AppSettings.synthNoteRange` live per call.
@MainActor
public final class AudioService: AudioPlaying {
  public static let shared = AudioService()

  private let engine = AudioEngine()
  private let sink: LocalToneEventSink
  private let settings: AppSettings
  private var isStarted = false

  public init(settings: AppSettings = .shared) {
    self.settings = settings
    let renderer = ToneRenderer(
      oscillator: OscillatorDSP(
        frequency: 440.0, amplitude: 1.0, detuningOffset: 0.0, detuningMultiplier: 1.0
      ),
      envelope: EnvelopeDSP(
        attackDuration: 0.1, decayDuration: 0.1, sustainLevel: 1.0, releaseDuration: 0.1
      )
    )
    self.sink = LocalToneEventSink(renderer: renderer)
    engine.output = ToneVoice(renderer: renderer)
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

  /// Self-starts on first call so callers don't need to call `start()` explicitly. Returns
  /// immediately regardless of hold duration — `sink.send` only enqueues commands and (re)arms a
  /// deferred close, it never blocks — so `ReplayEngine`'s playback loop is never slowed down by
  /// audio.
  public func play(value: Int, in range: ClosedRange<Int>, holdSeconds: Double) {
    if !isStarted { try? start() }
    guard isStarted else { return }

    sink.send(
      SortToneEvent(value: value, range: range, holdSeconds: holdSeconds),
      noteRange: settings.synthNoteRange)
  }
}
