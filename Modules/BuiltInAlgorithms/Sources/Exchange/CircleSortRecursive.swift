import AlgorithmKit
import SortEngineKit

/// ArrayV's `CircleSortRecursive` — like ``CircleSortIterative``, a symmetric compare-and-swap pass
/// converging a range's two ends toward its middle, but reached via genuine recursion into the two
/// half-ranges instead of an iterative `gap`/`start` loop.
///
/// The recursion's working size is padded up to the next power of two above the real array length
/// (`end`), while every actual access stays guarded against `end`. Two asymmetric guards matter:
/// `hi < end` gates only the compare-and-swap, not the convergence loop itself, so `lo`/`hi` keep
/// marching even while `hi` points past the real array; `low + mid + 1 < end` gates whether the
/// *second* half is even recursed into — the first half is always recursed into regardless.
///
/// One pass is a full recursive sweep; `runSort` repeats sweeps until one performs zero swaps.
public struct CircleSortRecursive: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "circlesortrecursive")
  public let metadata = AlgorithmMetadata(
    displayName: "Circle Sort (Recursive)",
    category: .exchange,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 739, coefficients: [231890, 439.615, 0.114404],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .powerLog, coefficients: [9.13569, 1.2496], rSquared: 0.99562),
    stable: false,
    timeComplexity: ComplexityBounds(
      best: "O(n log n)", average: "O(n log^2 n)", worst: "O(n log^2 n)"),
    // Distinct from CircleSortIterative's O(1): this version genuinely recurses into two
    // half-ranges per level, so it carries a real O(log n) recursion-stack depth on top of the
    // otherwise in-place compare-and-swap work.
    spaceComplexity: "O(log n)",
    iconName: "repeat.circle.fill"
  )

  public init() {}

  public func record(into engine: inout RecordingEngine) {
    let end = engine.count
    guard end > 1 else { return }

    var n = 1
    while n < end {
      n *= 2
    }

    func circleSortRoutine(_ lo: Int, _ hi: Int) -> Int {
      if lo == hi { return 0 }

      let low = lo
      let high = hi
      let mid = (hi - lo) / 2

      var lo = lo
      var hi = hi
      var swapCount = 0
      while lo < hi {
        if hi < end, engine.compare(lo, hi, by: (>)) {
          engine.swap(lo, hi)
          swapCount += 1
        }
        lo += 1
        hi -= 1
      }

      swapCount += circleSortRoutine(low, low + mid)
      if low + mid + 1 < end {
        swapCount += circleSortRoutine(low + mid + 1, high)
      }
      return swapCount
    }

    var numberOfSwaps: Int
    repeat {
      numberOfSwaps = circleSortRoutine(0, n - 1)
    } while numberOfSwaps != 0
  }
}
