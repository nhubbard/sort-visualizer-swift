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
    detectedGrowthModel: DetectedGrowthModel(
      family: .polynomialIntercept, coefficients: [2.5, -1.5, -6.79585e-11], rSquared: 1),
    implementationComplexity: 19,
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

    // Iterative descent rather than call-stack recursion — this tree is never balanced (see the
    // type's own doc comment), so inserting into sorted/reverse-sorted input walks the *entire*
    // existing chain on every insertion, meaning the very last insertion recurses to depth `n - 1`
    // in the original recursive form. That's the same `O(n)`-depth stack-overflow risk
    // `traverse` below has, just triggered during tree construction instead of the final walk.
    func add(_ node: Node?, _ addPointer: Int) -> Node {
      guard let node else { return Node(addPointer) }
      var current = node
      while true {
        if engine.compare(addPointer, current.pointer, by: <) {
          guard let left = current.left else {
            current.left = Node(addPointer)
            break
          }
          current = left
        } else {
          guard let right = current.right else {
            current.right = Node(addPointer)
            break
          }
          current = right
        }
      }
      return node
    }

    var root: Node?
    for i in 0..<n {
      root = add(root, i)
    }

    var sortedValues = [Int]()
    sortedValues.reserveCapacity(n)
    // Iterative in-order walk over an explicit `[Node]` stack rather than call-stack recursion —
    // this tree is never balanced (see the type's own doc comment), so a recursive traversal's
    // depth is `O(n)` in the worst case (sorted/reverse-sorted input degenerates it into a linear
    // chain), which produced a real `EXC_BAD_ACCESS` for `ClassicTreeSort`'s identically-shaped
    // traversal at size 8192 by overflowing the smaller stack `RecordingEngine`'s detached
    // recording `Task` runs on. An explicit stack has the same `O(depth)` space cost, but as an
    // ordinary heap-allocated Swift `Array` that grows instead of overflowing.
    func traverse(_ root: Node?) {
      var stack: [Node] = []
      var current = root
      while current != nil || !stack.isEmpty {
        while let node = current {
          stack.append(node)
          current = node.left
        }
        let node = stack.removeLast()
        sortedValues.append(engine.values[node.pointer])
        current = node.right
      }
    }
    traverse(root)

    // Manually detach every node from its children before `root` goes out of scope. Swift's
    // compiler-synthesized `Node.deinit` recursively releases `left`/`right`, so deallocating a
    // long linear chain (the exact same sorted/reverse-sorted degenerate shape as above) would
    // cascade through `n` nested `deinit` calls and overflow the stack — a second, independent
    // recursion-depth bug from the traversal/insertion ones above, since it happens during
    // deallocation rather than while the tree is actually being used. `ClassicTreeSort` never hits
    // this because it backs its tree with plain `Int` arrays, not reference-counted `Node`s.
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

    for i in 0..<n {
      engine.setValue(i, sortedValues[i])
    }
  }
}
