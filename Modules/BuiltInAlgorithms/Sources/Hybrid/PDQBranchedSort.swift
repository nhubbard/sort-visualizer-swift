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
      anchorSize: 1087, coefficients: [239844, 349.249, 0.117028],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .polynomialIntercept, coefficients: [0.117028, 94.8297, -1512.5], rSquared: 0.99967),
    implementationComplexity: 110,
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
