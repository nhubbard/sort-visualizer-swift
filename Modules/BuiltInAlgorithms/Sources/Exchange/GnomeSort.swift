import AlgorithmKit
import SortEngineKit

public struct GnomeSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "gnomesort")
  public let metadata = AlgorithmMetadata(
    displayName: "Gnome Sort",
    category: .exchange,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 179, coefficients: [238965, 2677.5, 7.5],
      measuredSafeCeiling: nil),
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
      if engine.compare(i, i - 1) {
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
