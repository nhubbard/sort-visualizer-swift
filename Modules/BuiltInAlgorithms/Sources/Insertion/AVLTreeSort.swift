import AlgorithmKit
import SortEngineKit

/// A tree sort backed by an AVL tree, the original self-balancing BST: each node tracks `balance`
/// (right subtree height minus left subtree height, always -1/0/1) instead of a color or level.
/// `add` recurses down, then on the way back up calls `heightChangeLeft`/`heightChangeRight`
/// whenever the just-modified child subtree grew taller — most of the time that just nudges
/// `balance` by one and reports whether *this* subtree also grew, but once `balance` would go to
/// ±2 it instead performs exactly one single or double rotation (chosen by which side the
/// grandchild leans on) and reports that the subtree's height is unchanged, which is what stops the
/// rebalancing from propagating any further up the tree.
///
/// Nodes hold a `pointer` back into the array rather than a value copy (same convention as
/// `TreeSort`/`AATreeSort`/`RedBlackTreeSort`), so the array is untouched until the final
/// write-back traversal. Ties route to the right subtree, and in-order traversal is
/// left-self-right, so this sort is stable.
public struct AVLTreeSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "avltreesort")
  public let metadata = AlgorithmMetadata(
    displayName: "Tree Sort (AVL Balanced)",
    category: .insertion,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 2633, coefficients: [177828, 81.6697, 0.00303825],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .powerLog, coefficients: [4.48604, 1.08227], rSquared: 0.999203),
    implementationComplexity: 29,
    stable: true,
    timeComplexity: ComplexityBounds(best: "O(n log n)", average: "O(n log n)", worst: "O(n log n)"),
    spaceComplexity: "O(n)",
    iconName: "scale.3d"
  )

  public init() {}

  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 1 else { return }

    final class Node {
      var pointer: Int
      var left: Node?
      var right: Node?
      var balance = 0
      init(_ pointer: Int) { self.pointer = pointer }
    }

    func singleRotateRight(_ node: Node) -> Node {
      let b = node.left!
      node.left = b.right
      b.right = node
      node.balance = 0
      b.balance = 0
      return b
    }

    func singleRotateLeft(_ node: Node) -> Node {
      let b = node.right!
      node.right = b.left
      b.left = node
      node.balance = 0
      b.balance = 0
      return b
    }

    func doubleRotateRight(_ node: Node) -> Node {
      let oldBBalance = node.left!.right!.balance
      node.left = singleRotateLeft(node.left!)
      let b = singleRotateRight(node)
      if oldBBalance == -1 { b.right!.balance = 1 }
      if oldBBalance == 1 { b.left!.balance = -1 }
      return b
    }

    func doubleRotateLeft(_ node: Node) -> Node {
      let oldBBalance = node.right!.left!.balance
      node.right = singleRotateRight(node.right!)
      let b = singleRotateLeft(node)
      if oldBBalance == -1 { b.right!.balance = 1 }
      if oldBBalance == 1 { b.left!.balance = -1 }
      return b
    }

    struct AddResult { var node: Node; var heightChanged: Bool }

    func heightChangeLeft(_ node: Node) -> AddResult {
      if node.balance != -1 {
        node.balance -= 1
        return AddResult(node: node, heightChanged: node.balance == -1)
      }
      if node.left!.balance == -1 {
        return AddResult(node: singleRotateRight(node), heightChanged: false)
      }
      return AddResult(node: doubleRotateRight(node), heightChanged: false)
    }

    func heightChangeRight(_ node: Node) -> AddResult {
      if node.balance != 1 {
        node.balance += 1
        return AddResult(node: node, heightChanged: node.balance == 1)
      }
      if node.right!.balance == 1 {
        return AddResult(node: singleRotateLeft(node), heightChanged: false)
      }
      return AddResult(node: doubleRotateLeft(node), heightChanged: false)
    }

    func add(_ node: Node?, _ addPointer: Int) -> AddResult {
      guard let node else {
        return AddResult(node: Node(addPointer), heightChanged: true)
      }

      if engine.compare(addPointer, node.pointer, by: <) {
        let result = add(node.left, addPointer)
        node.left = result.node
        if result.heightChanged {
          return heightChangeLeft(node)
        }
        return AddResult(node: node, heightChanged: false)
      } else {
        let result = add(node.right, addPointer)
        node.right = result.node
        if result.heightChanged {
          return heightChangeRight(node)
        }
        return AddResult(node: node, heightChanged: false)
      }
    }

    var root: Node?
    for i in 0..<n {
      root = add(root, i).node
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
