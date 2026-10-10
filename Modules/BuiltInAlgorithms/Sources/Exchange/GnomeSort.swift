import Foundation
import AlgorithmKit
import SortEngineKit

public struct GnomeSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "gnomesort")
  public let metadata = AlgorithmMetadata(
    displayName: String(localized: "Gnome Sort", bundle: .module),
    category: .exchange,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 49, coefficients: [101588, 25866.7, 3360.94, 296.308, 19.9002, 1.08428],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .factorial, coefficients: [9.56395, 0.0654251], rSquared: 0.999114),
    implementationComplexity: 4,
    stable: true,
    timeComplexity: ComplexityBounds(best: "O(n)", average: "O(n^2)", worst: "O(n^2)"),
    spaceComplexity: "O(1)",
    iconName: "figure.walk"
  )
  public init() {}
  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    var i = 1
    while i < n {
      if engine.teachingCompare(
        i, i - 1,
        stageID: "GnomeSort.backtrack",
        whenTrue: String(localized: "The current item is ordered after its neighbor, so advance.", bundle: .module),
        whenFalse: String(localized: "The current item belongs before its neighbor, so swap and step back.", bundle: .module)
      ) {
        i += 1
      } else {
        engine.swap(i, i - 1)
        if i > 1 {
          i -= 1
        }
      }
    }
  }
}
