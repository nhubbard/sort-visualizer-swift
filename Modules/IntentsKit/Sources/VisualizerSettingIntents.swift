import AppIntents
import SettingsKit

/// Sets `AppSettings.selectedVisualizerID` directly — every live renderer already reads that
/// setting reactively (see `AppSettings.cycleVisualizer()`'s own doc comment), so this takes
/// effect immediately on an already-open sort, with no separate "nudge the active session" step
/// needed the way playback speed/sound need.
public struct SetVisualizerIntent: AppIntent {
    public static var title: LocalizedStringResource { "Set Visualizer" }
    public static var description: IntentDescription {
        IntentDescription("Changes which visualizer Sort Symphony draws sorts with.", categoryName: "Sort Symphony")
    }

    @Parameter(title: "Visualizer")
    public var visualizer: VisualizerEntity

    public init() {}

    public init(visualizer: VisualizerEntity) {
        self.visualizer = visualizer
    }

    @MainActor
    public func perform() async throws -> some IntentResult {
        AppSettings.shared.selectedVisualizerID = visualizer.visualizerID
        return .result()
    }
}

/// The App Intents equivalent of the hidden ⌘⇧V shortcut — advances one step through
/// `VisualizerRegistry`'s stable order, wrapping back to the first past the last.
public struct CycleVisualizerIntent: AppIntent {
    public static var title: LocalizedStringResource { "Cycle Visualizer" }
    public static var description: IntentDescription {
        IntentDescription("Advances Sort Symphony to the next visualizer.", categoryName: "Sort Symphony")
    }

    public init() {}

    @MainActor
    public func perform() async throws -> some IntentResult {
        AppSettings.shared.cycleVisualizer()
        return .result()
    }
}
