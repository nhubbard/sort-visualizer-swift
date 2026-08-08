import AlgorithmKit
import SortEngineKit

/// A Selection Sort variant that targets the current maximum *value* rather than a single index:
/// each round swaps every element equal to that value into the shrinking tail in one pass, while
/// tracking the next-highest value seen for the following round. This clears all tied duplicates
/// per pass instead of one per pass, which is why it beats plain Selection Sort when values repeat
/// (`O(n+m^2)` best case, `O(n*m)` otherwise, where `m` is the count of distinct values).
public struct BingoSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "bingosort")
  public let metadata = AlgorithmMetadata(
    displayName: "Bingo Sort",
    category: .selection,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 7700, coefficients: [239958, 58.86, 0.00359711],
      measuredSafeCeiling: nil),
    stable: false,
    timeComplexity: ComplexityBounds(
      best: "O(n+m^2)", average: "O(n \\times m)", worst: "O(n \\times m)"),
    spaceComplexity: "O(1)",
    iconName: "target"
  )
  public init() {}

  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 1 else { return }

    var maximum = n - 1
    // `next` is a held value, not a live index — same held-value-vs-array-value pattern as
    // CycleSort's cached `t`, so this reads `engine.values` directly instead of going through
    // `engine.compare` (which only supports index-vs-index comparisons).
    var next = engine.values[maximum]
    var i = maximum - 1
    while i >= 0 {
      if engine.values[i] > next {
        next = engine.values[i]
      }
      i -= 1
    }
    // Skip past any elements at the tail that already equal the true maximum — nothing to do
    // for them yet.
    while maximum > 0 && engine.values[maximum] == next {
      maximum -= 1
    }

    while maximum > 0 {
      let val = next
      next = engine.values[maximum]

      // `j`'s starting bound is fixed here, before any swaps in this pass can move
      // `maximum` — mirrors ArrayV's `for (int j = maximum - 1; j >= 0; j--)`, whose
      // initializer runs exactly once even though the loop body mutates `maximum`.
      var j = maximum - 1
      while j >= 0 {
        // Held-value equality against the local `val` — ArrayV routes this one through
        // `Reads.compareValues` for its own stat tracking, but `val` is still a local, not
        // a live index, so the held-value pattern applies regardless: read directly.
        if engine.values[j] == val {
          engine.swap(j, maximum)
          maximum -= 1
        } else if engine.values[j] > next {
          next = engine.values[j]
        }
        j -= 1
      }
      while maximum > 0 && engine.values[maximum] == next {
        maximum -= 1
      }
    }
  }
}
