import AlgorithmKit
import SortEngineKit

public struct MaxHeapSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "maxheapsort")
  public let metadata = AlgorithmMetadata(
    displayName: "Max Heap Sort",
    category: .selection,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 1361, coefficients: [213492, 194.876, 0.0162418],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .powerLog, coefficients: [10.283, 1.10374], rSquared: 0.998829),
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
        if left < size && !engine.compare(largest, left) {
          largest = left
        }
        if right < size && !engine.compare(largest, right) {
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
      siftDown(0, end)
      end -= 1
    }
  }
}
