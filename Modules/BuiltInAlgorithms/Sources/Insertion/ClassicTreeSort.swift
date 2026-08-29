import AlgorithmKit
import SortEngineKit

/// ArrayV's `ClassicTreeSort` — builds an unbalanced binary search tree over the array's indices
/// (not its values directly), then reads sorted order back out via an in-order traversal.
///
/// `lower`/`upper` are `n`-sized index arrays holding each node's left/right child, or `0` for
/// "no child." `0` also doubles as the real index `0`, which never collides because insertion
/// starts at `i = 1` — index `0` is implicitly the root and is never anyone's child.
///
/// Stability: `true` — ties route to `upper` (right), and traversal is left-self-right, so a later
/// index with an equal value always ends up nested inside the earlier one's `upper` subtree and is
/// emitted after it.
///
/// Complexity: `O(n log n)` best/average (random arrival order gives `O(log n)` expected insertion
/// depth), `O(n^2)` worst (sorted/reverse-sorted input degenerates the tree into a chain). Space:
/// `Θ(n)` for the three persistent auxiliary arrays (`lower`, `upper`, `temp`) — not `O(1)`/
/// `O(log n)` like other insertion-family sorts here.
public struct ClassicTreeSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "classictreesort")
  public let metadata = AlgorithmMetadata(
    displayName: "Classic Tree Sort",
    category: .insertion,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 309, coefficients: [238856, 1545.5, 2.5],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .polynomialIntercept, coefficients: [0, 3, -1], rSquared: 1),
    stable: true,
    timeComplexity: ComplexityBounds(best: "O(n log n)", average: "O(n log n)", worst: "O(n^2)"),
    spaceComplexity: "O(n)",
    iconName: "list.bullet.indent"
  )

  public init() {}

  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 1 else { return }

    // `lower`/`upper` back the tree's child pointers. `writeAux` only feeds the visualizer tape,
    // so real Swift arrays drive the actual logic (same pattern as `WeaveMergeSort`/`BottomUpMergeSort`).
    var lower = [Int](repeating: 0, count: n)
    var upper = [Int](repeating: 0, count: n)
    let lowerHandle = engine.createAuxArray(length: n)
    let upperHandle = engine.createAuxArray(length: n)

    for i in 1..<n {
      var c = 0
      while true {
        // Both `i` and `c` are live, untouched main-array indices for the whole insertion phase
        // (nothing writes to `values` until the final reconstruction loop below), so this is a
        // real `engine.compare` — routing it through raw `engine.values` reads made this
        // algorithm's true O(n^2) worst-case cost invisible to the growth model that sizes it.
        let goLower = engine.compare(i, c, by: <)
        if goLower {
          if lower[c] == 0 {
            lower[c] = i
            engine.writeAux(lowerHandle, at: c, value: i)
            break
          } else {
            c = lower[c]
          }
        } else {
          if upper[c] == 0 {
            upper[c] = i
            engine.writeAux(upperHandle, at: c, value: i)
            break
          } else {
            c = upper[c]
          }
        }
      }
    }

    var temp = [Int](repeating: 0, count: n)
    let tempHandle = engine.createAuxArray(length: n)
    var idx = 0
    traverse(
      engine.values, lower, upper, root: 0, into: &temp, at: &idx, engine: &engine,
      tempHandle: tempHandle)

    for i in 0..<n {
      engine.setValue(i, temp[i])
    }

    engine.deleteAuxArray(lowerHandle)
    engine.deleteAuxArray(upperHandle)
    engine.deleteAuxArray(tempHandle)
  }

  /// Ports ArrayV's recursive `traverse(array, temp, lower, upper, r)` — an in-order walk (left,
  /// self, right) that emits the tree's values into `temp` in sorted order — as an iterative walk
  /// over an explicit, heap-allocated `[Int]` stack instead, mirroring
  /// `BinaryQuickSortingTemplate`'s explicit-work-list idiom.
  ///
  /// This tree is never balanced (see the type's own doc comment), so a call-stack-recursive
  /// traversal's depth is `O(n)` in the worst case (sorted/reverse-sorted or otherwise adversarial
  /// input degenerates it into a linear chain) — a size-8192 run with such an input produced a real,
  /// reproduced-in-Xcode `EXC_BAD_ACCESS` from overflowing the smaller stack `RecordingEngine`'s
  /// detached recording `Task` runs on (nothing like the 8 MB main-thread stack). An explicit
  /// `[Int]` stack has the identical `O(depth)` space cost, but as an ordinary heap-allocated Swift
  /// `Array` rather than fixed-size thread-stack frames, so it grows instead of overflowing.
  ///
  /// `current`/node indices are `Int?`, not the tree's own `0`-means-"no child" sentinel — `0` is
  /// also the real root index here, so a raw `Int` can't distinguish "descend into node 0" from
  /// "no child," unlike inside `lower`/`upper` themselves (where `0` is unambiguous only because
  /// index `0` can never be assigned as anyone's child during insertion).
  private func traverse(
    _ values: [Int],
    _ lower: [Int],
    _ upper: [Int],
    root: Int,
    into temp: inout [Int],
    at idx: inout Int,
    engine: inout RecordingEngine,
    tempHandle: AuxHandle
  ) {
    var stack: [Int] = []
    var current: Int? = root
    while current != nil || !stack.isEmpty {
      while let node = current {
        stack.append(node)
        current = lower[node] != 0 ? lower[node] : nil
      }
      let node = stack.removeLast()
      temp[idx] = values[node]
      engine.writeAux(tempHandle, at: idx, value: values[node])
      idx += 1
      current = upper[node] != 0 ? upper[node] : nil
    }
  }
}
