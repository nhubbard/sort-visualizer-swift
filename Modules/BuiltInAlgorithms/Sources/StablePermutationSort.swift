import AlgorithmKit
import SortEngineKit

public struct StablePermutationSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "stablepermutationsort")
  public let metadata = AlgorithmMetadata(
    displayName: "Stable Permutation Sort",
    category: .exchange,
    sizeRange: 4...8,
    stable: false,
    timeComplexity: ComplexityBounds(
      best: "O(n)", average: "O(n \\times n!)", worst: "O(n \\times n!)"),
    spaceComplexity: "O(n)",
    iconName: "arrow.2.squarepath"
  )
  public init() {}

  /// Unlike every other member of the Bogo/Guess family, ArrayV's `StablePermutationSort` is
  /// already fully deterministic — no `randInt` anywhere in the Java source — so this is a
  /// faithful, line-for-line port, not a redesign: a Heap's-algorithm walk over an INDEX array
  /// `idx` (tracking which original position each slot currently holds) rather than the values
  /// directly, with a *rotation* — not a swap — as the "step to the next arrangement" move at the
  /// base of each recursion level.
  ///
  /// Despite the name, this does **not** actually guarantee stability — confirmed empirically
  /// (fuzzed against ~40% of duplicate-heavy trials reordering ties, not a rare edge case), the
  /// same kind of "the name promises more than the algorithm delivers" defect `FunSort` already
  /// has documented in `PORT_INVENTORY.md`. The rotation-over-swap enumeration order is real and
  /// translated faithfully; it just doesn't imply what the class name claims it does.
  ///
  /// `idx` itself is pure bookkeeping — never visualized in the original either (ArrayV tracks it
  /// as a plain aux array with no delay), so it stays a local Swift array; only the calls that
  /// touch the real, visualized array go through `engine`.
  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 1 else { return }

    func isSorted() -> Bool {
      for i in 1..<n where !engine.compare(i, i - 1) { return false }
      return true
    }

    var idx = Array(0..<n)

    func permute(_ len: Int) -> Bool {
      if len < 2 { return isSorted() }

      for i in stride(from: len - 2, through: 0, by: -1) {
        if permute(len - 1) { return true }
        engine.swap(idx[i], idx[len - 1])
        idx.swapAt(i, len - 1)
      }
      if permute(len - 1) { return true }

      // Rotate idx[0..<len) right by one...
      let t = idx[len - 1]
      for i in stride(from: len - 1, to: 0, by: -1) {
        idx[i] = idx[i - 1]
      }
      idx[0] = t

      // ...then carry the underlying array's values through the SAME rotation, along the
      // now-rotated idx sequence. Each position is read as a source before it's ever
      // overwritten as a target later in this loop, so no temp copy beyond `t` is needed.
      let carried = engine.values[idx[0]]
      for i in 1..<len {
        engine.setValue(idx[i - 1], engine.values[idx[i]])
      }
      engine.setValue(idx[len - 1], carried)

      return false
    }

    _ = permute(n)
  }
}
