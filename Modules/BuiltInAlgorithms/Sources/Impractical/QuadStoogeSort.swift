import AlgorithmKit
import SortEngineKit

/// Ported from ArrayV's `sorts/exchange/QuadStoogeSort.java` — categorized `.impractical` there
/// (`setCategory("Impractical Sorts")`) despite living in the `exchange` package, the same
/// override `ShoveSort`/`BogoSort` also need.
///
/// A 4-way generalization of `StoogeSort`: after settling the range's endpoints with one
/// compare-and-swap, `quadStooge(pos, len)` makes six recursive calls, each covering roughly
/// half the range (`len1 = len/2`, `len2 = (len+1)/2`, and `len3` — a third overlapping half-sized
/// window bridging the two) rather than `StoogeSort`'s three calls each covering 2/3 of the
/// range. Six calls of size `n/2` gives the recurrence `T(n) = 6T(n/2) + O(1)`, resolving to
/// `O(n^(log2 6)) ≈ O(n^2.585)` — a *lower* exponent than `StoogeSort`'s `O(n^2.71)` despite the
/// extra recursive calls, since halving shrinks the problem faster than thirding it.
public struct QuadStoogeSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "quadstoogesort")
  public let metadata = AlgorithmMetadata(
    displayName: "Quad Stooge Sort",
    category: .impractical,
    sizeRange: 16...48,
    growthModel: OperationGrowthModel(
      anchorSize: 89, coefficients: [234447, 6880.98, 51.1949],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .polynomialIntercept, coefficients: [51.1949, -2231.72, 27554.5], rSquared: 0.999815),
    stable: false,
    timeComplexity: ComplexityBounds(
      best: "O(n^{2.585})", average: "O(n^{2.585})", worst: "O(n^{2.585})"),
    spaceComplexity: "O(log n)",
    iconName: "theatermasks.fill"
  )

  public init() {}

  public func record(into engine: inout RecordingEngine) {
    guard engine.count > 1 else { return }
    quadStooge(&engine, 0, engine.count)
  }

  private func quadStooge(_ engine: inout RecordingEngine, _ pos: Int, _ len: Int) {
    if len >= 2 && engine.compare(pos, pos + len - 1, by: >) {
      engine.swap(pos, pos + len - 1)
    }
    guard len > 2 else { return }

    let len1 = len / 2
    let len2 = (len + 1) / 2
    let len3 = (len1 + 1) / 2 + (len2 + 1) / 2

    quadStooge(&engine, pos, len1)
    quadStooge(&engine, pos + len1, len2)
    quadStooge(&engine, pos + len1 / 2, len3)
    quadStooge(&engine, pos + len1, len2)
    quadStooge(&engine, pos, len1)
    if len > 3 {
      quadStooge(&engine, pos + len1 / 2, len3)
    }
  }
}
