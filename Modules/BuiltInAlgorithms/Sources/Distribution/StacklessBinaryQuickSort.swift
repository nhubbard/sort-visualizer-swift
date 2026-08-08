import AlgorithmKit
import SortEngineKit

/// Ported from ArrayV's `StacklessBinaryQuickSort` — the same bit-radix partitioning as
/// `BinaryQuickSortingTemplate` (Hoare-style: route "bit clear" left, "bit set" right, then
/// recurse on both halves with the next-lower bit), but without a call stack *or* an explicit work
/// queue like `BinaryQuickSortIterative` uses. Instead, `i`/`b` track the current active range and
/// `q` the current bit, and the traversal always partitions the active range immediately (a
/// pre-order "descend left first" step via `b = p; q -= 1`). Once a range bottoms out at bit 0,
/// `m` — a counter that enumerates this binary recursion tree's nodes in the same pre-order the
/// traversal already visits them in — finds the next not-yet-visited sibling by counting how many
/// trailing bits of `m` are already set (`while !getBit(m, q + 1) { q += 1 }`): each such bit means
/// that level's left/right split is already fully behind us, so the search climbs one level higher
/// until it finds a level with an unvisited right sibling. The trailing `while` widens `b` to catch
/// up: elements at the boundary that share `m`'s higher bits belong to that sibling's range but
/// were never included when the original range was first carved out.
public struct StacklessBinaryQuickSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "stacklessbinaryquicksort")
  public let metadata = AlgorithmMetadata(
    displayName: "Stackless Binary Quick Sort",
    category: .distribution,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 4823, coefficients: [130922, 35.5342, 0.00109931],
      measuredSafeCeiling: nil),
    stable: false,
    timeComplexity: ComplexityBounds(
      best: "O(n log n)", average: "O(n log n)", worst: "O(n log n)"),
    spaceComplexity: "O(1)",
    iconName: "arrow.triangle.branch"
  )

  public init() {}

  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 1 else { return }

    func getBit(_ value: Int, _ bit: Int) -> Bool {
      (value >> bit) & 1 == 1
    }

    func partition(_ a: Int, _ b: Int, _ bit: Int) -> Int {
      var i = a - 1
      var j = b
      while true {
        i += 1
        while i < j && !getBit(engine.values[i], bit) { i += 1 }
        j -= 1
        while j > i && getBit(engine.values[j], bit) { j -= 1 }
        if i < j {
          engine.swap(i, j)
        } else {
          return i
        }
      }
    }

    var q = BinaryQuickSortingTemplate.mostSignificantBit(engine.values)
    guard q >= 0 else { return }
    var m = 0
    var i = 0
    var b = n

    while i < n {
      let p = b - i < 1 ? i : partition(i, b, q)

      if q == 0 {
        m += 2
        while !getBit(m, q + 1) { q += 1 }

        i = b
        while b < n && (engine.values[b] >> (q + 1)) == (m >> (q + 1)) {
          b += 1
        }
      } else {
        b = p
        q -= 1
      }
    }
  }
}
