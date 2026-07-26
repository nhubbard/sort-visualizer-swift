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

  /// ArrayV's `StablePermutationSort` is already deterministic (no `randInt`): a Heap's-algorithm
  /// walk over an index array `idx`, using a *rotation* rather than a swap as the step to the next
  /// arrangement.
  ///
  /// Despite the name, this is NOT stable — fuzzing shows ~40% of duplicate-heavy trials reorder
  /// ties. `idx` is pure bookkeeping (never visualized in ArrayV either), so it stays a local Swift
  /// array; only calls touching the real array go through `engine`.
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
