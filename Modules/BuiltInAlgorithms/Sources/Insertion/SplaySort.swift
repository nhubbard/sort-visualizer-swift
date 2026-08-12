import AlgorithmKit
import SortEngineKit

/// An adaptive sort built on a splay tree — a self-balancing binary search tree that moves
/// whatever node was just accessed up to the root via a sequence of rotations (`leftRotate`/
/// `rightRotate`). Each element is inserted by first splaying the existing tree toward that
/// element's own key (`splay`, a combined search-and-rotate descent rather than a plain search),
/// which brings whatever key is closest to the new one to the root; the new node then simply
/// swaps in as the root, taking over one side of the just-splayed node's children and leaving the
/// other side attached to it. Every key here is a genuine held copy (`Node.key`), not an index back
/// into the array — unlike `TreeSort`, this insertion order matters for the tree's shape, so the
/// values themselves have to travel with each node.
///
/// Splay trees are self-adjusting: repeatedly accessing nearby keys keeps the tree shallow for
/// exactly that stretch, which is what gives this sort its adaptive character — an input that's
/// already sorted or nearly so inserts each new (extreme) key in roughly constant amortized time,
/// while a genuinely random insertion order costs the same amortized `O(log n)` per insertion an
/// ordinary balanced tree would. A final in-order traversal writes each key directly back into the
/// real array as it's visited, without a separate temporary buffer.
public struct SplaySort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "splaysort")
  public let metadata = AlgorithmMetadata(
    displayName: "Splay Sort",
    category: .insertion,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 304, coefficients: [293.481, 0.89195],
      measuredSafeCeiling: nil),
    stable: true,
    timeComplexity: ComplexityBounds(best: "O(n)", average: "O(n log n)", worst: "O(n log n)"),
    spaceComplexity: "O(n)",
    iconName: "rotate.3d"
  )

  public init() {}

  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 1 else { return }

    final class Node {
      var key: Int
      var left: Node?
      var right: Node?
      init(_ key: Int) { self.key = key }
    }

    func leftRotate(_ x: Node) -> Node {
      let y = x.right!
      x.right = y.left
      y.left = x
      return y
    }

    func rightRotate(_ x: Node) -> Node {
      let y = x.left!
      x.left = y.right
      y.right = x
      return y
    }

    func splay(_ rootArg: Node?, _ key: Int) -> Node? {
      guard var root = rootArg else { return nil }

      if root.key > key {
        guard let left = root.left else { return root }
        if left.key > key {
          left.left = splay(left.left, key)
          root = rightRotate(root)
        } else {
          left.right = splay(left.right, key)
          if left.right != nil {
            root.left = leftRotate(left)
          }
        }
        return root.left == nil ? root : rightRotate(root)
      } else {
        guard let right = root.right else { return root }
        if right.key > key {
          right.left = splay(right.left, key)
          if right.left != nil {
            root.right = rightRotate(right)
          }
        } else {
          right.right = splay(right.right, key)
          root = leftRotate(root)
        }
        return root.right == nil ? root : leftRotate(root)
      }
    }

    func insertRec(_ rootArg: Node?, _ key: Int) -> Node {
      guard let splayed = splay(rootArg, key) else {
        return Node(key)
      }
      let inserted = Node(key)
      if splayed.key > key {
        inserted.right = splayed
        inserted.left = splayed.left
        splayed.left = nil
      } else {
        inserted.left = splayed
        inserted.right = splayed.right
        splayed.right = nil
      }
      return inserted
    }

    var root: Node?
    for i in 0..<n {
      root = insertRec(root, engine.values[i])
    }

    var index = 0
    // Iterative in-order walk over an explicit `[Node]` stack rather than call-stack recursion.
    // Splaying only pays off across a *mixed* access pattern — for monotonically increasing or
    // decreasing input, `splay` hits its early-return on every insertion (the tree's far child on
    // the relevant side is always `nil`) and the tree never actually gets rotated, so it grows as
    // a plain linear chain exactly like an unbalanced BST would. That makes sorted input a worst
    // case here, not a best case, and a recursive traversal over it the same `O(n)`-depth
    // `EXC_BAD_ACCESS` risk `ClassicTreeSort`'s identically-shaped traversal actually hit at size
    // 8192. An explicit stack has the same `O(depth)` space cost, but as an ordinary
    // heap-allocated Swift `Array` that grows instead of overflowing.
    func traverse(_ root: Node?) {
      var stack: [Node] = []
      var current = root
      while current != nil || !stack.isEmpty {
        while let node = current {
          stack.append(node)
          current = node.left
        }
        let node = stack.removeLast()
        engine.setValue(index, node.key)
        index += 1
        current = node.right
      }
    }
    traverse(root)

    // Manually detach every node from its children before `root` goes out of scope. Swift's
    // compiler-synthesized `Node.deinit` recursively releases `left`/`right`, so deallocating a
    // long linear chain (the same degenerate shape `traverse`'s own doc comment above describes)
    // would cascade through `n` nested `deinit` calls and overflow the stack — a second,
    // independent recursion-depth bug from `traverse`'s, since it happens during deallocation
    // rather than while the tree is actually being used.
    func detachAll(_ root: Node?) {
      var stack: [Node] = []
      if let root { stack.append(root) }
      while let node = stack.popLast() {
        if let left = node.left { stack.append(left) }
        if let right = node.right { stack.append(right) }
        node.left = nil
        node.right = nil
      }
    }
    detachAll(root)
  }
}
