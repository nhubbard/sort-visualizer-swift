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
/// Every rotation is `O(n)`, but the number of rotations itself is `O(n^2)`, not `O(n)` the way a
/// shift-based insertion sort's element-relocation count is — a single early-array element can be
/// re-shoved once per later inversion it collides with as `i` backs up and rescans, and on
/// adversarial (or even just random) input that happens roughly `n(n-1)/2` times, not `n` times.
/// `O(n)` rotations × `O(n^2)` of them is `O(n^3)` overall, confirmed both by this exact shove-count
/// (matches the triangular numbers on strictly-descending input) and by direct measurement: real
/// `RecordingEngine` op counts fit a `powerLaw` curve with exponent ≈2.97-3.0 (adjusted R² >
/// 0.9998) across nearly every shuffle, including plain random -- not just the adversarial worst
/// case ArrayV's own `O(n^2)` label (and this port's previous claim) implied. Despite ArrayV's own
/// impractical-sort label, `O(n^3)` is worse than the label's own `O(n^2)` undersells it as.
public struct ShoveSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "shovesort")
  public let metadata = AlgorithmMetadata(
    displayName: "Shove Sort",
    category: .impractical,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 52, coefficients: [227387, 13239.8, 258.144, 1.70068],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .powerLaw, coefficients: [1.44926, 3.02775], rSquared: 0.99848),
    implementationComplexity: 6,
    stable: false,
    timeComplexity: ComplexityBounds(best: "O(n)", average: "O(n^3)", worst: "O(n^3)"),
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
