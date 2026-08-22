import AppIntents
import SettingsKit
import VisualizationKit

/// Sets `AppSettings.selectedVisualizerID` directly — every live renderer already reads that
/// setting reactively (see `AppSettings.cycleVisualizer()`'s own doc comment), so this takes
/// effect immediately on an already-open sort, with no separate "nudge the active session" step
/// needed the way playback speed/sound need.
public struct SetVisualizerIntent: AppIntent {
  public static var title: LocalizedStringResource { "Set Visualizer" }
  public static var description: IntentDescription {
    IntentDescription(
      "Changes which visualizer Sort Symphony draws sorts with.",
      categoryName: "Sort Symphony",
      searchKeywords: ["Visualizer", "Visualization"])
  }

  @Parameter(title: "Visualizer", description: "Which visualizer to draw sorts with.")
  public var visualizer: VisualizerEntity

  public static var parameterSummary: some ParameterSummary {
    Summary("Set visualizer to \(\.$visualizer)")
  }

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
    IntentDescription(
      "Advances Sort Symphony to the next visualizer.",
      categoryName: "Sort Symphony",
      searchKeywords: ["Next Visualizer", "Change Visualizer"])
  }

  public init() {}

  @MainActor
  public func perform() async throws -> some IntentResult {
    AppSettings.shared.cycleVisualizer()
    return .result()
  }
}

/// The value-returning counterpart to `CycleVisualizerIntent` — same advance, but hands back the
/// visualizer it landed on instead of just nudging state, so a Shortcut can feed that straight
/// into `RunSortIntent`'s `visualizer` parameter as a variable instead of a fixed literal. See
/// `GetNextShuffleIntent`'s doc comment for the shape this mirrors.
public struct GetNextVisualizerIntent: AppIntent {
  public static var title: LocalizedStringResource { "Get Next Visualizer" }
  public static var description: IntentDescription {
    IntentDescription(
      "Advances Sort Symphony's visualizer by one step and returns it — chain with Run Sort to cycle through every visualizer over a long run.",
      categoryName: "Sort Symphony",
      searchKeywords: ["Next Visualizer", "Cycle Visualizer", "Visualizer"],
      resultValueName: "Visualizer")
  }

  public init() {}

  @MainActor
  public func perform() async throws -> some IntentResult & ReturnsValue<VisualizerEntity> {
    AppSettings.shared.cycleVisualizer()
    let visualizer =
      VisualizerRegistry.shared.visualizer(id: AppSettings.shared.selectedVisualizerID)
      ?? VisualizerRegistry.shared.visualizers.first
    guard let visualizer else { throw SortSymphonyIntentError.visualizerUnavailable }
    return .result(value: VisualizerEntity(visualizer: visualizer))
  }
}
