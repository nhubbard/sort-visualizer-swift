import AlgorithmKit
import SortEngineKit

/// Ported from ArrayV's `sorts/exchange/ShoveSort.java` — categorized `.impractical` there
/// (`setCategory("Impractical Sorts")`) despite living in the `exchange` package, the same
/// "category string wins over package location" rule `QuadStoogeSort`/`BogoSort` already
/// establish.
///
/// Scans left to right; when an inverted adjacent pair is found, the offending element isn't
/// shifted into its correct spot — it's "shoved" all the way to the end of the range via a chain
/// of adjacent swaps (`for f in i..<(end-1) { swap(f, f+1) }`), which is a left-rotation of
/// `[i, end-1]` by one position. `i` then backs up by one (unless already at `start`) to
/// re-examine the pair that slid into its old spot, rather than advancing past it.
///
/// Every rotation is `O(n)`, and the same element can be re-shoved on a later pass, so this is
/// the same asymptotic order as a shift-based insertion sort — `O(n^2)` — despite ArrayV's own
/// impractical-sort label.
public struct ShoveSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "shovesort")
  public let metadata = AlgorithmMetadata(
    displayName: "Shove Sort",
    category: .impractical,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 45, coefficients: [217155, 25867.3, 1540.64, 61.1728, 1.8217, 0.0433997],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .exponential, coefficients: [1020.48, 1.1265], rSquared: 0.999456),
    implementationComplexity: 6,
    stable: false,
    timeComplexity: ComplexityBounds(best: "O(n)", average: "O(n^2)", worst: "O(n^2)"),
    spaceComplexity: "O(1)",
    iconName: "arrowshape.right.fill"
  )

  public init() {}

  public func record(into engine: inout RecordingEngine) {
    let end = engine.count
    guard end > 1 else { return }
    var i = 0
    while i < end - 1 {
      if engine.compare(i, i + 1, by: >) {
        for f in i..<(end - 1) {
          engine.swap(f, f + 1)
        }
        if i > 0 {
          i -= 1
        }
        continue
      }
      i += 1
    }
  }
}
