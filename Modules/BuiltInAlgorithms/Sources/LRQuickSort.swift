import AlgorithmKit
import SortEngineKit

/// ArrayV's `LRQuickSort` ("Quick Sort, Left/Right Pointers") — a Hoare-style partition, distinct
/// from ``LLQuickSort``'s single-boundary Lomuto scheme. Rather than one forward-sweeping pointer
/// tracking a "confirmed less-than-pivot" boundary, this variant advances two pointers `i`/`j` from
/// opposite ends of the range toward each other: `i` skips forward past every element already
/// strictly less than the pivot, `j` skips backward past every element already strictly greater,
/// and whenever both pointers stop (`i` found something `>= pivot`, `j` found something `<=
/// pivot`) with `i <= j`, those two elements are swapped and both pointers advance one further step
/// inward. The range then recurses on `[p, j]` and `[i, r]` — note the overlap-avoiding split point:
/// after the last swap-and-advance, `j < i`, so these two sub-ranges never re-examine the same
/// index, but ALSO don't leave any index unexamined (they always meet or cross by exactly one
/// step), matching Hoare's original partition scheme rather than Lomuto's single pivot-index
/// return value.
///
/// The pivot itself is chosen as the range's middle element (`p + (r - p + 1) / 2`) up front and
/// held in a local (never written to mid-partition, since neither pointer ever swaps the pivot's
/// own slot with itself), so — mirroring ``LLQuickSort``'s and ``CycleSort``'s identical
/// already-established pattern for a value ArrayV reads live via `Reads.compareValues` against a
/// held constant — this reads `engine.values[pivot]` once rather than re-reading it through
/// `engine.compare` on every pointer step. ArrayV's own `Highlights.markArray(3, ...)` calls that
/// track the pivot's highlight as it gets swapped are purely cosmetic bookkeeping with no effect on
/// the recorded sort itself (the actual pivot VALUE never moves during the partition — only which
/// physical index currently holds it changes, and nothing here depends on knowing that index), so
/// this port omits them, same as other ports in this codebase drop ArrayV's non-essential
/// visualization-only highlight calls.
///
/// ## Complexity
///
/// Choosing the middle element as pivot (rather than always the first or last, as ``LLQuickSort``
/// does) means already-sorted or reverse-sorted input no longer triggers the classic degenerate
/// worst case on its own — those inputs still partition roughly in half, giving `O(n log n)`. But a
/// fixed, data-independent pivot rule (no randomization, no median-of-three sampling) can still be
/// defeated by a specifically constructed adversarial input that keeps steering the middle-element
/// choice to one of the extremes of each recursive sub-range, so the worst case remains `O(n^2)`,
/// same as ``LLQuickSort``/``QuickSort``. Average case is the standard `O(n log n)` for
/// quicksort-family algorithms over random input. Space is `O(log n)`: the recursion depth for a
/// range that keeps splitting roughly evenly.
///
/// ## Stability: `false`
///
/// Both pointer-advance conditions are strict (`< pivot` for `i`, `> pivot` for `j`), and the
/// swap-and-cross step can exchange two elements that are far apart in the array — exactly the
/// mechanism that makes ``LLQuickSort``/``QuickSort`` unstable too. Two equal-valued elements can
/// end up on opposite sides of a partition swap and cross each other's original relative order,
/// with nothing in the partition logic to prevent it (unlike an adjacent-only compare-swap pass).
public struct LRQuickSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "lrquicksort")
  public let metadata = AlgorithmMetadata(
    displayName: "LR Quick Sort",
    category: .exchange,
    sizeRange: 16...256,
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

  private func quickSort(_ engine: inout RecordingEngine, _ p: Int, _ r: Int) {
    guard p < r else { return }

    let pivotIndex = p + (r - p + 1) / 2
    // Held-value pattern (see the doc comment above): the pivot's own slot is never written to
    // during this partition, so one read up front stands in for every live comparison against
    // it below.
    let pivotValue = engine.values[pivotIndex]

    var i = p
    var j = r
    while i <= j {
      while engine.values[i] < pivotValue {
        i += 1
      }
      while engine.values[j] > pivotValue {
        j -= 1
      }
      if i <= j {
        engine.swap(i, j)
        i += 1
        j -= 1
      }
    }

    if p < j {
      quickSort(&engine, p, j)
    }
    if i < r {
      quickSort(&engine, i, r)
    }
  }
}
