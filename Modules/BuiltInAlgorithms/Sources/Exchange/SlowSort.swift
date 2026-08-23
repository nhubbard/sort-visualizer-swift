import AlgorithmKit
import SortEngineKit

/// Ported from ArrayV's `SlowSort` — "multiply and surrender": `slowSort(i, j)` recursively sorts
/// halves `[i, m]`/`[m+1, j]`, settles the larger of `A[m]`/`A[j]` into position `j` with one
/// compare-and-swap, then recurses on `[i, j-1]`. Net effect: a divide-and-conquer restatement of
/// selection sort, deliberately impractical but fully deterministic (unlike Bogo/Bozo Sort's
/// open-ended random walk).
public struct SlowSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "slowsort")
  /// `sizeRange` capped at 64, well below `StoogeSort`'s 128: worst-case growth is
  /// `O(n^(log n))`, an exponent that grows with `n`, so the recorded-tape footprint explodes past
  /// 64 (a 128-element run takes ~7.4M compares).
  ///
  /// Stable: `false` — the recursive "tournament of maxima" shuffles equal-valued elements past
  /// each other before the final strict `>` compare ever sees them.
  public let metadata = AlgorithmMetadata(
    displayName: "Slow Sort",
    category: .exchange,
    sizeRange: 16...64,
    growthModel: OperationGrowthModel(
      anchorSize: 45, coefficients: [229877, 40045.9, 3580.68, 217.991, 10.1328, 0.382704],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .nToTheNLike, coefficients: [462.64, 0.0362426], rSquared: 0.999605),
    stable: false,
    timeComplexity: ComplexityBounds(
      best: "O(n^{log n})", average: "O(n^{log n})", worst: "O(n^{log n})"),
    spaceComplexity: "O(log n)",
    iconName: "tortoise.fill"
  )

  public init() {}

  public func record(into engine: inout RecordingEngine) {
    guard engine.count > 1 else { return }
    slowSort(&engine, 0, engine.count - 1)
  }

  /// Uses strict `(>)`, not the engine default `(>=)`: `>=` would additionally swap on equal
  /// values, corrupting tie order further (this sort is already unstable regardless).
  private func slowSort(_ engine: inout RecordingEngine, _ i: Int, _ j: Int) {
    if i >= j {
      return
    }
    let m = i + (j - i) / 2
    slowSort(&engine, i, m)
    slowSort(&engine, m + 1, j)
    if engine.compare(m, j, by: (>)) {
      engine.swap(m, j)
    }
    slowSort(&engine, i, j - 1)
  }
}
