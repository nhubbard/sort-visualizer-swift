import AlgorithmKit
import SortEngineKit

public struct TernaryHeapSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "ternaryheapsort")
  public let metadata = AlgorithmMetadata(
    displayName: "Ternary Heap Sort",
    category: .selection,
    sizeRange: 16...256,
    stable: false,
    timeComplexity: ComplexityBounds(
      best: "O(n log n)", average: "O(n log n)", worst: "O(n log n)"),
    spaceComplexity: "O(1)",
    iconName: "3.square.fill"
  )
  public init() {}

  /// Same extract-max heapsort shape as `MaxHeapSort`/`BaseNMaxHeapSort`, fixed at 3 children per
  /// node (`leftBranch/middleBranch/rightBranch = 3i+1/3i+2/3i+3`) rather than 2 or a runtime
  /// `base`. ArrayV's own `buildMaxTernaryHeap` starts its heapify loop at `length - 1 / 3`,
  /// which — due to Java's operator precedence (division binds before subtraction) — evaluates
  /// to `length - 0 = length`, one past the last valid index. That extra call is a provable
  /// no-op (every child-bound check inside `maxHeapify` short-circuits false before ever reading
  /// `array[length]`), so this starts the loop at the last real index instead of replicating the
  /// pointless call.
  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 1 else { return }

    var heapSize = n - 1

    func maxHeapify(_ i: Int) {
      let leftChild = 3 * i + 1
      let middleChild = 3 * i + 2
      let rightChild = 3 * i + 3

      var largest = i
      if leftChild <= heapSize, engine.compare(leftChild, largest, by: (>)) {
        largest = leftChild
      }
      if rightChild <= heapSize, engine.compare(rightChild, largest, by: (>)) {
        largest = rightChild
      }
      if middleChild <= heapSize, engine.compare(middleChild, largest, by: (>)) {
        largest = middleChild
      }

      if largest != i {
        engine.swap(i, largest)
        maxHeapify(largest)
      }
    }

    for i in stride(from: n - 1, through: 0, by: -1) {
      maxHeapify(i)
    }

    for i in stride(from: n - 1, through: 0, by: -1) {
      engine.swap(0, i)
      heapSize -= 1
      maxHeapify(0)
    }
  }
}
