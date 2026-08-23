import AlgorithmKit
import SortEngineKit

/// Ported from ArrayV's `ShatterSort` — a pure entry-point wrapper around
/// `ShatterSortingTemplate.shatterSort`'s bucket-then-insertion-sort finish. See that template's
/// own doc comment for the corrected (range-normalized) bucketing design.
///
/// ArrayV's `bucketCount` is an externally user-configured UI parameter shared with
/// `SimpleShatterSort`, with no equivalent plumbed through `SortAlgorithm` here — `4` is a fixed,
/// reasonable "few items per initial bucket" choice instead.
public struct ShatterSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "shattersort")
  public let metadata = AlgorithmMetadata(
    displayName: "Shatter Sort",
    category: .distribution,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 977, coefficients: [239859, 468.347, 0.227713],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .polynomialIntercept, coefficients: [0.227713, 23.3957, -357.268], rSquared: 0.995959),
    stable: true,
    timeComplexity: ComplexityBounds(
      best: "O(n)", average: "O(n + k)", worst: "O(n^2)"),
    spaceComplexity: "O(n)",
    iconName: "square.grid.3x3.fill"
  )

  public init() {}

  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 1 else { return }
    ShatterSortingTemplate.shatterSort(&engine, n, 4)
  }
}
