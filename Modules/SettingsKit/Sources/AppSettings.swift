import AlgorithmKit
import Foundation
import Observation
import UIKit
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

    /// Manual override — off by default, since `reduceFlashingEffective` already turns this on
    /// automatically for anyone with Reduce Motion enabled system-wide (see that property's own
    /// doc comment). This exists for someone who wants smoothed highlight colors without also
    /// turning on every other Reduce Motion effect across their whole device.
    public var reduceFlashingEnabled: Bool {
        didSet { store.set(reduceFlashingEnabled, forKey: Keys.reduceFlashingEnabled) }
    }

    /// What Metal renderers actually check before easing highlight-color changes instead of
    /// snapping them (see `MetalIncrementalRenderer.reduceFlashingEnabled`) — the manual toggle
    /// above, OR'd with the system's Reduce Motion accessibility setting, Apple's own
    /// HIG-documented signal for reducing rapid flashing/strobing effects. `UIAccessibility`
    /// bridges this from the Mac's native Accessibility preferences under Mac Catalyst too.
    public var reduceFlashingEffective: Bool {
        reduceFlashingEnabled || cachedSystemReduceMotionEnabled
    }

    /// Cached instead of querying `UIAccessibility.isReduceMotionEnabled` fresh on every
    /// `reduceFlashingEffective` read — `MetalRendererView.updateUIView` reads that during every
    /// SwiftUI body evaluation, which happens very often during active playback. Updated only when
    /// the system setting actually changes, via the `NotificationCenter` observer registered in
    /// `init`, so a read here is always just a plain stored-property access.
    private var cachedSystemReduceMotionEnabled: Bool

    private enum Keys {
        static let selectedVisualizerID = "selectedVisualizerID"
        static let playbackSpeed = "playbackSpeed"
        static let soundEnabled = "soundEnabled"
        static let synthLowNote = "synthLowNote"
        static let synthHighNote = "synthHighNote"
        static let defaultArraySize = "defaultArraySize"
        static let codeTheme = "codeTheme"
        static let defaultShuffleID = "defaultShuffleID"
        static let reduceFlashingEnabled = "reduceFlashingEnabled"
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
            Keys.defaultShuffleID: "random",
            Keys.reduceFlashingEnabled: false
        ])
        selectedVisualizerID = VisualizerID(rawValue: store.string(forKey: Keys.selectedVisualizerID) ?? "bargraph")
        playbackSpeed = store.double(forKey: Keys.playbackSpeed)
        soundEnabled = store.bool(forKey: Keys.soundEnabled)
        synthNoteRange = store.integer(forKey: Keys.synthLowNote)...store.integer(forKey: Keys.synthHighNote)
        defaultArraySize = store.integer(forKey: Keys.defaultArraySize)
        codeTheme = CodeThemeID(rawValue: store.string(forKey: Keys.codeTheme) ?? "monokai")
        defaultShuffleID = ShuffleID(rawValue: store.string(forKey: Keys.defaultShuffleID) ?? "random")
        reduceFlashingEnabled = store.bool(forKey: Keys.reduceFlashingEnabled)
        cachedSystemReduceMotionEnabled = UIAccessibility.isReduceMotionEnabled

        // `queue: .main` guarantees this closure only ever runs on the main thread, same as every
        // other `UIAccessibility` display-option notification — `MainActor.assumeIsolated` below
        // is a safe, correct assertion given that guarantee, matching the same cross-isolation
        // callback shape `MetalBarRenderer.mtkView(_:drawableSizeWillChange:)` already uses.
        NotificationCenter.default.addObserver(
            forName: UIAccessibility.reduceMotionStatusDidChangeNotification, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.cachedSystemReduceMotionEnabled = UIAccessibility.isReduceMotionEnabled
            }
        }
    }

    private func persistNoteRange() {
        store.set(synthNoteRange.lowerBound, forKey: Keys.synthLowNote)
        store.set(synthNoteRange.upperBound, forKey: Keys.synthHighNote)
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
