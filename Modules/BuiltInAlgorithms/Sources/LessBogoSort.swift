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
