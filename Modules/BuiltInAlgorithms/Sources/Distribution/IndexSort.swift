import Foundation
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
    displayName: String(localized: "Index Sort", bundle: .module),
    category: .distribution,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 5762, coefficients: [239964, 78.8994, 0.0064669],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .polynomialIntercept, coefficients: [0.0064669, 4.3748, 50.803], rSquared: 0.998893),
    implementationComplexity: 7,
    stable: false,
    timeComplexity: ComplexityBounds(best: "O(n)", average: "O(n)", worst: "O(n)"),
    spaceComplexity: "O(1)",
    iconName: "pin.fill"
  )

  public init() {}

  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 1 else { return }

    var minValue = engine.readValue(at: 0)
    for i in 1..<n {
      let candidate = engine.readValue(at: i)
      let newMinimum = candidate < minValue
      engine.annotateLastOperation(
        stageID: "minimumScan", decisionID: "indexsort.minimumScan",
        outcome: newMinimum ? "updateMinimum" : "keepMinimum",
        roles: ["candidate": .arrayIndex(i), "minimum": .value(minValue)],
        explanationKey: "indexsort.minimumScan",
        explanation: newMinimum
          ? String(localized: "This value is lower than the current minimum, so use it as the index offset.", bundle: .module)
          : String(localized: "The current minimum remains the offset for index placement.", bundle: .module))
      if newMinimum { minValue = engine.readValue(at: i) }
    }

    for i in 0..<n {
      var cmpCount = 0
      while engine.readValue(at: i) - minValue != i, cmpCount < n {
        let target = engine.readValue(at: i) - minValue
        engine.swap(i, target)
        engine.annotateLastOperation(
          stageID: "bucketExchange", decisionID: "indexsort.bucketExchange",
          outcome: "exchange", roles: ["left": .arrayIndex(i), "right": .arrayIndex(target)],
          explanationKey: "indexsort.bucketExchange",
          explanation: String(localized: "The value’s offset from the minimum identifies index \(target), so exchange it into place.", bundle: .module))
        cmpCount += 1
      }
      if cmpCount >= n - 1 { break }
    }
  }
}
