import AlgorithmKit
import SortEngineKit

public struct ShellSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "shellsort")
  public let metadata = AlgorithmMetadata(
    displayName: "Shell Sort",
    category: .insertion,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 1374, coefficients: [239969, 298.068, 0.0895609],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .polynomialIntercept, coefficients: [0.0895609, 51.9549, -496.608], rSquared: 0.999886),
    implementationComplexity: 6,
    stable: false,
    timeComplexity: ComplexityBounds(
      best: "O(n log n)", average: "O(n^{1.25})", worst: "O(n^2)"),
    spaceComplexity: "O(1)",
    iconName: "shell"
  )

  public init() {}

  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    let gaps = [8861, 3938, 1750, 701, 301, 132, 57, 23, 10, 4, 1]

    for gap in gaps where gap < n {
      for i in gap..<n {
        var j = i
        while j >= gap && !engine.compare(j, j - gap) {
          engine.swap(j, j - gap)
          j -= gap
        }
      }
    }
  }
}
