import Foundation
import Observation
import VisualizationKit

/// §3.3, in full as of Phase 8. No `shuffleMethod` (shuffles are already data-driven via
/// `ShuffleRegistry`, not a settings-level enum — see Phase 6) and no `warnBeforeBogoSort`/
/// `warnBeforeBitonicSort` (the confirmation-dialog system they'd gate was removed in Phase 8, see
/// §9 of ARCHITECTURE_V2.md — `AlgorithmMetadata.sizeRange` already does that job unconditionally).
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

    private enum Keys {
        static let selectedVisualizerID = "selectedVisualizerID"
        static let playbackSpeed = "playbackSpeed"
        static let soundEnabled = "soundEnabled"
        static let synthLowNote = "synthLowNote"
        static let synthHighNote = "synthHighNote"
        static let defaultArraySize = "defaultArraySize"
        static let codeTheme = "codeTheme"
    }

    private let store: UserDefaults

    public init(store: UserDefaults = .standard) {
        self.store = store
        store.register(defaults: [
            Keys.selectedVisualizerID: "bargraph",
            Keys.playbackSpeed: 30.0,
            Keys.soundEnabled: true,
            Keys.synthLowNote: 36,
            Keys.synthHighNote: 72,
            Keys.defaultArraySize: 256,
            Keys.codeTheme: "monokai",
        ])
        selectedVisualizerID = VisualizerID(rawValue: store.string(forKey: Keys.selectedVisualizerID) ?? "bargraph")
        playbackSpeed = store.double(forKey: Keys.playbackSpeed)
        soundEnabled = store.bool(forKey: Keys.soundEnabled)
        synthNoteRange = store.integer(forKey: Keys.synthLowNote)...store.integer(forKey: Keys.synthHighNote)
        defaultArraySize = store.integer(forKey: Keys.defaultArraySize)
        codeTheme = CodeThemeID(rawValue: store.string(forKey: Keys.codeTheme) ?? "monokai")
    }

    private func persistNoteRange() {
        store.set(synthNoteRange.lowerBound, forKey: Keys.synthLowNote)
        store.set(synthNoteRange.upperBound, forKey: Keys.synthHighNote)
    }
}
