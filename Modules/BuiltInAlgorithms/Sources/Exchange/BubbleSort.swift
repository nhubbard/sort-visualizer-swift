import AlgorithmKit
import SortEngineKit

public struct BubbleSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "bubblesort")
  public let metadata = AlgorithmMetadata(
    displayName: "Bubble Sort",
    category: .exchange,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 219, coefficients: [238708, 2185, 5],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .polynomialIntercept, coefficients: [5, -5, -2], rSquared: 1),
    implementationComplexity: 5,
    stable: true,
    timeComplexity: ComplexityBounds(best: "O(n^2)", average: "O(n^2)", worst: "O(n^2)"),
    spaceComplexity: "O(1)",
    iconName: "circle.grid.2x2.fill"
  )
  public init() {}
  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 1 else { return }
    for i in 1..<n {
      for j in 0..<(n - i) where engine.teachingCompare(
        j, j + 1,
        by: >,
        stageID: "BubbleSort.adjacentOrder",
        whenTrue: "The left neighbor is larger, so swap this adjacent pair.",
        whenFalse: "This adjacent pair is already in order."
      ) {
        engine.swap(j, j + 1)
      }
    }
  }
}
