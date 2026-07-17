import AlgorithmKit
import SortEngineKit

public struct GuessSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "guesssort")
  public let metadata = AlgorithmMetadata(
    displayName: "Guess Sort",
    category: .impractical,
    sizeRange: 3...4,
    stable: false,
    timeComplexity: ComplexityBounds(best: "O(n)", average: "O(n^n)", worst: "O(n^n)"),
    spaceComplexity: "O(n)",
    iconName: "questionmark"
  )
  public init() {}

  /// Already fully deterministic in ArrayV — the "plain" ancestor `OptimizedGuessSort`/
  /// `SmartGuessSort` both grew out of. Same base-`n` odometer, but validity is checked
  /// differently: rather than an adjacent-pair-with-tie-break scan, this brute-force-counts, for
  /// every ordered pair `(i, j)`, both whether `loops[i] == loops[j]` (catching a non-permutation
  /// mapping — an index used twice always contributes at least the `n` expected self-pairs, plus
  /// more if genuinely duplicated) and whether reading through `loops` produces an inversion in
  /// EITHER direction. The mapping is accepted only when both counts land at exactly `n` — unlike
  /// the other three, no tie-break on equal values is enforced (accepting any relative order among
  /// ties, matching the original's lack of one). Unlike the others, this never stops early: it
  /// walks the *entire* `n^n` space and keeps whichever valid mapping it saw last, so the final
  /// answer can depend on which tie-order the odometer happened to reach last — still correct,
  /// since any valid mapping sorts the array.
  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 1 else { return }

    var loops = [Int](repeating: 0, count: n)
    var indexes = [Int](repeating: 0, count: n)

    func isValidMapping() -> Bool {
      var total = 0
      for i in 0..<n {
        for j in 0..<n where loops[i] == loops[j] {
          total += 1
        }
      }
      for i in 0..<n {
        for j in 0..<n {
          let isInversion: Bool
          if i < j {
            isInversion = engine.compare(loops[i], loops[j], by: (>))
          } else if i > j {
            isInversion = engine.compare(loops[i], loops[j], by: (<))
          } else {
            isInversion = false
          }
          if isInversion { total += 1 }
        }
      }
      return total == n
    }

    while true {
      if isValidMapping() {
        indexes = loops
      }
      var pos = 0
      while pos < n {
        if loops[pos] < n - 1 {
          loops[pos] += 1
          break
        } else {
          loops[pos] = 0
          pos += 1
        }
      }
      if pos == n { break }
    }

    let original = engine.values
    for i in 0..<n {
      engine.setValue(i, original[indexes[i]])
    }
  }
}
