import AlgorithmKit
import SortEngineKit

/// Ported from ArrayV's `PDQBranchlessSort` — a pure entry-point wrapper around
/// `PDQSortingTemplate.pdqLoop` using the block-quicksort-style branchless partition
/// (`branchless: true`). See that template's own doc comment for the shared algorithm.
public struct PDQBranchlessSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "pdqbranchlesssort")
  public let metadata = AlgorithmMetadata(
    displayName: "Branchless Pattern-Defeating Quick Sort",
    category: .hybrid,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 3459, coefficients: [154956, 56.5413, 0.002045],
      measuredSafeCeiling: nil),
    stable: false,
    timeComplexity: ComplexityBounds(
      best: "O(n)", average: "O(n log n)", worst: "O(n log n)"),
    spaceComplexity: "O(log n)",
    iconName: "bolt.shield.fill"
  )

  public init() {}

  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 1 else { return }
    PDQSortingTemplate.sortBranchless(&engine, 0, n)
  }
}
