import AlgorithmKit
import SortEngineKit

/// Ported from ArrayV's `SimpleShatterSort` — a pure entry-point wrapper around
/// `ShatterSortingTemplate.simpleShatterSort`'s repeated shrinking-granularity bucket passes. See
/// that template's own doc comment for the corrected (range-normalized) bucketing design.
///
/// ArrayV's own `rate` is `floor(log2(sortLength)) / 2` — reused verbatim here (well-defined and
/// `>= 2` throughout this algorithm's `16...256` `sizeRange`, so the shrinking loop always
/// terminates); `bucketCount` (`num`) is the same externally-configured UI parameter
/// `ShatterSort` uses, with no equivalent plumbed through `SortAlgorithm` here — `4` is used for
/// the same reason.
public struct SimpleShatterSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "simpleshattersort")
  public let metadata = AlgorithmMetadata(
    displayName: "Simple Shatter Sort",
    category: .distribution,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 16527, coefficients: [239998, 24.634, 0.000611972],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .polynomialIntercept, coefficients: [0.000611972, 4.40588, 26.5466], rSquared: 0.999512),
    stable: true,
    timeComplexity: ComplexityBounds(
      best: "O(n)", average: "O(n log n)", worst: "O(n^2)"),
    spaceComplexity: "O(n)",
    iconName: "square.grid.2x2.fill"
  )

  public init() {}

  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 1 else { return }
    let rate = max(2, (Int.bitWidth - 1 - n.leadingZeroBitCount) / 2)
    ShatterSortingTemplate.simpleShatterSort(&engine, n, 4, rate)
  }
}
