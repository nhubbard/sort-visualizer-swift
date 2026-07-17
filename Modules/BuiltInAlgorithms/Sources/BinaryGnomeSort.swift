import AlgorithmKit
import SortEngineKit

/// ArrayV's own display name is "Optimized Gnome Sort + Binary Search" and it files this under
/// `sorts/exchange/` (`setCategory("Exchange Sorts")`), but the algorithm ArrayV actually wrote is
/// not gnome sort's classic adjacent-compare-and-backstep walk at all — `runSort` binary-searches
/// the sorted prefix `[0, i)` for element `i`'s insertion point, then shifts it into place via
/// adjacent swaps. That is Binary Insertion Sort's own structure, verbatim (compare
/// `BinaryInsertionSort.swift`). This port is faithful to ArrayV's source and its `.exchange`
/// categorization even though the logic itself would otherwise be filed as `.insertion` — the name
/// and category are ArrayV's historical/nominal choice, not a claim that a distinct gnome-sort
/// mechanism is present here.
public struct BinaryGnomeSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "binarygnomesort")
  public let metadata = AlgorithmMetadata(
    displayName: "Binary Gnome Sort",
    category: .exchange,
    sizeRange: 16...256,
    stable: true,
    timeComplexity: ComplexityBounds(best: "O(n)", average: "O(n^2)", worst: "O(n^2)"),
    spaceComplexity: "O(1)",
    iconName: "figure.walk.motion"
  )
  public init() {}

  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 1 else { return }

    for i in 1..<n {
      // Binary search for the insertion point of the element held at `i` within
      // the already-sorted run [0, i). The element at `i` is never overwritten
      // during the search, so comparing against index `i` directly (instead of
      // caching its value) is safe.
      var lo = 0
      var hi = i

      while lo < hi {
        let mid = lo + (hi - lo) / 2  // avoid overflow

        // Do NOT move equal elements to the right of the inserted element;
        // this maintains stability.
        if engine.compare(i, mid, by: <) {
          hi = mid
        } else {
          lo = mid + 1
        }
      }

      // The element belongs at index `lo`. Shift the run [lo, i) one slot to the
      // right by walking the held element down via adjacent swaps, matching this
      // codebase's swap-based shift convention (see InsertionSort.swift).
      var j = i
      while j > lo {
        engine.swap(j, j - 1)
        j -= 1
      }
    }
  }
}
