import AlgorithmKit
import SortEngineKit

public struct OptimizedBubbleSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "optimizedbubblesort")
  public let metadata = AlgorithmMetadata(
    displayName: "Optimized Bubble Sort",
    category: .exchange,
    sizeRange: 16...256,
    stable: true,
    timeComplexity: ComplexityBounds(best: "O(n)", average: "O(n^2)", worst: "O(n^2)"),
    spaceComplexity: "O(1)",
    iconName: "hare.fill"
  )
  public init() {}
  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 1 else { return }
    var i = n - 1
    while i > 0 {
      var consecSorted = 1
      for j in 0..<i {
        if engine.compare(j, j + 1, by: (>)) {
          engine.swap(j, j + 1)
          consecSorted = 1
        } else {
          consecSorted += 1
        }
      }
      i -= consecSorted
    }
  }
}
