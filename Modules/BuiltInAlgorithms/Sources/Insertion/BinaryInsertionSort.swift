import AlgorithmKit
import SortEngineKit

public struct BinaryInsertionSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "binaryinsertionsort")
  public let metadata = AlgorithmMetadata(
    displayName: "Binary Insertion Sort",
    category: .insertion,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 303, coefficients: [239852, 1559, 2.5301],
      measuredSafeCeiling: nil),
    stable: true,
    timeComplexity: ComplexityBounds(best: "O(n)", average: "O(n^2)", worst: "O(n^2)"),
    spaceComplexity: "O(1)",
    iconName: "text.insert"
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
