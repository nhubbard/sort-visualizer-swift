import AlgorithmKit
import SortEngineKit

public struct SlopeSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "slopesort")
  public let metadata = AlgorithmMetadata(
    displayName: "Slope Sort",
    category: .exchange,
    sizeRange: 16...256,
    stable: true,
    timeComplexity: ComplexityBounds(best: "O(n^2)", average: "O(n^2)", worst: "O(n^2)"),
    spaceComplexity: "O(1)",
    iconName: "chart.line.uptrend.xyaxis"
  )
  public init() {}

  /// Ported from ArrayV's `SlopeSort.runSort`. The Java source drives one outer index and one
  /// inner index off the *same* loop variable (`i`), decrementing `i` inside the inner loop and
  /// then resetting it from a separate tracking variable (`j`) at the end of each outer pass —
  /// unusual index bookkeeping, but the net effect is simple: for each `start` from `1` to
  /// `n - 1`, walk an adjacent pair backward from `(start, start - 1)` down to `(1, 0)`, swapping
  /// out-of-order neighbors along the way. Unlike insertion sort's equivalent backward walk,
  /// there's no early exit once the correct slot is found — every adjacent pair down to the
  /// front gets checked on every outer pass, which is what makes this strictly `O(n^2)` with no
  /// best-case shortcut for already-sorted input.
  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 1 else { return }

    for start in 1..<n {
      var i = start
      var k = start - 1
      while k >= 0 {
        // Strict `<` (not the default `>=`) matches ArrayV's `Reads.compareIndices(...,
        // true) < 0` — ties never swap, which is what keeps this stable.
        if engine.compare(i, k, by: (<)) {
          engine.swap(i, k)
        }
        k -= 1
        i -= 1
      }
    }
  }
}
