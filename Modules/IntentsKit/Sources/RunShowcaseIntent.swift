import AlgorithmKit
import AppIntents
import SortFeature

/// A from-scratch, Shortcuts-only reimplementation of `ContentView`'s in-app Showcase mode — every
/// registered algorithm once, alphabetically, at its own `sizeRange.upperBound`, leaving whichever
/// visualizer is currently selected untouched (exactly like the in-app version, whose visualizer
/// can still be changed mid-run via ⌘⇧V). Deliberately doesn't call into `ContentView`'s own
/// Showcase state — it just drives the same `SortCoordinator.runSort` primitive `RunSortIntent`
/// does, once per algorithm, fully awaiting each pass before starting the next.
public struct RunShowcaseIntent: AppIntent {
  public static var title: LocalizedStringResource { "Run Showcase" }
  public static var description: IntentDescription {
    IntentDescription(
      "Runs every algorithm once, in alphabetical order, at its own maximum size, with the current visualizer.",
      categoryName: "Sort Symphony",
      searchKeywords: ["Showcase", "Demo", "Every Algorithm"])
  }

  public static var openAppWhenRun: Bool { true }

  public init() {}

  @MainActor
  public func perform() async throws -> some IntentResult {
    let algorithms = AlgorithmRegistry.shared.algorithms
      .sorted { $0.metadata.displayName < $1.metadata.displayName }
    for algorithm in algorithms {
      await SortCoordinator.shared.runSort(
        algorithm: algorithm, visualizerID: nil, shuffleID: nil,
        size: algorithm.metadata.sizeRange.upperBound)
    }
    return .result()
  }
}
