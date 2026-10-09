import AlgorithmKit
import SortEngineKit

public struct CocktailBogoSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "cocktailbogosort")
  public let metadata = AlgorithmMetadata(
    displayName: "Cocktail Bogo Sort",
    category: .impractical,
    sizeRange: 4...7,
    growthModel: OperationGrowthModel(
      anchorSize: 7, coefficients: [261.641, 34.196],
      measuredSafeCeiling: 7),
    detectedGrowthModel: DetectedGrowthModel(
      family: .powerLaw, coefficients: [44.1097, 0.914889], rSquared: 0.999948),
    implementationComplexity: 16,
    stable: false,
    timeComplexity: ComplexityBounds(
      best: "O(n)", average: "O(n \\times n!)", worst: "O(n \\times n!)"),
    spaceComplexity: "O(1)",
    iconName: "die.face.2.fill"
  )
  public init() {}

  /// ArrayV's `CocktailBogoSort` is `LessBogoSort` made bidirectional: tracks a shrinking
  /// `[min, max)` window, advancing `min` when the front is already the window's minimum,
  /// retreating `max` when the back is already its maximum, otherwise reshuffling and retrying.
  ///
  /// Ported here as a deterministic substitute: reshuffling becomes stepping to the window's next
  /// lexicographic permutation. The window's fully ascending arrangement always satisfies both
  /// stopping conditions, so this can never run out of permutations before one is met.
  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 1 else { return }

    func isFrontMinimum(_ start: Int, _ end: Int) -> Bool {
      for i in (start + 1)..<end {
        let frontIsLarger = engine.compare(start, i, by: (>))
        engine.annotateLastOperation(
          stageID: "candidateCheck", decisionID: "cocktailbogosort.frontMinimum",
          outcome: frontIsLarger ? "reject" : "continue",
          roles: ["front": .arrayIndex(start), "candidate": .arrayIndex(i)],
          explanationKey: "cocktailbogosort.frontMinimum",
          explanation: frontIsLarger
            ? "A smaller value exists in this window, so the front is not its minimum."
            : "The front is no larger than this value, so continue checking the window.")
        if frontIsLarger { return false }
      }
      return true
    }

    func isBackMaximum(_ start: Int, _ end: Int) -> Bool {
      for i in start..<(end - 1) {
        let earlierIsLarger = engine.compare(i, end - 1, by: (>))
        engine.annotateLastOperation(
          stageID: "candidateCheck", decisionID: "cocktailbogosort.backMaximum",
          outcome: earlierIsLarger ? "reject" : "continue",
          roles: ["candidate": .arrayIndex(i), "back": .arrayIndex(end - 1)],
          explanationKey: "cocktailbogosort.backMaximum",
          explanation: earlierIsLarger
            ? "A larger value exists in this window, so the back is not its maximum."
            : "The back is no smaller than this value, so continue checking the window.")
        if earlierIsLarger { return false }
      }
      return true
    }

    /// Lexicographic next permutation of the half-open range `[start, end)` — identical in
    /// shape to `LessBogoSort`'s helper of the same name, just duplicated here rather than
    /// shared since every ported algorithm in this module is self-contained.
    func nextPermutation(_ start: Int, _ end: Int) -> Bool {
      var i = end - 2
      while i >= start, engine.compare(i, i + 1) { i -= 1 }
      guard i >= start else { return false }

      var j = end - 1
      while !engine.compare(j, i, by: (>)) { j -= 1 }

      engine.swap(i, j)
      engine.annotateLastOperation(
        stageID: "candidateExchange", decisionID: "cocktailbogosort.candidateExchange",
        outcome: "exchange", roles: ["left": .arrayIndex(i), "right": .arrayIndex(j)],
        explanationKey: "cocktailbogosort.candidateExchange",
        explanation: "The next permutation exchanges a pivot and successor within the active range.")
      engine.reversal(i + 1, end - 1)
      engine.annotateLastOperation(
        stageID: "candidateWrap", decisionID: "cocktailbogosort.reverseSuffix",
        outcome: "reverse",
        roles: ["first": .arrayIndex(i + 1), "last": .arrayIndex(end - 1)],
        explanationKey: "cocktailbogosort.reverseSuffix",
        explanation: "Reverse this descending range to advance to the next candidate permutation.")
      return true
    }

    var minIndex = 0
    var maxIndex = n

    while minIndex < maxIndex - 1 {
      if isFrontMinimum(minIndex, maxIndex) {
        minIndex += 1
        continue
      }
      if isBackMaximum(minIndex, maxIndex) {
        maxIndex -= 1
        continue
      }
      if !nextPermutation(minIndex, maxIndex) {
        engine.reversal(minIndex, maxIndex - 1)
        engine.annotateLastOperation(
          stageID: "candidateWrap", decisionID: "cocktailbogosort.reverseSuffix",
          outcome: "reverse",
          roles: ["first": .arrayIndex(minIndex), "last": .arrayIndex(maxIndex - 1)],
          explanationKey: "cocktailbogosort.reverseSuffix",
          explanation: "Reverse this descending range to advance to the next candidate permutation.")
      }
    }
  }
}
