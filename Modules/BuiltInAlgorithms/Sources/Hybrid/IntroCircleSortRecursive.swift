import AlgorithmKit
import SortEngineKit

/// ArrayV's `IntroCircleSortRecursive` — `CircleSortRecursive`'s recursive `circleSortRoutine`
/// (see that file's own doc comment for the padded-power-of-two/guard details), capped at
/// `threshold` passes the same way `IntroCircleSortIterative` caps its iterative sibling: double
/// `n` from 1 until it reaches `end`, count the doublings, halve that count. If the budget runs out
/// before a pass reports zero swaps, it falls back to one full binary insertion sort pass, giving a
/// hard `O(n^2)` worst-case ceiling instead of circle sort's unbounded repeat-until-stable loop.
///
/// Stable: `false` — same as `CircleSortRecursive`, whose fold-inward compare-and-swap can reorder
/// equal elements across separate windows. The insertion sort fallback is itself stable, but can't
/// retroactively undo disordering already committed by earlier circle-sort passes.
public struct IntroCircleSortRecursive: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "introcirclesortrecursive")
  public let metadata = AlgorithmMetadata(
    displayName: "Intro Circle (Recursive)",
    category: .hybrid,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 829, coefficients: [239841, 499.178, 0.251744],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .polynomialIntercept, coefficients: [0.251744, 81.7865, -969.005], rSquared: 0.999804),
    stable: false,
    // Best/average mirror CircleSortRecursive's O(n log n)/O(n log^2 n). Worst case differs:
    // passes are capped at `threshold`, then the insertion sort fallback's O(n^2) shift step
    // dominates.
    timeComplexity: ComplexityBounds(
      best: "O(n log n)", average: "O(n log^2 n)", worst: "O(n^2)"),
    // Recursion stack depth, like CircleSortRecursive — the insertion-sort fallback itself is
    // O(1) space.
    spaceComplexity: "O(log n)",
    iconName: "repeat.circle.fill"
  )

  public init() {}

  public func record(into engine: inout RecordingEngine) {
    let end = engine.count
    guard end > 1 else { return }

    // Same padded-power-of-two `n` as CircleSortRecursive — every real array access below stays
    // separately guarded against `end`, so `n` only ever controls how deep the recursion's
    // lo/hi convergence goes, never an actual out-of-range read or write.
    var n = 1
    var threshold = 0
    while n < end {
      n *= 2
      threshold += 1
    }
    threshold /= 2

    // Verbatim `CircleSorting.circleSortRoutine` translation (see `CircleSortRecursive.swift`):
    // converge lo/hi toward the range's middle, then recurse into the first half unconditionally
    // and the second half only if it still overlaps the real array.
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

    // ArrayV's `do { iterations++; if (iterations >= threshold) { ...; break; } }
    // while (circleSortRoutine(...) != 0)`, translated via Swift's `repeat`/`while`: iterations
    // must be incremented and checked against `threshold` before each next pass.
    var iterations = 0
    repeat {
      iterations += 1
      if iterations >= threshold {
        // Fallback: one full binary insertion sort pass, inlined rather than calling into
        // `BinaryInsertionSort`'s own `SortAlgorithm` conformance (no precedent in this codebase
        // for one algorithm invoking another) — identical to `IntroCircleSortIterative`'s own
        // inlined fallback.
        for i in 1..<end {
          var lo = 0
          var hi = i
          while lo < hi {
            let mid = lo + (hi - lo) / 2
            if engine.compare(i, mid, by: <) {
              hi = mid
            } else {
              lo = mid + 1
            }
          }
          var j = i
          while j > lo {
            engine.swap(j, j - 1)
            j -= 1
          }
        }
        break
      }
    } while circleSortRoutine(0, n - 1) != 0
  }
}
