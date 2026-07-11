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

    public var codeTheme: CodeThemeID {
        didSet { store.set(codeTheme.rawValue, forKey: Keys.codeTheme) }
    }

    public var defaultShuffleID: ShuffleID {
        didSet { store.set(defaultShuffleID.rawValue, forKey: Keys.defaultShuffleID) }
    }

    private enum Keys {
        static let selectedVisualizerID = "selectedVisualizerID"
        static let playbackSpeed = "playbackSpeed"
        static let soundEnabled = "soundEnabled"
        static let synthLowNote = "synthLowNote"
        static let synthHighNote = "synthHighNote"
        static let defaultArraySize = "defaultArraySize"
        static let codeTheme = "codeTheme"
        static let defaultShuffleID = "defaultShuffleID"
    }

    private let store: UserDefaults

    public init(store: UserDefaults = .standard) {
        self.store = store
        store.register(defaults: [
            Keys.selectedVisualizerID: "bargraph",
            Keys.playbackSpeed: 30.0,
            // Off by default — real audio now plays through ScrollingSortView (ToneKit-backed
            // AudioService.shared, see Modules/ToneKit/NOTICE.md), and a brand-new user shouldn't
            // have sound start playing on their very first sort without having chosen it.
            Keys.soundEnabled: false,
            Keys.synthLowNote: 36,
            Keys.synthHighNote: 72,
            Keys.defaultArraySize: 256,
            Keys.codeTheme: "monokai",
            Keys.defaultShuffleID: "random"
        ])
        selectedVisualizerID = VisualizerID(rawValue: store.string(forKey: Keys.selectedVisualizerID) ?? "bargraph")
        playbackSpeed = store.double(forKey: Keys.playbackSpeed)
        soundEnabled = store.bool(forKey: Keys.soundEnabled)
        synthNoteRange = store.integer(forKey: Keys.synthLowNote)...store.integer(forKey: Keys.synthHighNote)
        defaultArraySize = store.integer(forKey: Keys.defaultArraySize)
        codeTheme = CodeThemeID(rawValue: store.string(forKey: Keys.codeTheme) ?? "monokai")
        defaultShuffleID = ShuffleID(rawValue: store.string(forKey: Keys.defaultShuffleID) ?? "random")
    }

    private func persistNoteRange() {
        store.set(synthNoteRange.lowerBound, forKey: Keys.synthLowNote)
        store.set(synthNoteRange.upperBound, forKey: Keys.synthHighNote)
    }
}
