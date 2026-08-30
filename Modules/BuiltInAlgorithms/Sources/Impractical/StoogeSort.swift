import AlgorithmKit
import SortEngineKit

public struct StoogeSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "stoogesort")
  public let metadata = AlgorithmMetadata(
    displayName: "Stooge Sort",
    category: .impractical,
    sizeRange: 16...32,
    growthModel: OperationGrowthModel(
      anchorSize: 38, coefficients: [224731, 17718.9, 100.418],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .polynomialIntercept, coefficients: [100.418, 10087.1, -303583], rSquared: 0.994979),
    implementationComplexity: 5,
    stable: false,
    timeComplexity: ComplexityBounds(
      best: "O(n^{2.71})", average: "O(n^{2.71})", worst: "O(n^{2.71})"),
    spaceComplexity: "O(log n)",
    iconName: "theatermasks.fill"
  )

  public init() {}

  public func record(into engine: inout RecordingEngine) {
    guard engine.count > 1 else { return }
    stoogeSort(&engine, 0, engine.count - 1)
  }

  /// Ported faithfully from ArrayV's `StoogeSort.stoogeSort(A, i, j)`: swap the ends if they're
  /// out of order, then — for ranges of 3 or more elements — recursively sort the first 2/3,
  /// the last 2/3, and the first 2/3 again. `t = (j - i + 1) / 3` uses integer (floor) division,
  /// so subtracting it from `j` rounds the 2/3 boundary *up* rather than down (e.g. for a
  /// 5-element range, `t` is 1, leaving a 4-element first/third sub-range — `ceil(2/3 * 5)`, not
  /// `floor`) exactly as the algorithm requires to fully sort every input.
  private func stoogeSort(_ engine: inout RecordingEngine, _ i: Int, _ j: Int) {
    if engine.compare(i, j, by: >) {
      engine.swap(i, j)
    }
    if j - i + 1 >= 3 {
      let t = (j - i + 1) / 3
      stoogeSort(&engine, i, j - t)
      stoogeSort(&engine, i + t, j)
      stoogeSort(&engine, i, j - t)
    }
  }
}
