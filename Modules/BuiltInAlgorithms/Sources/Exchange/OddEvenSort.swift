import AlgorithmKit
import SortEngineKit

public struct OddEvenSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "oddevensort")
  public let metadata = AlgorithmMetadata(
    displayName: "Odd-Even Sort",
    category: .exchange,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 219, coefficients: [239793, 2190.03, 5.00077],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .polynomialIntercept, coefficients: [5.00077, -0.30601, 18.2392], rSquared: 1),
    implementationComplexity: 7,
    stable: true,
    timeComplexity: ComplexityBounds(best: "O(n)", average: "O(n^2)", worst: "O(n^2)"),
    spaceComplexity: "O(1)",
    iconName: "checkerboard.rectangle"
  )

  public init() {}

  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 1 else { return }

    var sorted = false
    while !sorted {
      sorted = true

      var i = 1
      while i < n - 1 {
        if engine.compare(i, i + 1, by: >) {
          engine.swap(i, i + 1)
          sorted = false
        }
        i += 2
      }

      i = 0
      while i < n - 1 {
        if engine.compare(i, i + 1, by: >) {
          engine.swap(i, i + 1)
          sorted = false
        }
        i += 2
      }
    }
  }
}
