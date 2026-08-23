import AlgorithmKit
import SortEngineKit

public struct MinHeapSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "minheapsort")
  public let metadata = AlgorithmMetadata(
    displayName: "Min Heap Sort",
    category: .selection,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 1373, coefficients: [214009, 191.071, 0.0146267],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .powerLog, coefficients: [11.4717, 1.08742], rSquared: 0.999419),
    stable: false,
    timeComplexity: ComplexityBounds(
      best: "O(n log n)", average: "O(n log n)", worst: "O(n log n)"),
    spaceComplexity: "O(1)",
    iconName: "square.stack.3d.down.right.fill"
  )
  public init() {}
  public func record(into engine: inout RecordingEngine) {
    let n = engine.count

    // Mirrors ArrayV's `HeapSorting.siftDown` with `isMax == false`: the same shape as
    // MaxHeapSort's sift-down, but the child comparison flips to `<=` so the *smallest* child
    // bubbles toward the root instead of the largest.
    func siftDown(_ root: Int, _ size: Int) {
      var root = root
      while true {
        var smallest = root
        let left = 2 * root + 1
        let right = 2 * root + 2
        if left < size && !engine.compare(smallest, left, by: (<=)) {
          smallest = left
        }
        if right < size && !engine.compare(smallest, right, by: (<=)) {
          smallest = right
        }
        if smallest == root { break }
        engine.swap(root, smallest)
        root = smallest
      }
    }

    var i = n / 2 - 1
    while i >= 0 {
      siftDown(i, n)
      i -= 1
    }
    var end = n - 1
    while end > 0 {
      engine.swap(0, end)
      siftDown(0, end)
      end -= 1
    }

    // ArrayV's `MinHeapSort` calls `heapSort(..., isMax: false)`, which repeatedly extracts the
    // *minimum* to the shrinking heap's back — that leaves the array in descending order, so
    // `HeapSorting.heapSort` finishes with `Writes.reversal` whenever `isMax` is false. Do the
    // same here to land on the required ascending result.
    engine.reversal(0, n - 1)
  }
}
