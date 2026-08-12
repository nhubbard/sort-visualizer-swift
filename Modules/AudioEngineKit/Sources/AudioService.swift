import Foundation
import Observation
import SettingsKit
import SortAudioCore
import ToneKitAVFoundation
import ToneKitDSP
#if targetEnvironment(macCatalyst)
import SortAudioBridgeKit
#endif

/// A UI-facing summary of the companion-mode bridge's state — deliberately more granular than a
/// single bool, since "never started" (no sort has played yet), "bound but nothing's connected
/// yet," and "failed to bind at all" (e.g. an App Group/entitlement problem) are different
/// situations someone debugging "why isn't Logic Pro receiving audio" needs to tell apart.
public enum BridgeConnectionStatus: Sendable, Equatable {
  /// `AudioService.start()` hasn't run yet — nothing has played a tone since the app launched.
  case notStarted
  /// Mac Catalyst only, and only reachable if `start()` has run there — this platform never has a
  /// bridge (`AUv3Extension` and `SortAudioBridgeKit` are Mac Catalyst only, permanently).
  case unsupportedPlatform
  /// The App Group entitlement isn't resolvable (`SortAudioBridgePath.socketPath()` returned
  /// `nil`) or the socket failed to bind — check `Console.app`/`log show` for
  /// `SortAudioBridgeServer`'s own logged reason.
  case unavailable
  /// Bound and listening; no AU instance has connected (yet, or ever, if none is loaded in a DAW).
  case listening
  /// At least one AU instance is connected — `play()` is broadcasting to it instead of playing
  /// locally.
  case connected

  public var displayText: String {
    switch self {
    case .notStarted: "Not Started Yet"
    case .unsupportedPlatform: "Not Available on This Platform"
    case .unavailable: "Unavailable"
    case .listening: "Waiting for Connection"
    case .connected: "Connected"
    }
  }
}

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
@Observable
@MainActor
public final class AudioService: AudioPlaying {
  public static let shared = AudioService()

  private let engine = AudioEngine()
  /// Kept as a property (not just handed off to `sink`/`engine.output` and discarded) so the bridge
  /// handoff below can reach in and silence it directly — see `startBridgeServerIfNeeded()`'s
  /// `onConnectedClientsChanged` handler.
  private let renderer: ToneRenderer
  private let sink: LocalToneEventSink
  private let settings: AppSettings
  private var isStarted = false
  /// Fires when the AU-hosted remote (`AUDIO_UNIT_PLAN.md` §7) sends a sort-transport command —
  /// wired to `bridgeServer.onRemoteControlCommandReceived` on Mac Catalyst. Declared unconditionally
  /// (not `#if targetEnvironment(macCatalyst)`) so app-level wiring code compiles identically on
  /// both platforms; on iPad it's simply never invoked, since no bridge exists there to receive from.
  public var remoteControlHandler: (@Sendable (RemoteControlCommand) -> Void)?
  #if targetEnvironment(macCatalyst)
  private let bridgeServer = SortAudioBridgeServer()
  private var bridgeStarted = false
  public private(set) var bridgeStatus: BridgeConnectionStatus = .notStarted
  #else
  public let bridgeStatus: BridgeConnectionStatus = .unsupportedPlatform
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
    self.renderer = renderer
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
  /// Degrades to `.unavailable` (never a crash) if the App Group entitlement isn't resolvable —
  /// matches the AU extension's own `SortAudioUnit.startBridgeClient()` fallback, so a
  /// signing/provisioning gap on either side just means "bridge inactive." `bridgeStatus`'s
  /// transitions are the thing to check first when the bridge doesn't seem to be working: an app
  /// launch alone never starts it — only the first `play()` call does (see `start()` below) — so
  /// "no sort has played sound yet" is the single most common reason nothing is happening.
  private func startBridgeServerIfNeeded() {
    guard !bridgeStarted else { return }
    bridgeStarted = true

    guard let socketPath = SortAudioBridgePath.socketPath() else {
      bridgeStatus = .unavailable
      return
    }

    bridgeServer.onListenerStateChanged = { [weak self] state in
      Task { @MainActor in
        guard let self else { return }
        switch state {
        case .listening:
          if self.bridgeStatus != .connected { self.bridgeStatus = .listening }
        case .failed, .cancelled:
          self.bridgeStatus = .unavailable
        }
      }
    }
    bridgeServer.onConnectedClientsChanged = { [weak self] connected in
      Task { @MainActor in
        guard let self else { return }
        self.bridgeStatus = connected ? .connected : .listening
        // A note already ringing locally (enqueued before this connection existed) would otherwise
        // keep playing until whatever holdSeconds was already in flight expires on its own — this
        // guarantees an immediate, clean handoff the moment a client connects, instead of a brief
        // (or, if the connection kept flapping, indefinite) overlap between the bridge and the
        // local speakers. Never the reverse: disconnecting doesn't reopen anything locally, `play()`
        // just resumes routing new notes to `sink` on its own.
        if connected { self.renderer.enqueue(.closeGate) }
      }
    }
    bridgeServer.onRemoteControlCommandReceived = { [weak self] command in
      Task { @MainActor in
        self?.remoteControlHandler?(command)
      }
    }

    do {
      try bridgeServer.start(socketPath: socketPath)
    } catch {
      bridgeStatus = .unavailable
    }
  }
  #endif
}
