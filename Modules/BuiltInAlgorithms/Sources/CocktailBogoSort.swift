import AlgorithmKit
import SortEngineKit

public struct CocktailBogoSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "cocktailbogosort")
  public let metadata = AlgorithmMetadata(
    displayName: "Cocktail Bogo Sort",
    category: .impractical,
    sizeRange: 4...7,
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
      for i in (start + 1)..<end where engine.compare(start, i, by: (>)) { return false }
      return true
    }

    func isBackMaximum(_ start: Int, _ end: Int) -> Bool {
      for i in start..<(end - 1) where engine.compare(i, end - 1, by: (>)) { return false }
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
      engine.reversal(i + 1, end - 1)
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
      }
    }
  }
}
