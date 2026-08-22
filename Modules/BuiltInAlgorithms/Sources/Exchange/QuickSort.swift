import AlgorithmKit
import SortEngineKit

public struct QuickSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "quicksort")
  public let metadata = AlgorithmMetadata(
    displayName: "Quick Sort",
    category: .exchange,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 306, coefficients: [239425, 1547.5, 2.5],
      measuredSafeCeiling: nil),
    stable: false,
    timeComplexity: ComplexityBounds(
      best: "O(n log n)", average: "O(n log n)", worst: "O(n^2)"),
    spaceComplexity: "O(n)",
    iconName: "bolt.fill"
  )

  public init() {}

  public func record(into engine: inout RecordingEngine) {
    guard engine.count > 1 else { return }
    quickSort(&engine, 0, engine.count - 1)
  }

  private func quickSort(_ engine: inout RecordingEngine, _ left: Int, _ right: Int) {
    guard left < right else { return }
    let pivot = left
    var i = left
    var j = right
    while i < j {
      while engine.compare(pivot, i) && i < j {
        i += 1
      }
      while !engine.compare(pivot, j) {
        j -= 1
      }
      if i < j {
        engine.swap(i, j)
      }
    }
    engine.swap(pivot, j)
    quickSort(&engine, left, j - 1)
    quickSort(&engine, j + 1, right)
  }
}
