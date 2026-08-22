import AlgorithmKit
import AppIntents
import SettingsKit
import SortFeature

/// A from-scratch, Shortcuts-only reimplementation of `ContentView`'s in-app Showcase mode — every
/// registered algorithm once, alphabetically, at its own `sizeRange.upperBound`. Cycles the
/// shuffle and visualizer once per algorithm (`AppSettings.cycleShuffle()`/`cycleVisualizer()`),
/// matching `ContentView`'s `startShowcase()`/`advanceShowcase()` exactly, so a full pass exercises
/// every shuffle and every visualizer at least once. Deliberately doesn't call into `ContentView`'s
/// own Showcase state — it just drives the same `SortCoordinator.runSort` primitive `RunSortIntent`
/// does, once per algorithm, fully awaiting each pass before starting the next.
public struct RunShowcaseIntent: AppIntent {
  public static var title: LocalizedStringResource { "Run Showcase" }
  public static var description: IntentDescription {
    IntentDescription(
      "Runs every algorithm once, in alphabetical order, at its own maximum size, cycling through every shuffle and visualizer along the way.",
      categoryName: "Sort Symphony",
      searchKeywords: ["Showcase", "Demo", "Every Algorithm"])
  }

  public static var openAppWhenRun: Bool { true }

  public init() {}

  @MainActor
  public func perform() async throws -> some IntentResult {
    let algorithms = AlgorithmRegistry.shared.algorithms
      .sorted { $0.metadata.displayName < $1.metadata.displayName }
    let operationCap = AppSettings.shared.recordingOperationCap
    for algorithm in algorithms {
      AppSettings.shared.cycleShuffle()
      AppSettings.shared.cycleVisualizer()
      await SortCoordinator.shared.runSort(
        algorithm: algorithm, visualizerID: nil, shuffleID: nil,
        size: algorithm.metadata.effectiveSizeRange(operationCap: operationCap).upperBound)
    }
    return .result()
  }
}
