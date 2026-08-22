import AlgorithmKit
import SortEngineKit

public struct SelectionBogoSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "selectionbogosort")
  public let metadata = AlgorithmMetadata(
    displayName: "Selection Bogo Sort",
    category: .impractical,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 309, coefficients: [239234, 1547.02, 2.50054],
      measuredSafeCeiling: nil),
    stable: false,
    timeComplexity: ComplexityBounds(best: "O(n^2)", average: "O(n^2)", worst: "O(n^2)"),
    spaceComplexity: "O(1)",
    iconName: "checkmark.diamond.fill"
  )
  public init() {}

  /// ArrayV's `SelectionBogoSort`, despite the name, doesn't actually bogo-sort: the range's true
  /// minimum is always at some index in `[i, n)`, so one deterministic scan finds it and a single
  /// swap places it — plain selection sort's inner loop, hence the much larger `sizeRange` than a
  /// typical bogo variant.
  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 1 else { return }

    for i in 0..<n {
      var minIndex = i
      for j in (i + 1)..<n where engine.compare(minIndex, j, by: (>)) {
        minIndex = j
      }
      if minIndex != i {
        engine.swap(i, minIndex)
      }
    }
  }
}
