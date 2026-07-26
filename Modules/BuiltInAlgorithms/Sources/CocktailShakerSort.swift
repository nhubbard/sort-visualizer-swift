import AlgorithmKit
import SortEngineKit

public struct CocktailShakerSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "cocktailshakersort")
  public let metadata = AlgorithmMetadata(
    displayName: "Cocktail Shaker Sort",
    category: .exchange,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 219, coefficients: [239258, 2187.5, 4.99995],
      measuredSafeCeiling: nil),
    stable: true,
    timeComplexity: ComplexityBounds(best: "O(n)", average: "O(n^2)", worst: "O(n^2)"),
    spaceComplexity: "O(1)",
    iconName: "arrow.left.arrow.right"
  )
  public init() {}

  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 1 else { return }

    var i = 0
    while i < n / 2 {
      var sorted = true

      // Strict `>`/`<` (not the default `>=`) — ArrayV's `Reads.compareValues(...) == 1`/
      // `== -1` never swaps on a tie, which is what actually makes this stable: swapping two
      // equal-valued adjacent elements wouldn't affect sortedness, but it would needlessly
      // flip their relative order.
      var j = i
      while j < n - i - 1 {
        if engine.compare(j, j + 1, by: (>)) {
          engine.swap(j, j + 1)
          sorted = false
        }
        j += 1
      }

      j = n - i - 1
      while j > i {
        if engine.compare(j - 1, j, by: (>)) {
          engine.swap(j - 1, j)
          sorted = false
        }
        j -= 1
      }

      if sorted { break }
      i += 1
    }
  }
}
