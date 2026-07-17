import AlgorithmKit
import SortEngineKit

/// ArrayV's `OptimizedCocktailShakerSort.java` applies the same "shrink the bound by the length of
/// the trailing already-sorted run" trick as `OptimizedBubbleSort`
/// (`Modules/BuiltInAlgorithms/Sources/OptimizedBubbleSort.swift`), but bidirectionally: each
/// outer pass does a forward bubble sweep shrinking `end`, then a backward sweep shrinking
/// `start`, each tracking its own consecutive-no-swap counter independently.
public struct OptimizedCocktailShakerSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "optimizedcocktailshakersort")
  public let metadata = AlgorithmMetadata(
    displayName: "Optimized Cocktail Shaker Sort",
    category: .exchange,
    sizeRange: 16...256,
    stable: true,
    timeComplexity: ComplexityBounds(best: "O(n)", average: "O(n^2)", worst: "O(n^2)"),
    spaceComplexity: "O(1)",
    iconName: "arrow.left.arrow.right.circle.fill"
  )
  public init() {}

  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 1 else { return }

    var start = 0
    var end = n - 1
    while start < end {
      var consecSorted = 1
      var i = start
      while i < end {
        // Strict `>` (not the default `>=`): ties never trigger a swap, keeping the sort
        // stable, same as `OptimizedBubbleSort`/`CocktailShakerSort`.
        if engine.compare(i, i + 1, by: (>)) {
          engine.swap(i, i + 1)
          consecSorted = 1
        } else {
          consecSorted += 1
        }
        i += 1
      }
      end -= consecSorted

      consecSorted = 1
      var j = end
      while j > start {
        if engine.compare(j - 1, j, by: (>)) {
          engine.swap(j - 1, j)
          consecSorted = 1
        } else {
          consecSorted += 1
        }
        j -= 1
      }
      start += consecSorted
    }
  }
}
