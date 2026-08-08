import AlgorithmKit
import SortEngineKit

/// An unbalanced (naive) binary search tree sort. Each array position is inserted into the tree
/// exactly once, as a node holding that position's own index rather than a copy of its value — the
/// underlying array is never mutated during tree construction, so every comparison a node's `add`
/// makes (`values[addPointer]` against `values[node.pointer]`) stays valid for the tree's entire
/// lifetime. Ties go to the right subtree, matching ArrayV's own convention, which is exactly what
/// makes an in-order traversal preserve original relative order among equal elements.
///
/// A final in-order traversal collects every position's value into a plain array in ascending
/// order, then that array is written back into the real array position-by-position — mirroring
/// ArrayV's own two-pass shape (build the tree, walk it into a temporary array, copy that back)
/// rather than writing directly into the live array mid-traversal.
public struct TreeSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "treesort")
  public let metadata = AlgorithmMetadata(
    displayName: "Tree Sort (Unbalanced)",
    category: .insertion,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 310, coefficients: [239785, 1548.5, 2.5],
      measuredSafeCeiling: nil),
    stable: true,
    timeComplexity: ComplexityBounds(best: "O(n log n)", average: "O(n log n)", worst: "O(n^2)"),
    spaceComplexity: "O(n)",
    iconName: "leaf.fill"
  )

  public init() {}

  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 1 else { return }

    final class Node {
      var pointer: Int
      var left: Node?
      var right: Node?
      init(_ pointer: Int) { self.pointer = pointer }
    }

    func add(_ node: Node?, _ addPointer: Int) -> Node {
      guard let node else { return Node(addPointer) }
      if engine.compare(addPointer, node.pointer, by: <) {
        node.left = add(node.left, addPointer)
      } else {
        node.right = add(node.right, addPointer)
      }
      return node
    }

    var root: Node?
    for i in 0..<n {
      root = add(root, i)
    }

    var sortedValues = [Int]()
    sortedValues.reserveCapacity(n)
    func traverse(_ node: Node?) {
      guard let node else { return }
      traverse(node.left)
      sortedValues.append(engine.values[node.pointer])
      traverse(node.right)
    }
    traverse(root)

    for i in 0..<n {
      engine.setValue(i, sortedValues[i])
    }
  }
}
