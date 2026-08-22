import AlgorithmKit
import SortEngineKit

/// A direct-placement "sort" that only works because this app's arrays are always a permutation
/// of `min...(min + n - 1)` (`SortSession`'s identity array) — a value tells you exactly which
/// index it belongs at, so there's nothing to compare. For each position `i`, keep swapping
/// whatever's currently there into its own `value - min` slot until `i` itself holds a value
/// equal to its own index. Every swap seats at least one element in its final home for good (the
/// value that used to occupy the target slot is exactly the value `i` needs), so the whole array
/// settles in at most `n - 1` swaps total, not per position — the `cmpCount` guard below exists
/// only to stop early once every remaining position is already correct, matching ArrayV's own
/// early-exit rather than because more than `n - 1` total swaps could ever be needed.
public struct IndexSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "indexsort")
  public let metadata = AlgorithmMetadata(
    displayName: "Index Sort",
    category: .distribution,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 225, coefficients: [239388, 3451.44, 17.2112, 0.0317196],
      measuredSafeCeiling: nil),
    stable: false,
    timeComplexity: ComplexityBounds(best: "O(n)", average: "O(n)", worst: "O(n)"),
    spaceComplexity: "O(1)",
    iconName: "pin.fill"
  )

  public init() {}

  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 1 else { return }

    var minValue = engine.values[0]
    for i in 1..<n where engine.values[i] < minValue {
      minValue = engine.values[i]
    }

    for i in 0..<n {
      var cmpCount = 0
      while engine.values[i] - minValue != i, cmpCount < n {
        engine.swap(i, engine.values[i] - minValue)
        cmpCount += 1
      }
      if cmpCount >= n - 1 { break }
    }
  }
}
