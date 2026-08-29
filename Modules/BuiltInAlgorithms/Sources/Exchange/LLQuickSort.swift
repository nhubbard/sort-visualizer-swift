import AlgorithmKit
import SortEngineKit

/// ArrayV's `LLQuickSort` ("Quick Sort, Left/Left Pointers") — classic Lomuto partition: pivot is
/// always the last element (`array[hi]`), and forward-scanning pointer `i` marks the boundary of
/// "confirmed less-than-pivot" elements as `j` sweeps the rest of the range. No pivot randomization
/// or median-of-three selection, which is why already-sorted/reverse-sorted input triggers the
/// classic `O(n^2)` worst case. Distinct from this app's Hoare-style `QuickSort` and the
/// `TernaryLLQuickSort`/`TernaryLRQuickSort` three-way partition variants.
public struct LLQuickSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "llquicksort")
  public let metadata = AlgorithmMetadata(
    displayName: "LL Quick Sort",
    category: .exchange,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 244, coefficients: [238383, 1953, 4],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .polynomialIntercept, coefficients: [4, 1, -5], rSquared: 1),
    implementationComplexity: 7,
    stable: false,
    timeComplexity: ComplexityBounds(best: "O(n log n)", average: "O(n log n)", worst: "O(n^2)"),
    spaceComplexity: "O(log n)",
    iconName: "arrow.right.to.line"
  )

  public init() {}

  public func record(into engine: inout RecordingEngine) {
    guard engine.count > 1 else { return }
    quickSort(&engine, 0, engine.count - 1)
  }

  private func partition(_ engine: inout RecordingEngine, _ lo: Int, _ hi: Int) -> Int {
    // Held-value pattern (matching `CycleSort`'s precedent): `hi` is never written to until
    // the final pivot-placement swap below, so reading `engine.values[hi]` once up front is
    // equivalent to ArrayV's `Reads.compareValues(array[j], pivot) < 0` against a value that
    // never changes mid-sweep. Every subsequent comparison against `pivot` goes through
    // `engine.compareValue` — this scans the *entire* `[lo, hi)` range regardless of how many
    // elements actually swap, so a conditional `engine.swap` alone would leave most of that real
    // comparison work invisible to the tape/op count on skewed input.
    let pivot = engine.values[hi]
    var i = lo
    for j in lo..<hi {
      if engine.compareValue(j, against: pivot, by: (<)) {
        engine.swap(i, j)
        i += 1
      }
    }
    engine.swap(i, hi)
    return i
  }

  private func quickSort(_ engine: inout RecordingEngine, _ lo: Int, _ hi: Int) {
    guard lo < hi else { return }
    let p = partition(&engine, lo, hi)
    quickSort(&engine, lo, p - 1)
    quickSort(&engine, p + 1, hi)
  }
}
