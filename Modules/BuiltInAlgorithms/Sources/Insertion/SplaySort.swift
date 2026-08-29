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
///
/// `splay`'s three `Node.key` comparisons go through `engine.compareValues` — neither side is ever
/// a live array index (both are held tree-node keys), so `engine.compare`/`compareValue` don't
/// apply. Before this, the tree's entire real descent cost (amortized `O(log n)` per insertion,
/// but a degenerate/sorted input's worst-case `O(n)` single-call depth) was invisible to
/// `compareCount` — the tape only ever saw this sort's final `n` `setValue` calls, indistinguishable
/// from `PatienceSort`'s equally under-counted profile despite the two being structurally
/// unrelated sorts.
public struct SplaySort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "splaysort")
  public let metadata = AlgorithmMetadata(
    displayName: "Splay Sort",
    category: .insertion,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 4925, coefficients: [134363, 32.8644, 0.000644423],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .powerLog, coefficients: [1.53133, 1.08701], rSquared: 0.999659),
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

    // Which of the 4 zig-zig/zig-zag cases a descend step took, and the two nodes its unwind
    // step needs — everything the original recursive call's stack frame held onto across its own
    // single recursive call.
    enum SplayFrame {
      case zigZigLeft(root: Node, left: Node)
      case zigZagLeft(root: Node, left: Node)
      case zigZagRight(root: Node, right: Node)
      case zigZigRight(root: Node, right: Node)
    }

    // Iterative splay — a real, reproducible `EXC_BAD_ACCESS` (445 recursion frames, well within
    // a plausible tree depth here) showed splaying's *amortized* O(log n) guarantee doesn't bound
    // any single call's depth: even an ordinary (non-adversarial) insertion sequence can
    // transiently build a deep chain, and a single splay toward a key at its far end still
    // recurses the full depth of that chain. `traverse`'s own doc comment already covers the
    // "monotonic insertion order never rotates, degenerates into a chain" mechanism; this is the
    // second, independent place that same transient chain shape can blow the stack.
    //
    // Every recursive call above makes *at most one* further recursive call, so this converts
    // directly: a descend loop mirrors the original's branch decisions exactly, pushing one
    // `SplayFrame` per level instead of recursing, until it hits a base case (`nil` root, or a
    // missing child — the same two `guard` cases the recursive version returns from directly);
    // an unwind loop then replays each frame's post-recursion work bottom-up, in the same order
    // the call stack would have unwound it. Each case below is a line-for-line transcription of
    // one branch's "assign into the child slot, rotate, decide the frame's own return value" — the
    // `newRoot` locals exist only because the original's `root = rightRotate(root)`/`root =
    // leftRotate(root)` reassignments need a distinct name once they're no longer a single
    // function's local variable.
    func splay(_ rootArg: Node?, _ key: Int) -> Node? {
      var frames: [SplayFrame] = []
      var current = rootArg
      var baseResult: Node?

      descend: while true {
        guard let root = current else {
          baseResult = nil
          break descend
        }
        if engine.compareValues(root.key, key, by: (>)) {
          guard let left = root.left else {
            baseResult = root
            break descend
          }
          if engine.compareValues(left.key, key, by: (>)) {
            frames.append(.zigZigLeft(root: root, left: left))
            current = left.left
          } else {
            frames.append(.zigZagLeft(root: root, left: left))
            current = left.right
          }
        } else {
          guard let right = root.right else {
            baseResult = root
            break descend
          }
          if engine.compareValues(right.key, key, by: (>)) {
            frames.append(.zigZagRight(root: root, right: right))
            current = right.left
          } else {
            frames.append(.zigZigRight(root: root, right: right))
            current = right.right
          }
        }
      }

      var result = baseResult
      while let frame = frames.popLast() {
        switch frame {
        case .zigZigLeft(let root, let left):
          left.left = result
          let newRoot = rightRotate(root)
          result = newRoot.left == nil ? newRoot : rightRotate(newRoot)
        case .zigZagLeft(let root, let left):
          left.right = result
          if left.right != nil {
            root.left = leftRotate(left)
          }
          result = root.left == nil ? root : rightRotate(root)
        case .zigZagRight(let root, let right):
          right.left = result
          if right.left != nil {
            root.right = rightRotate(right)
          }
          result = root.right == nil ? root : leftRotate(root)
        case .zigZigRight(let root, let right):
          right.right = result
          let newRoot = leftRotate(root)
          result = newRoot.right == nil ? newRoot : leftRotate(newRoot)
        }
      }
      return result
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
