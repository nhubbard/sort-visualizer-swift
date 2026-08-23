import AlgorithmKit
import SortEngineKit

public struct QuickBogoSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "quickbogosort")
  public let metadata = AlgorithmMetadata(
    displayName: "Quick Bogo Sort",
    category: .impractical,
    sizeRange: 4...6,
    growthModel: OperationGrowthModel(
      anchorSize: 7, coefficients: [80426.6, 170544, 187079, 140785, 81461.4, 38549.3],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .factorial, coefficients: [59.1261, 1.08972], rSquared: 0.999744),
    stable: false,
    timeComplexity: ComplexityBounds(
      best: "O(n)", average: "O(n \\times n!)", worst: "O(n \\times n!)"),
    spaceComplexity: "O(log n)",
    iconName: "questionmark.square.fill"
  )
  public init() {}

  /// ArrayV's `QuickBogoSort` picks the first element as pivot and reshuffles the range until it
  /// happens to be partitioned around it — the same open-ended random walk `BogoSort` fixed.
  /// Substitutes a lexicographic `nextPermutation` walk (as `LessBogoSort`/`CocktailBogoSort` use),
  /// tracking the pivot's position through each step's swap and reversal.
  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 1 else { return }

    func isRangePartitioned(_ start: Int, _ pivot: Int, _ end: Int) -> Bool {
      for i in start..<pivot where engine.compare(i, pivot, by: (>)) { return false }
      for i in (pivot + 1)..<end where engine.compare(pivot, i, by: (>)) { return false }
      return true
    }

    func quickBogo(_ start: Int, _ end: Int) {
      guard start < end - 1 else { return }
      var pivot = start

      func trackedSwap(_ i: Int, _ j: Int) {
        engine.swap(i, j)
        if pivot == i { pivot = j } else if pivot == j { pivot = i }
      }

      func trackedReversal(_ lo: Int, _ hi: Int) {
        engine.reversal(lo, hi)
        if pivot >= lo, pivot <= hi { pivot = lo + hi - pivot }
      }

      func nextPermutation() -> Bool {
        var i = end - 2
        while i >= start, engine.compare(i, i + 1) { i -= 1 }
        guard i >= start else { return false }
        var j = end - 1
        while !engine.compare(j, i, by: (>)) { j -= 1 }
        trackedSwap(i, j)
        trackedReversal(i + 1, end - 1)
        return true
      }

      while !isRangePartitioned(start, pivot, end) {
        if !nextPermutation() {
          trackedReversal(start, end - 1)
        }
      }

      quickBogo(start, pivot)
      quickBogo(pivot + 1, end)
    }

    quickBogo(0, n)
  }
}
