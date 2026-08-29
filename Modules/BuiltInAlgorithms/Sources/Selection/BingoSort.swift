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
      anchorSize: 218, coefficients: [238671, 2184.84, 4.99964],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .polynomialIntercept, coefficients: [0.00359711, 3.4646, 8.34021], rSquared: 0.996179),
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
    var next = engine.values[maximum]
    var i = maximum - 1
    while i >= 0 {
      if engine.compareValue(i, against: next, by: >) {
        next = engine.values[i]
      }
      i -= 1
    }
    // Skip past any elements at the tail that already equal the true maximum — nothing to do
    // for them yet.
    while maximum > 0 && engine.compareValue(maximum, against: next, by: ==) {
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
        if engine.compareValue(j, against: val, by: ==) {
          engine.swap(j, maximum)
          maximum -= 1
        } else if engine.compareValue(j, against: next, by: >) {
          next = engine.values[j]
        }
        j -= 1
      }
      while maximum > 0 && engine.compareValue(maximum, against: next, by: ==) {
        maximum -= 1
      }
    }
  }
}
