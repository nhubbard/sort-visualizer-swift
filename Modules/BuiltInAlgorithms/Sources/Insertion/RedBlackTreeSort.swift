import AlgorithmKit
import SortEngineKit

/// A tree sort backed by a red-black tree, inserted top-down: on the way *down* the recursion,
/// any node with two red children gets recolored (itself red, both children black) before
/// descending further, which prevents the double-red violations that would otherwise need fixing
/// on the way back up; on the way *up*, a child reporting `needsFix` (it and its own red child form
/// a red-red chain) triggers exactly one single or double rotation depending on which side the
/// grandchild leans.
///
/// Nodes hold a `pointer` back into the array rather than a value copy (same convention as
/// `TreeSort`/`AATreeSort`), so the array is untouched until the final write-back traversal. Ties
/// route to the right subtree, and in-order traversal is left-self-right, so this sort is stable.
/// The root is forced black after every insertion, same as the textbook invariant.
public struct RedBlackTreeSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "redblacktreesort")
  public let metadata = AlgorithmMetadata(
    displayName: "Tree Sort (Red-Black Balanced)",
    category: .insertion,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 2141, coefficients: [187269, 110.438, 0.00642576],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .powerLog, coefficients: [4.13756, 1.13222], rSquared: 0.998576),
    stable: true,
    timeComplexity: ComplexityBounds(best: "O(n log n)", average: "O(n log n)", worst: "O(n log n)"),
    spaceComplexity: "O(n)",
    iconName: "circle.lefthalf.filled"
  )

  public init() {}

  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 1 else { return }

    final class Node {
      var pointer: Int
      var left: Node?
      var right: Node?
      var isRed = true
      init(_ pointer: Int) { self.pointer = pointer }
    }

    func isRed(_ node: Node?) -> Bool { node?.isRed ?? false }

    func singleRotateRight(_ node: Node) -> Node {
      let b = node.left!
      node.left = b.right
      b.right = node
      b.isRed = false
      node.isRed = true
      return b
    }

    func singleRotateLeft(_ node: Node) -> Node {
      let b = node.right!
      node.right = b.left
      b.left = node
      b.isRed = false
      node.isRed = true
      return b
    }

    func doubleRotateRight(_ node: Node) -> Node {
      node.left = singleRotateLeft(node.left!)
      return singleRotateRight(node)
    }

    func doubleRotateLeft(_ node: Node) -> Node {
      node.right = singleRotateRight(node.right!)
      return singleRotateLeft(node)
    }

    struct AddResult { var node: Node; var needsFix: Bool }

    func add(_ node: Node?, _ addPointer: Int) -> AddResult {
      guard let node else {
        return AddResult(node: Node(addPointer), needsFix: false)
      }

      if !node.isRed, isRed(node.left), isRed(node.right) {
        node.isRed = true
        node.left!.isRed = false
        node.right!.isRed = false
      }

      if engine.compare(addPointer, node.pointer, by: <) {
        let result = add(node.left, addPointer)
        node.left = result.node
        if result.needsFix {
          if isRed(node.left!.left) {
            return AddResult(node: singleRotateRight(node), needsFix: false)
          }
          return AddResult(node: doubleRotateRight(node), needsFix: false)
        }
        return AddResult(node: node, needsFix: node.isRed && isRed(node.left))
      } else {
        let result = add(node.right, addPointer)
        node.right = result.node
        if result.needsFix {
          if isRed(node.right!.right) {
            return AddResult(node: singleRotateLeft(node), needsFix: false)
          }
          return AddResult(node: doubleRotateLeft(node), needsFix: false)
        }
        return AddResult(node: node, needsFix: node.isRed && isRed(node.right))
      }
    }

    var root: Node?
    for i in 0..<n {
      let result = add(root, i)
      root = result.node
      root?.isRed = false
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
