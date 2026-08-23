import AlgorithmKit
import SortEngineKit

/// Despite the name and ArrayV's `.exchange` categorization, this isn't gnome sort's classic
/// adjacent-compare-and-backstep walk — it binary-searches the sorted prefix `[0, i)` for each
/// element's insertion point, then shifts it into place via adjacent swaps, i.e. Binary Insertion
/// Sort's structure verbatim (compare `BinaryInsertionSort.swift`). Kept as `.exchange` to match
/// ArrayV's own categorization.
public struct BinaryGnomeSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "binarygnomesort")
  public let metadata = AlgorithmMetadata(
    displayName: "Binary Gnome Sort",
    category: .exchange,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 303, coefficients: [239852, 1559, 2.5301],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .polynomialIntercept, coefficients: [2.5301, 25.7589, -238.373], rSquared: 1),
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
