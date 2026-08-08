import AlgorithmKit
import Foundation
import Observation
import VisualizationKit

/// §3.3, in full as of Phase 9. No `warnBeforeBogoSort`/`warnBeforeBitonicSort` (the
/// confirmation-dialog system they'd gate was removed in Phase 8, see §9 of ARCHITECTURE_V2.md —
/// `AlgorithmMetadata.sizeRange` already does that job unconditionally). `defaultShuffleID`
/// replaces what would have been a `shuffleMethod` enum — shuffles are data-driven via
/// `ShuffleRegistry` (Phase 6), so this is an ID lookup, not a fixed case set.
@Observable
@MainActor
public final class AppSettings {
  public static let shared = AppSettings()

  public var selectedVisualizerID: VisualizerID {
    didSet { store.set(selectedVisualizerID.rawValue, forKey: Keys.selectedVisualizerID) }
  }

  public var playbackSpeed: Double {
    didSet { store.set(playbackSpeed, forKey: Keys.playbackSpeed) }
  }

  /// Mode switch: `false` (default) keeps `playbackSpeed`'s flat ops/sec behavior exactly as
  /// today. `true` switches every new replay (manual, automation, or Showcase — `SortSession
  /// .startReplay` reads this unconditionally) to pace against `targetPlaybackDuration` instead,
  /// so a run's animated length stays roughly constant regardless of how large its tape is.
  public var useFixedDurationPacing: Bool {
    didSet { store.set(useFixedDurationPacing, forKey: Keys.useFixedDurationPacing) }
  }

  /// Only consulted when `useFixedDurationPacing` is `true`.
  public var targetPlaybackDuration: Double {
    didSet { store.set(targetPlaybackDuration, forKey: Keys.targetPlaybackDuration) }
  }

  /// Optional refinement on top of `useFixedDurationPacing`: drops purely-cosmetic
  /// mark/unmark bookkeeping from the replay-only tape copy so the target duration is easier to
  /// hit cleanly. Never affects `TapeHeader`'s recorded operation-count stats — see
  /// `Tape.compactedForFastPlayback()`.
  public var compactPlaybackForFixedDuration: Bool {
    didSet { store.set(compactPlaybackForFixedDuration, forKey: Keys.compactPlaybackForFixedDuration) }
  }

  public var soundEnabled: Bool {
    didSet { store.set(soundEnabled, forKey: Keys.soundEnabled) }
  }

  /// MIDI note numbers (matching `Legacy/Shared/Data/Primary/SortViewModel.swift`'s
  /// `synthLowNote`/`synthHighNote`), not Hz — `AudioEngineKit`'s `AudioService` converts to
  /// frequency at play time, so this stays a plain, portable `ClosedRange<Int>` here.
  public var synthNoteRange: ClosedRange<Int> {
    didSet { persistNoteRange() }
  }

  public var defaultArraySize: Int {
    didSet { store.set(defaultArraySize, forKey: Keys.defaultArraySize) }
  }

  /// The `RecordingEngine.operationCap` every new recording is built with (`SortSession.start
  /// (size:)` reads this live, right before spawning the detached recording task) — "how many
  /// operations is too many" is a judgment call about acceptable RAM/playback-time, not a fixed
  /// fact, so it's a real setting rather than `RecordingEngine.defaultOperationCap` alone.
  public var recordingOperationCap: Int {
    didSet { store.set(recordingOperationCap, forKey: Keys.recordingOperationCap) }
  }

  public var codeTheme: CodeThemeID {
    didSet { store.set(codeTheme.rawValue, forKey: Keys.codeTheme) }
  }

  public var defaultShuffleID: ShuffleID {
    didSet { store.set(defaultShuffleID.rawValue, forKey: Keys.defaultShuffleID) }
  }

  private enum Keys {
    static let selectedVisualizerID = "selectedVisualizerID"
    static let playbackSpeed = "playbackSpeed"
    static let useFixedDurationPacing = "useFixedDurationPacing"
    static let targetPlaybackDuration = "targetPlaybackDuration"
    static let compactPlaybackForFixedDuration = "compactPlaybackForFixedDuration"
    static let soundEnabled = "soundEnabled"
    static let synthLowNote = "synthLowNote"
    static let synthHighNote = "synthHighNote"
    static let defaultArraySize = "defaultArraySize"
    static let recordingOperationCap = "recordingOperationCap"
    static let codeTheme = "codeTheme"
    static let defaultShuffleID = "defaultShuffleID"
  }

