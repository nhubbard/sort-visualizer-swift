import AlgorithmKit
import SortEngineKit

public struct SelectionSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "selectionsort")
  public let metadata = AlgorithmMetadata(
    displayName: "Selection Sort",
    category: .selection,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 309, coefficients: [239470, 1547.5, 2.5],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .polynomialIntercept, coefficients: [2.5, 2.5, -5], rSquared: 1),
    implementationComplexity: 5,
    stable: false,
    timeComplexity: ComplexityBounds(best: "O(n^2)", average: "O(n^2)", worst: "O(n^2)"),
    spaceComplexity: "O(1)",
    iconName: "checkmark.circle"
  )
  public init() {}
  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 1 else { return }
    for i in 0..<(n - 1) {
      var lowestIndex = i
      for j in (i + 1)..<n where !engine.compare(j, lowestIndex) {
        lowestIndex = j
      }
      engine.swap(i, lowestIndex)
    }
  }
}
