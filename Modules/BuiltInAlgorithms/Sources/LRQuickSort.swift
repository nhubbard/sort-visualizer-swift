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
