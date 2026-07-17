import AlgorithmKit
import AppIntents
import SortFeature
import VisualizationKit

/// One algorithm, at its own maximum size, run once per visualizer in `VisualizerRegistry`'s
/// stable order — a single full rotation through every visualizer, not an unbounded loop (chain
/// with Shortcuts' own "Repeat" action to run it forever). Each pass switches the visualizer
/// *before* starting, then fully awaits that run finishing before switching again — deliberately
/// not a live mid-run switch (which the renderers do support, reactively) because the point here
/// is to see each visualizer's own complete, undisturbed run.
public struct RunVisualizerShowcaseIntent: AppIntent {
  public static var title: LocalizedStringResource { "Run Visualizer Showcase" }
  public static var description: IntentDescription {
    IntentDescription(
      "Runs one algorithm at its maximum size once per visualizer, switching visualizers only between runs.",
      categoryName: "Sort Symphony",
      searchKeywords: ["Visualizer Showcase", "Every Visualizer"])
  }

  public static var openAppWhenRun: Bool { true }

  @Parameter(
    title: "Algorithm",
    description: "The algorithm to showcase, run once per visualizer at its own maximum size.")
  public var algorithm: AlgorithmEntity

  public static var parameterSummary: some ParameterSummary {
    Summary("Run visualizer showcase for \(\.$algorithm)")
  }

  public init() {}

  public init(algorithm: AlgorithmEntity) {
    self.algorithm = algorithm
  }

  @MainActor
  public func perform() async throws -> some IntentResult {
    guard let realAlgorithm = AlgorithmRegistry.shared.algorithm(id: algorithm.algorithmID) else {
      throw SortSymphonyIntentError.algorithmUnavailable
    }
    let size = realAlgorithm.metadata.sizeRange.upperBound
    for visualizer in VisualizerRegistry.shared.visualizers {
      await SortCoordinator.shared.runSort(
        algorithm: realAlgorithm, visualizerID: visualizer.id, shuffleID: nil, size: size)
    }
    return .result()
  }
}
