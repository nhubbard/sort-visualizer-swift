import Foundation
import AlgorithmKit
import SortEngineKit

public struct UnoptimizedBubbleSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "unoptimizedbubblesort")
  public let metadata = AlgorithmMetadata(
    displayName: String(localized: "Unoptimized Bubble Sort", bundle: .module),
    category: .exchange,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 53, coefficients: [294461, 76818.7, 10202.7, 917.824, 62.8087, 3.48295],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .factorial, coefficients: [9.47655, 0.0657078], rSquared: 0.999103),
    implementationComplexity: 5,
    stable: true,
    timeComplexity: ComplexityBounds(best: "O(n)", average: "O(n^2)", worst: "O(n^2)"),
    spaceComplexity: "O(1)",
    iconName: "repeat"
  )
  public init() {}
  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 1 else { return }
    var sorted = false
    while !sorted {
      sorted = true
      for i in 0..<(n - 1) where engine.teachingCompare(
        i, i + 1,
        by: (>),
        stageID: "UnoptimizedBubbleSort.adjacentOrder",
        whenTrue: String(localized: "The left neighbor is larger, so exchange this pair.", bundle: .module),
        whenFalse: String(localized: "This adjacent pair needs no exchange.", bundle: .module)
      ) {
        engine.swap(i, i + 1)
        sorted = false
      }
    }
  }
}
