import AlgorithmKit
import SortEngineKit

/// ArrayV's `TriangularHeapSort` — the same extract-max heapsort shape as `MaxHeapSort`, but the
/// implicit tree is read as a triangular structure instead of a binary one: row `r` starts at
/// `T(r) = r*(r+1)/2` and holds `r + 1` elements, and a node at offset `p` within its row has
/// children at offsets `p` and `p + 1` in the next row down (adjacent nodes share a child, like
/// Pascal's triangle). `triangularRoot` inverts `T` to find a flat index's row.
///
/// `runSort` needs an explicit final `if array[0] > array[1] { swap(0, 1) }` after the main loop
/// that `MaxHeapSort` doesn't: ArrayV's loop bound stops one iteration short of the corrective
/// pass `MaxHeapSort`'s loop happens to fold in automatically.
///
/// Stability: `false`, verified empirically — same as `MaxHeapSort`, ties never trigger a swap in
/// `siftDown`, but heap extraction can still reorder equal elements.
///
/// Complexity: `Θ(n^1.5)`, not `O(n log n)` like `MaxHeapSort`. Row sizes grow linearly, so heap
/// height is `O(sqrt(n))`, not `O(log n)`; each of the `n` extraction passes re-sifts from the
/// root and can cross that many rows, giving `Θ(n * sqrt(n))` for the dominant phase.
public struct TriangularHeapSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "triangularheapsort")
  public let metadata = AlgorithmMetadata(
    displayName: "Triangular Heap Sort",
    category: .selection,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 499, coefficients: [239702, 829.397, 0.692574],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .polynomialIntercept, coefficients: [0.692574, 138.207, -1715.4], rSquared: 0.999867),
    stable: false,
    timeComplexity: ComplexityBounds(
      best: "O(n^1.5)", average: "O(n^1.5)", worst: "O(n^1.5)"),
    spaceComplexity: "O(1)",
    iconName: "triangle.fill"
  )
  public init() {}

  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 1 else { return }

    triangularHeapify(&engine, n)
    var i = 1
    while i < n - 1 {
      engine.swap(0, n - i)
      siftDown(&engine, 0, n - i)
      i += 1
    }
    // The explicit tidy-up `MaxHeapSort` doesn't need — see the doc comment above. ArrayV
    // performs this via the non-marking `Reads.compareValues`, so this reads `engine.values`
    // directly rather than calling `engine.compare`.
    if engine.values[0] > engine.values[1] {
      engine.swap(0, 1)
    }
  }

  /// Just the build-heap sweep, stopping short of `record`'s extraction phase — the entry point
  /// `Shuffles.TRI_HEAP` calls directly (`triangularHeapify`), matching `SmoothSort.smoothHeapify`/
  /// `PoplarHeapSort.poplarHeapify`'s own dedicated-entry-point shape.
  public func triangularHeapify(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 1 else { return }
    triangularHeapify(&engine, n)
  }

  // The largest row index `r` such that the triangular number `T(r) = r*(r+1)/2` is `<=
  // val` — the inverse of `T`, telling us which row of the implicit triangular tree a flat
  // array index falls in. Ports ArrayV's `triangularRoot(val)`:
  // `((int) Math.sqrt(8 * val + 1) - 1) / 2`. `val` stays well within `Double`'s exact-
  // integer range for every size this codebase allows (max array size 256, so `8 * val + 1`
  // never exceeds a few thousand), so the `Double` round-trip through `squareRoot()` never
  // loses precision the way it might for astronomically large inputs.
  private func triangularRoot(_ val: Int) -> Int {
    let integerSqrt = Int(Double(8 * val + 1).squareRoot())
    return (integerSqrt - 1) / 2
  }

  // Same nested-loop shape as `MaxHeapSort.swift`'s `siftDown`, with the two DISJOINT
  // binary-heap children (`2*root+1`/`2*root+2`) replaced by this variant's triangular
  // children (`root + row + 1`/`root + row + 2`, where `row = triangularRoot(root)`).
  private func siftDown(_ engine: inout RecordingEngine, _ rootIn: Int, _ size: Int) {
    var root = rootIn
    while true {
      let row = triangularRoot(root)
      let left = root + row + 1
      if left >= size { break }
      let right = left + 1
      var largest = root
      if !engine.compare(largest, left) {
        largest = left
      }
      if right < size && !engine.compare(largest, right) {
        largest = right
      }
      if largest == root { break }
      engine.swap(root, largest)
      root = largest
    }
  }

  // Ports `triangularHeapify` — every index from `length - 1` down to `0`, unlike
  // `MaxHeapSort`'s leaf-skipping `n / 2 - 1` starting point: the triangular leaf boundary
  // isn't a single fixed fraction of `n` the way a binary heap's is, and ArrayV's own source
  // doesn't bother computing it either, so a `siftDown` call on an already-leaf index is a
  // harmless one-comparison-free no-op (`left >= size` breaks immediately) rather than an
  // optimization worth reproducing here.
  private func triangularHeapify(_ engine: inout RecordingEngine, _ length: Int) {
    var i = length - 1
    while i >= 0 {
      siftDown(&engine, i, length)
      i -= 1
    }
  }
}
