import AlgorithmKit
import SortEngineKit

public struct BogoSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "bogosort")
  public let metadata = AlgorithmMetadata(
    displayName: "Bogo Sort",
    category: .impractical,
    sizeRange: 4...7,
    growthModel: OperationGrowthModel(
      anchorSize: 7, coefficients: [64841.3, 138712, 153462, 116450, 67932.8, 32406.7],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .factorial, coefficients: [44.7206, 1.09936], rSquared: 0.999853),
    implementationComplexity: 11,
    stable: false,
    timeComplexity: ComplexityBounds(
      best: "O(n)", average: "O(n \\times n!)", worst: "O(n \\times n!)"),
    spaceComplexity: "O(1)",
    iconName: "die.face.5.fill"
  )
  public init() {}

  /// Classic Bogo Sort shuffles randomly and checks; since `RecordingEngine` must pre-record the
  /// entire run before playback, an open-ended random walk risks an unbounded tape. This instead
  /// walks permutations deterministically via lexicographic `next_permutation`, giving a hard
  /// n!-step ceiling with no repeats. `next_permutation` never lands on the sorted (lexicographically
  /// first) permutation except by wrapping around from the fully descending (lexicographically
  /// last) one, so the final `engine.reversal` handles that wrap-to-sorted step directly.
  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 1 else { return }

    func isSorted() -> Bool {
      for i in 1..<n where !engine.compare(i, i - 1) { return false }
      return true
    }

    if isSorted() { return }

    func nextPermutation() -> Bool {
      var i = n - 2
      while i >= 0, engine.compare(i, i + 1) { i -= 1 }
      guard i >= 0 else { return false }

      var j = n - 1
      while !engine.compare(j, i, by: (>)) { j -= 1 }

      engine.swap(i, j)
      engine.reversal(i + 1, n - 1)
      return true
    }

    while nextPermutation() {}
    // `nextPermutation` only returns false once the array is the fully descending
    // permutation — the next one, cyclically, is the fully sorted ascending array.
    engine.reversal(0, n - 1)
  }
}
