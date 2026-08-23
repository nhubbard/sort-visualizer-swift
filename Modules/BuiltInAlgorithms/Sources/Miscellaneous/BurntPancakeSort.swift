import AlgorithmKit
import SortEngineKit

public struct BurntPancakeSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "burntpancakesort")
  public let metadata = AlgorithmMetadata(
    displayName: "Burnt Pancake Sort",
    category: .miscellaneous,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 184, coefficients: [239094, 2629.98, 7.23954],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .polynomialIntercept, coefficients: [7.23954, -34.1724, 279.982], rSquared: 0.999995),
    stable: false,
    timeComplexity: ComplexityBounds(best: "O(n^2)", average: "O(n^2)", worst: "O(n^2)"),
    spaceComplexity: "O(1)",
    iconName: "flame"
  )

  public init() {}

  public func record(into engine: inout RecordingEngine) {
    let n = engine.count

    func flip(_ end: Int) {
      engine.reversal(0, end)
    }

    var i = n - 1
    while i > 0 {
      var max = 0
      var j = max + 1
      while j <= i {
        if engine.compare(j, max) {
          max = j
        }
        j += 1
      }
      if max != i {
        flip(max)
        flip(i)
        flip(i - 1)
        flip(max - 1)
      }
      i -= 1
    }
  }
}
