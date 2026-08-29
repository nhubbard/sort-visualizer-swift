import AlgorithmKit
import SortEngineKit

public struct PancakeSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "pancakesort")
  public let metadata = AlgorithmMetadata(
    displayName: "Pancake Sort",
    category: .miscellaneous,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 228, coefficients: [238503, 2093.78, 4.5946],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .polynomialIntercept, coefficients: [4.5946, -1.35518, -33.802], rSquared: 1),
    implementationComplexity: 7,
    stable: false,
    timeComplexity: ComplexityBounds(best: "O(n^2)", average: "O(n^2)", worst: "O(n^2)"),
    spaceComplexity: "O(1)",
    iconName: "circle.grid.3x3.fill"
  )
  public init() {}
  public func record(into engine: inout RecordingEngine) {
    let n = engine.count

    func flip(_ end: Int) {
      engine.reversal(0, end)
    }

    func findMaxIndex(_ end: Int) -> Int {
      var maxIndex = 0
      var i = 1
      while i <= end {
        if !engine.compare(maxIndex, i) {
          maxIndex = i
        }
        i += 1
      }
      return maxIndex
    }

    var currentSize = n - 1
    while currentSize > 0 {
      let maxIndex = findMaxIndex(currentSize)
      if maxIndex != currentSize {
        flip(maxIndex)
        flip(currentSize)
      }
      currentSize -= 1
    }
  }
}