  private let store: UserDefaults

  public init(store: UserDefaults = .standard) {
    self.store = store
    store.register(defaults: [
      Keys.selectedVisualizerID: "bargraph",
      Keys.playbackSpeed: 30.0,
      Keys.useFixedDurationPacing: false,
      Keys.targetPlaybackDuration: 10.0,
      Keys.compactPlaybackForFixedDuration: false,
      // Off by default — real audio now plays through ScrollingSortView (ToneKit-backed
      // AudioService.shared, see Modules/ToneKit/NOTICE.md), and a brand-new user shouldn't
      // have sound start playing on their very first sort without having chosen it.
      Keys.soundEnabled: false,
      Keys.synthLowNote: 36,
      Keys.synthHighNote: 72,
      Keys.defaultArraySize: 256,
      // 5 minutes at the speed slider's own 1000 ops/sec max (see RecordingEngine
      // .defaultOperationCap, which this mirrors but can't reference directly — SettingsKit
      // doesn't depend on SortEngineKit).
      Keys.recordingOperationCap: 300_000,
      Keys.codeTheme: "monokai",
      Keys.defaultShuffleID: "random"
    ])
    selectedVisualizerID = VisualizerID(
      rawValue: store.string(forKey: Keys.selectedVisualizerID) ?? "bargraph")
    playbackSpeed = store.double(forKey: Keys.playbackSpeed)
    useFixedDurationPacing = store.bool(forKey: Keys.useFixedDurationPacing)
    targetPlaybackDuration = store.double(forKey: Keys.targetPlaybackDuration)
    compactPlaybackForFixedDuration = store.bool(forKey: Keys.compactPlaybackForFixedDuration)
    soundEnabled = store.bool(forKey: Keys.soundEnabled)
    synthNoteRange =
      store.integer(forKey: Keys.synthLowNote)...store.integer(forKey: Keys.synthHighNote)
    defaultArraySize = store.integer(forKey: Keys.defaultArraySize)
    recordingOperationCap = store.integer(forKey: Keys.recordingOperationCap)
    codeTheme = CodeThemeID(rawValue: store.string(forKey: Keys.codeTheme) ?? "monokai")
    defaultShuffleID = ShuffleID(rawValue: store.string(forKey: Keys.defaultShuffleID) ?? "random")
  }

  private func persistNoteRange() {
    store.set(synthNoteRange.lowerBound, forKey: Keys.synthLowNote)
    store.set(synthNoteRange.upperBound, forKey: Keys.synthHighNote)
  }

  /// Mirrors `init`'s `store.register(defaults:)` literals exactly — keep the two in sync if a
  /// default value ever changes. Each property's own `didSet` already persists it, so nothing
  /// else is needed here.
  public func resetToDefaults() {
    selectedVisualizerID = VisualizerID(rawValue: "bargraph")
    playbackSpeed = 30.0
    useFixedDurationPacing = false
    targetPlaybackDuration = 10.0
    compactPlaybackForFixedDuration = false
    soundEnabled = false
    synthNoteRange = 36...72
    defaultArraySize = 256
    recordingOperationCap = 300_000
    codeTheme = CodeThemeID(rawValue: "monokai")
    defaultShuffleID = ShuffleID(rawValue: "random")
  }

  /// Advances `selectedVisualizerID` to the next entry in `VisualizerRegistry.shared.visualizers`
  /// (that registry's own stable, app-composition-root-defined order), wrapping back to the
  /// first after the last — a ring buffer, not a forward-only walk that stops at the end. If the
  /// current ID isn't found there at all (registry not yet populated, or a stale/removed ID),
  /// this lands on the first entry rather than doing nothing, same as it would for any other
  /// "index not found" case feeding into the same wraparound arithmetic.
  public func cycleVisualizer() {
    let visualizers = VisualizerRegistry.shared.visualizers
    guard !visualizers.isEmpty else { return }
    let currentIndex = visualizers.firstIndex { $0.id == selectedVisualizerID } ?? -1
    let nextIndex = (currentIndex + 1) % visualizers.count
    selectedVisualizerID = visualizers[nextIndex].id
  }
}
