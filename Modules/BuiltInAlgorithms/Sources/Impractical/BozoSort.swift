import AlgorithmKit
import SortEngineKit

public struct BozoSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "bozosort")
  public let metadata = AlgorithmMetadata(
    displayName: "Bozo Sort",
    category: .impractical,
    sizeRange: 4...7,
    growthModel: OperationGrowthModel(
      anchorSize: 7, coefficients: [64090.2, 134423, 145904, 108671, 62245.2, 29163],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .factorial, coefficients: [50.9678, 1.07785], rSquared: 0.995758),
    implementationComplexity: 11,
    stable: false,
    timeComplexity: ComplexityBounds(
      best: "O(n)", average: "O(n \\times n!)", worst: "O(n \\times n!)"),
    spaceComplexity: "O(1)",
    iconName: "arrow.triangle.swap"
  )
  public init() {}

  /// Classic Bozo Sort swaps two random elements and checks; like `BogoSort`, an open-ended
  /// random walk risks an unbounded pre-recorded tape. Heap's algorithm keeps the "one swap, then
  /// check" shape but makes it deterministic — it visits every permutation exactly once, reaching
  /// each via exactly one swap from the last, giving a hard n!-step ceiling with no repeats.
  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 1 else { return }

    func isSorted() -> Bool {
      for i in 1..<n {
        let inOrder = engine.compare(i, i - 1)
        engine.annotateLastOperation(
          stageID: "sortednessCheck", decisionID: "bozosort.adjacentOrder",
          outcome: inOrder ? "continue" : "reject",
          roles: ["previous": .arrayIndex(i - 1), "current": .arrayIndex(i)],
          explanationKey: "bozosort.adjacentOrder",
          explanation: inOrder
            ? "This adjacent pair is ordered, so keep checking the candidate."
            : "This adjacent pair is inverted, so reject this candidate permutation.")
        if !inOrder { return false }
      }
      return true
    }

    var done = false

    func heap(_ k: Int) {
      guard !done else { return }
      if k == 1 {
        if isSorted() { done = true }
        return
      }
      for i in 0..<(k - 1) {
        heap(k - 1)
        guard !done else { return }
        engine.swap(k.isMultiple(of: 2) ? i : 0, k - 1)
        engine.annotateLastOperation(
          stageID: "candidateExchange", decisionID: "bozosort.candidateExchange",
          outcome: "exchange", roles: ["left": .arrayIndex(k.isMultiple(of: 2) ? i : 0), "right": .arrayIndex(k - 1)],
          explanationKey: "bozosort.candidateExchange",
          explanation: "Heap’s permutation step exchanges these positions before the next sortedness check.")
      }
      heap(k - 1)
    }

    heap(n)
  }
}
