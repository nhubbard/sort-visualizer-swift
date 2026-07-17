import AlgorithmKit
import SortEngineKit

/// Ported from ArrayV's `Shuffles.INV_BST`. Computes the same breadth-first, implicit-binary-tree
/// visiting order over the index range that `BSTTraversalShuffle` does, but uses it in reverse:
/// instead of gathering values *from* that order into natural position order, it scatters the
/// array's current values (read in their existing natural order) *into* that order's positions —
/// the inverse permutation of `BSTTraversalShuffle`.
public struct InvertedBSTShuffle: ShuffleAlgorithm {
  public let id = ShuffleID(rawValue: "invertedbst")
  public let metadata = ShuffleMetadata(displayName: "Inverted BST")
  public init() {}
  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 0 else { return }

    var visitedIndex = [Int](repeating: 0, count: n)
    var queue: [(start: Int, end: Int)] = [(0, n)]
    var i = 0
    var head = 0
    while head < queue.count {
      let sub = queue[head]
      head += 1
      guard sub.start != sub.end else { continue }
      let mid = (sub.start + sub.end) / 2
      visitedIndex[i] = mid
      i += 1
      queue.append((sub.start, mid))
      queue.append((mid + 1, sub.end))
    }

    let original = engine.values
    for i in 0..<n {
      engine.setValue(visitedIndex[i], original[i])
    }
  }
}
