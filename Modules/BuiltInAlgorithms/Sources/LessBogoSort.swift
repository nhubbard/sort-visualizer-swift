import AlgorithmKit
import SortEngineKit

public struct LessBogoSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "lessbogosort")
  public let metadata = AlgorithmMetadata(
    displayName: "Less Bogo Sort",
    category: .impractical,
    sizeRange: 4...7,
    stable: false,
    timeComplexity: ComplexityBounds(
      best: "O(n)", average: "O(n \\times n!)", worst: "O(n \\times n!)"),
    spaceComplexity: "O(1)",
    iconName: "die.face.1.fill"
  )
  public init() {}

  /// ArrayV's `LessBogoSort` repeatedly Fisher–Yates shuffles the remaining range `[i, n)` until
  /// its front element happens to be the minimum of that range, then "drops" it by advancing
  /// `i`. Like `BogoSort`, a real shuffle-until-lucky loop has no memory of which arrangements of
  /// `[i, n)` it's already tried, so `RecordingEngine`'s pre-recorded tape has no hard ceiling —
  /// the same problem, just re-run once per outer step instead of once overall.
  ///
  /// This applies `BogoSort`'s own fix at the scope of each remaining subrange: instead of a
  /// random shuffle, deterministically step through lexicographic permutations of `[i, n)`
  /// (the same `next_permutation` technique, just bounded to the subrange) until the front
  /// element lands on the minimum. Every one of `(n - i)!` permutations of that subrange is
  /// reachable this way with no repeats, so each outer step is guaranteed to terminate within a
  /// hard `(n - i)!`-step ceiling — landing on the range's fully *ascending* order in particular
  /// always satisfies "front is minimum," so the walk can never run out of options before
  /// succeeding.
  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 1 else { return }

    func isFrontMinimum(_ start: Int, _ end: Int) -> Bool {
      for i in (start + 1)..<end where engine.compare(start, i, by: (>)) { return false }
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
      engine.reversal(i + 1, end - 1)
      return true
    }

    for i in 0..<n {
      while !isFrontMinimum(i, n) {
        if !nextPermutation(i, n) {
          // Fully descending range, still not front-minimum (only possible when
          // n - i > 1) — wrap straight to fully ascending, which trivially is.
          engine.reversal(i, n - 1)
        }
      }
    }
  }
}
