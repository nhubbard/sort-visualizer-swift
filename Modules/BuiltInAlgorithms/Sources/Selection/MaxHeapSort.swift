import AlgorithmKit
import SortEngineKit

public struct MaxHeapSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "maxheapsort")
  public let metadata = AlgorithmMetadata(
    displayName: "Max Heap Sort",
    category: .selection,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 1353, coefficients: [213817, 196.502, 0.0165542],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .powerLog, coefficients: [10.2998, 1.10474], rSquared: 0.998267),
    implementationComplexity: 10,
    stable: false,
    timeComplexity: ComplexityBounds(
      best: "O(n log n)", average: "O(n log n)", worst: "O(n log n)"),
    spaceComplexity: "O(1)",
    iconName: "square.stack.3d.up.fill"
  )
  public init() {}
  public func record(into engine: inout RecordingEngine) {
    let n = engine.count

    func siftDown(_ root: Int, _ size: Int) {
      var root = root
      while true {
        var largest = root
        let left = 2 * root + 1
        let right = 2 * root + 2
        if left < size && !engine.teachingCompare(
          largest, left,
          stageID: "MaxHeapSort.leftChild",
          whenTrue: "The left child is no larger, so keep the current heap maximum.",
          whenFalse: "The left child is larger, so promote it as heap maximum."
        ) {
          largest = left
        }
        if right < size && !engine.teachingCompare(
          largest, right, stageID: "MaxHeapSort.rightChild",
          whenTrue: "The current candidate is at least the right child, so keep it.",
          whenFalse: "The right child is larger, so promote it as heap maximum."
        ) {
          largest = right
        }
        if largest == root { break }
        engine.swap(root, largest)
        root = largest
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
      if engine.shouldAnnotateCurrentOperation {
        engine.annotateLastOperation(
          stageID: "MaxHeapSort.extractMaximum", outcome: "placed",
          roles: ["heapRoot": .arrayIndex(0), "sortedEnd": .arrayIndex(end)],
          explanationKey: "MaxHeapSort.extractMaximum",
          explanation: "Exchange the heap maximum with the end of the unsorted range.")
      }
      siftDown(0, end)
      end -= 1
    }
  }
}
