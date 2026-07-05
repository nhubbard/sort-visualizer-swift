import Foundation
import Observation
import VisualizationKit

/// Just enough of §3.3 to unblock Phase 4 (`selectedVisualizerID`, `playbackSpeed`) — the rest
/// (`soundEnabled`, `synthNoteRange`, `defaultArraySize`, `shuffleMethod`, `codeTheme`,
/// `warnBeforeBogoSort`/`warnBeforeBitonicSort`) lands in Phase 8. Follows the same
/// `UserDefaults`-backed, `didSet`-persisted pattern the full version will use, so Phase 8 only
/// adds properties rather than retrofitting persistence onto these two.
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

    private enum Keys {
        static let selectedVisualizerID = "selectedVisualizerID"
        static let playbackSpeed = "playbackSpeed"
    }

    private let store: UserDefaults

    public init(store: UserDefaults = .standard) {
        self.store = store
        store.register(defaults: [
            Keys.selectedVisualizerID: "bargraph",
            Keys.playbackSpeed: 30.0,
        ])
        selectedVisualizerID = VisualizerID(rawValue: store.string(forKey: Keys.selectedVisualizerID) ?? "bargraph")
        playbackSpeed = store.double(forKey: Keys.playbackSpeed)
    }
}
