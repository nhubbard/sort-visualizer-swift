import AlgorithmKit
import SortEngineKit

public struct SlopeSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "slopesort")
  public let metadata = AlgorithmMetadata(
    displayName: "Slope Sort",
    category: .exchange,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 219, coefficients: [238710, 2185, 5],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .polynomialIntercept, coefficients: [5, -5, -1.35917e-10], rSquared: 1),
    stable: true,
    timeComplexity: ComplexityBounds(best: "O(n^2)", average: "O(n^2)", worst: "O(n^2)"),
    spaceComplexity: "O(1)",
    iconName: "chart.line.uptrend.xyaxis"
  )
  public init() {}

  /// ArrayV's `SlopeSort`: for each `start` from 1 to `n-1`, walks an adjacent pair backward from
  /// `(start, start-1)` down to `(1, 0)`, swapping out-of-order neighbors. Unlike insertion sort,
  /// there's no early exit, so every adjacent pair is checked on every pass — strictly `O(n^2)`
  /// with no best-case shortcut.
  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 1 else { return }

    for start in 1..<n {
      var i = start
      var k = start - 1
      while k >= 0 {
        // Strict `<` (not the default `>=`) matches ArrayV's `Reads.compareIndices(...,
        // true) < 0` — ties never swap, which is what keeps this stable.
        if engine.compare(i, k, by: (<)) {
          engine.swap(i, k)
        }
        k -= 1
        i -= 1
      }
    }
  }
}
