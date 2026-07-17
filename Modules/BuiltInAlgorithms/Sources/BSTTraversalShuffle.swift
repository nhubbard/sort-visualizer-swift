import AlgorithmKit
import SortEngineKit

/// Ported from ArrayV's `Shuffles.BST_TRAVERSAL`. Treats the array's index range as an implicit
/// binary search tree — the midpoint of any range is that subtree's root, and the ranges to its
/// left/right are its children — and rewrites the array in breadth-first visiting order of that
/// tree, level by level.
public struct BSTTraversalShuffle: ShuffleAlgorithm {
  public let id = ShuffleID(rawValue: "bsttraversal")
  public let metadata = ShuffleMetadata(displayName: "BST Traversal")
  public init() {}
  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 0 else { return }
    let original = engine.values

    var queue: [(start: Int, end: Int)] = [(0, n)]
    var i = 0
    var head = 0
    while head < queue.count {
      let sub = queue[head]
      head += 1
      guard sub.start != sub.end else { continue }
      let mid = (sub.start + sub.end) / 2
      engine.setValue(i, original[mid])
      i += 1
      queue.append((sub.start, mid))
      queue.append((mid + 1, sub.end))
    }
  }
}
