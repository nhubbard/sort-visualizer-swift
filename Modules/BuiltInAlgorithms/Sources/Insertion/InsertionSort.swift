import AlgorithmKit
import SortEngineKit

public struct InsertionSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "insertionsort")
  public let metadata = AlgorithmMetadata(
    displayName: "Insertion Sort",
    category: .insertion,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 52, coefficients: [109542, 25833.7, 3109.11, 253.892, 15.7939, 0.797054],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .factorial, coefficients: [11.5232, 0.059686], rSquared: 0.999308),
    implementationComplexity: 5,
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
      var j = i
      while j > 0 && !engine.compare(j, j - 1) {
        engine.swap(j - 1, j)
        j -= 1
      }
    }
  }
}
