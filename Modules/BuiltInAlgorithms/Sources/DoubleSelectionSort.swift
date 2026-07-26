import AlgorithmKit
import SortEngineKit

/// ArrayV's `DoubleSelectionSort` — like plain Selection Sort, but each pass scans the unsorted
/// range `[left, right]` once for BOTH the minimum and maximum, placing the minimum at `left` and
/// the maximum at `right` in the same pass, roughly halving the number of passes.
///
/// `smallest`/`biggest` are live indices, so the two swaps must be sequenced with care: if the
/// largest element sits at `left` itself, the first swap (`left`/`smallest`) would relocate it, so
/// `biggest` is redirected to `smallest` before that swap runs. No analogous guard is needed for
/// `smallest == right` — the first swap only ever touches `left`/`smallest`, so `biggest`'s slot is
/// unaffected unless `biggest` already equals one of those two indices, in which case the second
/// swap is a harmless no-op.
public struct DoubleSelectionSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "doubleselectionsort")
  public let metadata = AlgorithmMetadata(
    displayName: "Double Selection Sort",
    category: .selection,
    sizeRange: 16...256,
    stable: false,
    timeComplexity: ComplexityBounds(best: "O(n^2)", average: "O(n^2)", worst: "O(n^2)"),
    spaceComplexity: "O(1)",
    iconName: "arrow.left.and.right.circle.fill"
  )
  public init() {}

  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 1 else { return }

    var left = 0
    var right = n - 1
    var smallest = 0
    var biggest = 0

    while left <= right {
      for i in left...right {
        // Reads.compareValues(array[i], array[biggest]) == 1 — strict greater-than,
        // both live indices.
        if engine.compare(i, biggest, by: (>)) {
          biggest = i
        }
        // Reads.compareValues(array[i], array[smallest]) == -1 — strict less-than,
        // both live indices.
        if engine.compare(i, smallest, by: (<)) {
          smallest = i
        }
      }
      if biggest == left {
        biggest = smallest
      }

      engine.swap(left, smallest)
      engine.swap(right, biggest)

      left += 1
      right -= 1

      smallest = left
      biggest = right
    }
  }
}
