import Foundation
import AlgorithmKit
import SortEngineKit

public struct LessBogoSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "lessbogosort")
  public let metadata = AlgorithmMetadata(
    displayName: String(localized: "Less Bogo Sort", bundle: .module),
    category: .impractical,
    sizeRange: 4...7,
    growthModel: OperationGrowthModel(
      anchorSize: 7, coefficients: [39800.1, 74893.9, 73214.9, 49241.9, 25518.4, 10833.2],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .factorial, coefficients: [65.9287, 0.967028], rSquared: 0.944331),
    implementationComplexity: 12,
    stable: false,
    timeComplexity: ComplexityBounds(
      best: "O(n)", average: "O(n \\times n!)", worst: "O(n \\times n!)"),
    spaceComplexity: "O(1)",
    iconName: "die.face.1.fill"
  )
  public init() {}

  /// ArrayV's `LessBogoSort` repeatedly shuffles the remaining range `[i, n)` until its front
  /// element is the minimum, then advances `i`. Ported using `BogoSort`'s fix applied per
  /// subrange: instead of a random shuffle, deterministically step through lexicographic
  /// permutations of `[i, n)` until the front lands on the minimum. Every one of `(n - i)!`
  /// permutations is reachable with no repeats, and the fully ascending arrangement always
  /// satisfies "front is minimum," so each outer step is guaranteed to terminate.
  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 1 else { return }

    func isFrontMinimum(_ start: Int, _ end: Int) -> Bool {
      for i in (start + 1)..<end {
        let frontIsLarger = engine.compare(start, i, by: (>))
        engine.annotateLastOperation(
          stageID: "candidateCheck", decisionID: "lessbogosort.frontMinimum",
          outcome: frontIsLarger ? "reject" : "continue",
          roles: ["front": .arrayIndex(start), "candidate": .arrayIndex(i)],
          explanationKey: "lessbogosort.frontMinimum",
          explanation: frontIsLarger
            ? String(localized: "A smaller value exists in this window, so the front is not its minimum.", bundle: .module)
            : String(localized: "The front is no larger than this value, so continue checking the window.", bundle: .module))
        if frontIsLarger { return false }
      }
      return true
    }

    /// Lexicographic next permutation of the half-open range `[start, end)`, scoped down from
    /// `BogoSort`'s full-array version. Returns `false` once `[start, end)` holds its fully
    /// descending arrangement — the lexicographic last permutation, and the one immediately
    /// before wrapping back around to fully ascending.
    func nextPermutation(_ start: Int, _ end: Int) -> Bool {
      var i = end - 2
      while i >= start, engine.compare(i, i + 1) { i -= 1 }
      guard i >= start else { return false }

      var j = end - 1
      while !engine.compare(j, i, by: (>)) { j -= 1 }

      engine.swap(i, j)
      engine.annotateLastOperation(
        stageID: "candidateExchange", decisionID: "lessbogosort.candidateExchange",
        outcome: "exchange", roles: ["left": .arrayIndex(i), "right": .arrayIndex(j)],
        explanationKey: "lessbogosort.candidateExchange",
        explanation: String(localized: "The next permutation exchanges its pivot with a successor in the active range.", bundle: .module))
      engine.reversal(i + 1, end - 1)
      engine.annotateLastOperation(
        stageID: "candidateWrap", decisionID: "lessbogosort.reverseSuffix",
        outcome: "reverse",
        roles: ["first": .arrayIndex(i + 1), "last": .arrayIndex(end - 1)],
        explanationKey: "lessbogosort.reverseSuffix",
        explanation: String(localized: "Reverse this descending range to advance to the next candidate permutation.", bundle: .module))
      return true
    }

    for i in 0..<n {
      while !isFrontMinimum(i, n) {
        if !nextPermutation(i, n) {
          // Fully descending range, still not front-minimum (only possible when
          // n - i > 1) — wrap straight to fully ascending, which trivially is.
          engine.reversal(i, n - 1)
          engine.annotateLastOperation(
            stageID: "candidateWrap", decisionID: "lessbogosort.reverseSuffix",
            outcome: "reverse",
            roles: ["first": .arrayIndex(i), "last": .arrayIndex(n - 1)],
            explanationKey: "lessbogosort.reverseSuffix",
            explanation: String(localized: "Reverse this descending range to advance to the next candidate permutation.", bundle: .module))
        }
      }
    }
  }
}
