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
      anchorSize: 80000, coefficients: [239999, 3],
      measuredSafeCeiling: nil),
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
        // Non-marking comparison (ArrayV's `Reads.compareValues`), so this reads `engine.values`
        // directly rather than calling `engine.compare`.
        let goLower = engine.values[i] < engine.values[c]
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

  /// Ports the recursive `traverse(array, temp, lower, upper, r)`: an in-order walk (left, self,
  /// right) that emits the tree's values into `temp` in sorted order.
  private func traverse(
    _ values: [Int],
    _ lower: [Int],
    _ upper: [Int],
    root r: Int,
    into temp: inout [Int],
    at idx: inout Int,
    engine: inout RecordingEngine,
    tempHandle: AuxHandle
  ) {
    if lower[r] != 0 {
      traverse(
        values, lower, upper, root: lower[r], into: &temp, at: &idx, engine: &engine,
        tempHandle: tempHandle)
    }
    temp[idx] = values[r]
    engine.writeAux(tempHandle, at: idx, value: values[r])
    idx += 1
    if upper[r] != 0 {
      traverse(
        values, lower, upper, root: upper[r], into: &temp, at: &idx, engine: &engine,
        tempHandle: tempHandle)
    }
  }
}
