import AlgorithmKit
import SortEngineKit

/// Ported from ArrayV's `PDQBranchedSort` — a pure entry-point wrapper around
/// `PDQSortingTemplate.pdqLoop` using the branch-based partition (`branchless: false`). See that
/// template's own doc comment for the shared algorithm.
public struct PDQBranchedSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "pdqbranchedsort")
  public let metadata = AlgorithmMetadata(
    displayName: "Pattern-Defeating Quick Sort",
    category: .hybrid,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 1725, coefficients: [239818, 242.583, 0.0598513],
      measuredSafeCeiling: nil),
    stable: false,
    timeComplexity: ComplexityBounds(
      best: "O(n)", average: "O(n log n)", worst: "O(n log n)"),
    spaceComplexity: "O(log n)",
    iconName: "bolt.shield"
  )

  public init() {}

  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 1 else { return }
    PDQSortingTemplate.sortBranched(&engine, 0, n)
  }
}
