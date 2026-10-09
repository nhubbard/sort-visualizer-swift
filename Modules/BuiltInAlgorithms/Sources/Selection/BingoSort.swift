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
      anchorSize: 271, coefficients: [239758, 1765.49, 3.24996],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .polynomialIntercept, coefficients: [3.24996, 4.01626, -10.2321], rSquared: 1),
    implementationComplexity: 12,
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
    // `next`/`val` are held values, not live indices — same held-value-vs-array-value pattern
    // as CycleSort's cached `t`, so comparisons against them go through `engine.compareValue`
    // rather than `engine.compare` (which only supports index-vs-index).
    var next = engine.readValue(at: maximum)
    var i = maximum - 1
    while i >= 0 {
      if engine.teachingCompareValue(
        i, against: next,
        by: >,
        stageID: "BingoSort.nextDistinctValue",
        whenTrue: "This value is larger than the current next value, so choose a new distinct target.",
        whenFalse: "This value does not replace the next distinct target."
      ) {
        next = engine.readValue(at: i)
      }
      i -= 1
    }
    // Skip past any elements at the tail that already equal the true maximum — nothing to do
    // for them yet.
    while maximum > 0 && engine.teachingCompareValue(
      maximum, against: next, by: ==, stageID: "BingoSort.skipPlacedMaximum",
      whenTrue: "This tail item equals the current maximum, so leave it in its final position.",
      whenFalse: "This tail item differs from the maximum, so begin another placement round."
    ) {
      maximum -= 1
    }

    while maximum > 0 {
      let val = next
      next = engine.readValue(at: maximum)

      // `j`'s starting bound is fixed here, before any swaps in this pass can move
      // `maximum` — mirrors ArrayV's `for (int j = maximum - 1; j >= 0; j--)`, whose
      // initializer runs exactly once even though the loop body mutates `maximum`.
      var j = maximum - 1
      while j >= 0 {
        if engine.teachingCompareValue(
          j, against: val, by: ==, stageID: "BingoSort.placeCurrentValue",
          whenTrue: "This item matches the current bingo value, so place it at the right boundary.",
          whenFalse: "This item has a different value; check whether it becomes the next target."
        ) {
          engine.swap(j, maximum)
          maximum -= 1
        } else if engine.teachingCompareValue(
          j, against: next, by: >, stageID: "BingoSort.findNextValue",
          whenTrue: "This item is larger than the next target, so use it for the next bingo round.",
          whenFalse: "The next bingo target remains the better candidate."
        ) {
          next = engine.readValue(at: j)
        }
        j -= 1
      }
      while maximum > 0 && engine.teachingCompareValue(
        maximum, against: next, by: ==, stageID: "BingoSort.skipPlacedTail",
        whenTrue: "This tail item already matches the next target, so shrink the unsorted boundary.",
        whenFalse: "The remaining tail needs another bingo placement round."
      ) {
        maximum -= 1
      }
    }
  }
}
