import AlgorithmKit
import SortEngineKit

public struct MedianQuickBogoSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "medianquickbogosort")
  public let metadata = AlgorithmMetadata(
    displayName: "Median Quick Bogo Sort",
    category: .impractical,
    sizeRange: 4...6,
    stable: false,
    timeComplexity: ComplexityBounds(
      best: "O(n)", average: "O(n \\times n!)", worst: "O(n \\times n!)"),
    spaceComplexity: "O(log n)",
    iconName: "die.face.6.fill"
  )
  public init() {}

  /// ArrayV's `MedianQuickBogoSort` reshuffles a range at random until its front half is no
  /// greater than its back half (a median-count split, not a full sort), then recurses on each
  /// half. Ported using the same lexicographic `nextPermutation` walk as `LessBogoSort`, checking
  /// `isRangeSplit` instead of full sortedness; the fully ascending arrangement always satisfies a
  /// split, so termination is guaranteed.
  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 1 else { return }

    func isRangeSplit(_ start: Int, _ mid: Int, _ end: Int) -> Bool {
      var maxIndex = start
      for i in (start + 1)..<mid where engine.compare(i, maxIndex, by: (>)) {
        maxIndex = i
      }
      for i in mid..<end where engine.compare(maxIndex, i, by: (>)) {
        return false
      }
      return true
    }

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

    func medianQuickBogo(_ start: Int, _ end: Int) {
      guard start < end - 1 else { return }
      let mid = (start + end) / 2

      while !isRangeSplit(start, mid, end) {
        if !nextPermutation(start, end) {
          engine.reversal(start, end - 1)
        }
      }

      medianQuickBogo(start, mid)
      medianQuickBogo(mid, end)
    }

    medianQuickBogo(0, n)
  }
}
