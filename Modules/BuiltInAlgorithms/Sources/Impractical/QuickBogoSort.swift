import AlgorithmKit
import SortEngineKit

public struct QuickBogoSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "quickbogosort")
  public let metadata = AlgorithmMetadata(
    displayName: "Quick Bogo Sort",
    category: .impractical,
    sizeRange: 4...6,
    growthModel: OperationGrowthModel(
      anchorSize: 7, coefficients: [39557.6, 74867.8, 73596.8, 49767.1, 25927.8, 11064.6],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .factorial, coefficients: [63.1451, 0.97262], rSquared: 0.947576),
    implementationComplexity: 22,
    stable: false,
    timeComplexity: ComplexityBounds(
      best: "O(n)", average: "O(n \\times n!)", worst: "O(n \\times n!)"),
    spaceComplexity: "O(log n)",
    iconName: "questionmark.square.fill"
  )
  public init() {}

  /// ArrayV's `QuickBogoSort` picks the first element as pivot and reshuffles the range until it
  /// happens to be partitioned around it — the same open-ended random walk `BogoSort` fixed.
  /// Substitutes a lexicographic `nextPermutation` walk (as `LessBogoSort`/`CocktailBogoSort` use),
  /// tracking the pivot's position through each step's swap and reversal.
  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 1 else { return }

    func isRangePartitioned(_ start: Int, _ pivot: Int, _ end: Int) -> Bool {
      for i in start..<pivot {
        let leftIsLarger = engine.compare(i, pivot, by: (>))
        engine.annotateLastOperation(
          stageID: "partitionCheck", decisionID: "quickbogosort.leftOfPivot",
          outcome: leftIsLarger ? "reject" : "continue",
          roles: ["candidate": .arrayIndex(i), "pivot": .arrayIndex(pivot)],
          explanationKey: "quickbogosort.leftOfPivot",
          explanation: leftIsLarger
            ? "A value left of the pivot is larger, so this candidate partition fails."
            : "This left-side value does not exceed the pivot, so keep checking.")
        if leftIsLarger { return false }
      }
      for i in (pivot + 1)..<end {
        let pivotIsLarger = engine.compare(pivot, i, by: (>))
        engine.annotateLastOperation(
          stageID: "partitionCheck", decisionID: "quickbogosort.rightOfPivot",
          outcome: pivotIsLarger ? "reject" : "continue",
          roles: ["pivot": .arrayIndex(pivot), "candidate": .arrayIndex(i)],
          explanationKey: "quickbogosort.rightOfPivot",
          explanation: pivotIsLarger
            ? "A value right of the pivot is smaller, so this candidate partition fails."
            : "This right-side value is no smaller than the pivot, so keep checking.")
        if pivotIsLarger { return false }
      }
      return true
    }

    func quickBogo(_ start: Int, _ end: Int) {
      guard start < end - 1 else { return }
      var pivot = start

      func trackedSwap(_ i: Int, _ j: Int) {
        engine.swap(i, j)
        engine.annotateLastOperation(
          stageID: "candidateExchange", decisionID: "quickbogosort.candidateExchange",
          outcome: "exchange", roles: ["left": .arrayIndex(i), "right": .arrayIndex(j)],
          explanationKey: "quickbogosort.candidateExchange",
          explanation: "The next candidate permutation exchanges its pivot with a successor while tracking the partition pivot.")
        if pivot == i { pivot = j } else if pivot == j { pivot = i }
      }

      func trackedReversal(_ lo: Int, _ hi: Int) {
        engine.reversal(lo, hi)
        engine.annotateLastOperation(
          stageID: "candidateWrap", decisionID: "quickbogosort.reverseSuffix",
          outcome: "reverse", roles: ["first": .arrayIndex(lo), "last": .arrayIndex(hi)],
          explanationKey: "quickbogosort.reverseSuffix",
          explanation: "Reverse this descending range to advance the candidate permutation.")
        if pivot >= lo, pivot <= hi { pivot = lo + hi - pivot }
      }

      func nextPermutation() -> Bool {
        var i = end - 2
        while i >= start, engine.compare(i, i + 1) { i -= 1 }
        guard i >= start else { return false }
        var j = end - 1
        while !engine.compare(j, i, by: (>)) { j -= 1 }
        trackedSwap(i, j)
        trackedReversal(i + 1, end - 1)
        return true
      }

      while !isRangePartitioned(start, pivot, end) {
        if !nextPermutation() {
          trackedReversal(start, end - 1)
        }
      }

      quickBogo(start, pivot)
      quickBogo(pivot + 1, end)
    }

    quickBogo(0, n)
  }
}
