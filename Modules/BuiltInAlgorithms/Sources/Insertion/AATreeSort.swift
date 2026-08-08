import AlgorithmKit
import SortEngineKit

/// A tree sort backed by an AA tree — a simplified red-black tree where balance is tracked with a
/// single integer `level` (how many black links separate a node from a leaf) rather than a color.
/// Every node holds a `pointer` back into the array (not a copy of its value), the same convention
/// `TreeSort` uses, so the underlying array is never touched until the final write-back pass.
///
/// An AA tree only allows two shapes that would otherwise violate balance: a left child at the same
/// level as its parent (fixed by `skew`, a single right rotation), and two consecutive right links
/// at the same level (fixed by `split`, a single left rotation that also bumps the surviving node's
/// level). `add` performs at most one of each per level on the way back up the recursion, which is
/// what keeps this to a real `O(log n)` worst-case height, unlike `TreeSort`'s unbalanced tree.
///
/// Ties route to the right subtree (`add`'s `<` check only takes the left branch on a strictly
/// smaller value), and in-order traversal is left-self-right, so this sort is stable.
public struct AATreeSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "aatreesort")
  public let metadata = AlgorithmMetadata(
    displayName: "Tree Sort (AA Balanced)",
    category: .insertion,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 2364, coefficients: [184459, 94.7247, 0.0040135],
      measuredSafeCeiling: nil),
    stable: true,
    timeComplexity: ComplexityBounds(best: "O(n log n)", average: "O(n log n)", worst: "O(n log n)"),
    spaceComplexity: "O(n)",
    iconName: "chevron.up.chevron.down"
  )

  public init() {}

  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 1 else { return }

    final class Node {
      var pointer: Int
      var left: Node?
      var right: Node?
      var level = 0
      init(_ pointer: Int) { self.pointer = pointer }
    }

    func level(_ node: Node?) -> Int { node?.level ?? -1 }

    func skew(_ node: Node) -> Node {
      guard let l = node.left else { return node }
      node.left = l.right
      l.right = node
      return l
    }

    func split(_ node: Node) -> Node {
      guard let r = node.right else { return node }
      node.right = r.left
      r.left = node
      r.level += 1
      return r
    }

    func add(_ node: Node?, _ addPointer: Int) -> Node {
      guard let node else { return Node(addPointer) }

      if engine.compare(addPointer, node.pointer, by: <) {
        node.left = add(node.left, addPointer)
        if level(node.left) == node.level {
          if node.level != level(node.right) {
            return skew(node)
          }
          node.level += 1
          return node
        }
        return node
      } else {
        node.right = add(node.right, addPointer)
        if level(node.right?.right) == node.level {
          return split(node)
        }
        return node
      }
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
