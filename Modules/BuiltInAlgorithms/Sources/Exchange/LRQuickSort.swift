import AlgorithmKit
import SortEngineKit

/// ArrayV's `LRQuickSort` ("Quick Sort, Left/Right Pointers") — a Hoare-style partition, distinct
/// from ``LLQuickSort``'s single-boundary Lomuto scheme. Two pointers `i`/`j` advance from opposite
/// ends of the range inward, swapping whenever both stop (`i` at `>= pivot`, `j` at `<= pivot`) with
/// `i <= j`; the range then recurses on `[p, j]` and `[i, r]`, which after the final swap-and-advance
/// never overlap or skip an index.
///
/// The pivot is the range's middle element, held in a local since neither pointer ever writes to
/// its own slot mid-partition (same held-value pattern as ``LLQuickSort``/``CycleSort``).
///
/// Complexity: choosing the middle element (vs. ``LLQuickSort``'s fixed end) avoids the degenerate
/// case on already-sorted/reverse-sorted input, but a fixed data-independent pivot can still be
/// defeated by adversarial input, so worst case remains `O(n^2)`.
///
/// Stable: `false` — the swap-and-cross step can exchange equal-valued elements from opposite ends
/// of the range, flipping their relative order.
public struct LRQuickSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "lrquicksort")
  public let metadata = AlgorithmMetadata(
    displayName: "LR Quick Sort",
    category: .exchange,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 555, coefficients: [239548, 849.223, 0.752436],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .polynomialIntercept, coefficients: [0.752436, 14.0195, -2.24718], rSquared: 1),
    stable: false,
    timeComplexity: ComplexityBounds(best: "O(n log n)", average: "O(n log n)", worst: "O(n^2)"),
    spaceComplexity: "O(log n)",
    iconName: "arrow.left.and.right.righttriangle.left.righttriangle.right.fill"
  )

  public init() {}

  public func record(into engine: inout RecordingEngine) {
    guard engine.count > 1 else { return }
    quickSort(&engine, 0, engine.count - 1)
  }

  // A real, reproduced `EXC_BAD_ACCESS` (1192 frames) surfaced from the exhaustive Full Sweep:
  // a fixed, data-independent pivot rule (the middle element) can still be defeated by
  // adversarial input into a perfectly skewed 1-versus-(k-1) partition at *every* level (see
  // `middlePivotKillerSequence` in the correctness test suite for the construction), and Swift
  // gives no guaranteed tail-call optimization -- two unbounded recursive calls per level made
  // real call-stack depth `O(n)` in that case, deep enough to overflow the stack well before
  // `maxReasonableArraySize`. Fixed with the standard technique for bounding quicksort's
  // recursion depth: always recurse (a real call) into whichever partition is *smaller*, and
  // loop for the larger one instead of a second recursive call. Since the recursed-into side is
  // never more than half of the remaining range, real recursion depth is bounded to `O(log n)`
  // regardless of how skewed any single partition is.
  //
  // This can change which partition's swaps get recorded first when the right partition happens
  // to be the smaller one (the original always fully finished the left partition before starting
  // the right) -- the final sorted result and swap/compare counts are unaffected, only the
  // interleaving order in that one case, an unavoidable trade-off for bounding the recursion (see
  // the fix's own regression test for why strict left-first order and a stack-depth guarantee are
  // mutually exclusive here).
  private func quickSort(_ engine: inout RecordingEngine, _ pArg: Int, _ rArg: Int) {
    var p = pArg
    var r = rArg
    while p < r {
      let pivotIndex = p + (r - p + 1) / 2
      // Held-value pattern (see the doc comment above): the pivot's own slot is never written to
      // during this partition, so one read up front stands in for every live comparison against
      // it below.
      let pivotValue = engine.values[pivotIndex]

      var i = p
      var j = r
      while i <= j {
        while engine.compareValue(i, against: pivotValue, by: (<)) {
          i += 1
        }
        while engine.compareValue(j, against: pivotValue, by: (>)) {
          j -= 1
        }
        if i <= j {
          engine.swap(i, j)
          i += 1
          j -= 1
        }
      }

      if (j - p) < (r - i) {
        if p < j {
          quickSort(&engine, p, j)
        }
        p = i
      } else {
        if i < r {
          quickSort(&engine, i, r)
        }
        r = j
      }
    }
  }
}
