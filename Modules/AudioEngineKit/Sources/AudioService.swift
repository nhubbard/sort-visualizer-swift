import Foundation
import SettingsKit
import SortAudioCore
import ToneKitAVFoundation
import ToneKitDSP
#if targetEnvironment(macCatalyst)
import SortAudioBridgeKit
#endif

/// `ToneKitAVFoundation`-backed `AudioPlaying`, replacing `Legacy/Shared/Data/Primary/
/// Synthesizer.swift`'s graph (`Oscillator` → `AmplitudeEnvelope` → `Fader` → `AudioEngine`,
/// originally AudioKit-backed) with the same shape minus `Fader` — it was never touched past its
/// default gain of 1, a pure passthrough, so `voice` connects directly to `engine.output` — and
/// minus the parts that no longer apply in v2's tape-based model (§3.1 of ARCHITECTURE_V2.md).
///
/// As of Phase 2 (AUDIO_UNIT_PLAN.md §2), the pitch mapping, gate-retrigger, and deferred-gate-
/// close logic that used to live directly in `play()` lives in `SortAudioCore.LocalToneEventSink`
/// instead, shared with the AU extension's own relay so both hear identical sort-to-tone
/// semantics. `AudioService` is left with the pieces genuinely specific to being the *standalone
/// app's* voice: owning the `AVAudioEngine` lifecycle, reading `AppSettings.synthNoteRange` live
/// per call, and — Mac Catalyst only — routing between local playback and the companion-mode
/// bridge.
///
/// Companion mode (AUDIO_UNIT_PLAN.md's corrected architecture): on Mac Catalyst, this class also
/// owns the bridge's `SortAudioBridgeServer`. Whenever an AU extension instance is connected
/// (loaded on a Logic Pro track, say), `play()` broadcasts to the bridge *instead of* playing
/// locally — never both at once, matching "sends... to the Audio Unit instead of running it
/// through our simple integrated ADSR envelope DSP" exactly. With nothing connected, playback is
/// unchanged from before the bridge existed. iPad builds never link `SortAudioBridgeKit` at all
/// (`.when([.catalyst])` in Project.swift) — the bridge simply doesn't exist there, by permanent
/// design (see AUDIO_UNIT_PLAN.md's platform-scope rationale).
@MainActor
public final class AudioService: AudioPlaying {
  public static let shared = AudioService()

  private let engine = AudioEngine()
  private let sink: LocalToneEventSink
  private let settings: AppSettings
  private var isStarted = false
  #if targetEnvironment(macCatalyst)
  private let bridgeServer = SortAudioBridgeServer()
  private var bridgeStarted = false
  #endif

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
    #if targetEnvironment(macCatalyst)
    startBridgeServerIfNeeded()
    #endif
  }

  public func stop() {
    guard isStarted else { return }
    engine.stop()
    isStarted = false
  }

  /// Self-starts on first call so callers don't need to call `start()` explicitly. Returns
  /// immediately regardless of hold duration — enqueuing (whether locally or onto the bridge) never
  /// blocks — so `ReplayEngine`'s playback loop is never slowed down by audio.
  public func play(value: Int, in range: ClosedRange<Int>, holdSeconds: Double) {
    if !isStarted { try? start() }
    guard isStarted else { return }

    let event = SortToneEvent(value: value, range: range, holdSeconds: holdSeconds)
    let noteRange = settings.synthNoteRange

    #if targetEnvironment(macCatalyst)
    if bridgeServer.hasConnectedClients {
      bridgeServer.broadcast(event, noteRange: noteRange)
      return
    }
    #endif

    sink.send(event, noteRange: noteRange)
  }

  #if targetEnvironment(macCatalyst)
  /// No-op if the App Group entitlement isn't resolvable — matches the AU extension's own
  /// `SortAudioUnit.startBridgeClient()` fallback, so a signing/provisioning gap on either side
  /// degrades to "bridge inactive," never a crash.
  private func startBridgeServerIfNeeded() {
    guard !bridgeStarted, let socketPath = SortAudioBridgePath.socketPath() else { return }
    try? bridgeServer.start(socketPath: socketPath)
    bridgeStarted = true
  }
  #endif
}
