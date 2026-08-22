import AlgorithmKit
import AppIntents
import SettingsKit

/// The "just the ceiling" sibling of `FindArraySizesIntent` — most Shortcuts that want the biggest
/// size an algorithm supports (e.g. to feed `RunSortIntent(size:)` for a max-size-only run) don't
/// need the full stepped list, just `sizeRange.upperBound` on its own.
public struct FindMaximumArraySizeIntent: AppIntent {
  public static var title: LocalizedStringResource { "Find Maximum Array Size" }
  public static var description: IntentDescription {
    IntentDescription(
      "Finds the largest array size one algorithm supports.",
      categoryName: "Sort Symphony",
      searchKeywords: ["Maximum Size", "Max Size", "Largest Size", "Upper Bound"],
      resultValueName: "Maximum Array Size")
  }

  @Parameter(title: "Algorithm", description: "The algorithm whose maximum array size to look up.")
  public var algorithm: AlgorithmEntity

  public static var parameterSummary: some ParameterSummary {
    Summary("Find maximum array size for \(\.$algorithm)")
  }

  public init() {}

  public init(algorithm: AlgorithmEntity) {
    self.algorithm = algorithm
  }

  @MainActor
  public func perform() async throws -> some IntentResult & ReturnsValue<Int> {
    guard let realAlgorithm = AlgorithmRegistry.shared.algorithm(id: algorithm.algorithmID) else {
      throw SortSymphonyIntentError.algorithmUnavailable
    }
    let effectiveSizeRange = realAlgorithm.metadata.effectiveSizeRange(
      operationCap: AppSettings.shared.recordingOperationCap)
    return .result(value: effectiveSizeRange.upperBound)
  }
}
