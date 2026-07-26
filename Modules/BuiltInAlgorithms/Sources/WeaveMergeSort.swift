import AlgorithmKit
import SortEngineKit

/// ArrayV's `WeaveMergeSort` — despite the merge-sort-shaped recursion, this never merges by
/// comparing values. `weaveMergeSort(min, max)` splits at the midpoint, recursively sorts each
/// half, then `weaveMerge` does two passes: a purely positional riffle-interleave of the two
/// sorted halves (`multiSwap` — a chain of adjacent swaps that walks an element into place, NOT a
/// single atomic exchange, despite the name), followed by a full insertion sort (`weaveInsert`)
/// over the woven range to actually restore order.
///
/// Stability: `false`. `weaveInsert`'s shift condition is non-strict (`<=`), so a newly reached
/// element slides left past elements merely equal to it, reordering ties. Confirmed empirically
/// via tagged-duplicate fuzzing — see
/// `NativeAlgorithmCorrectnessTests.weaveMergeSortTiedElementsCanLoseTheirOriginalRelativeOrder`.
///
/// Complexity: `Θ(n^2)` in every case, not `O(n log n)` despite the merge-sort shape. Interleaving
/// two sorted halves by position rather than value produces `Θ(n^2)` inversions even on sorted
/// input, and `weaveInsert` pays `Θ(1)` per inversion to fix them. Space is `O(log n)` — the
/// recursion stack only; unlike `WeavedMergeSort` there's no `O(n)` merge buffer.
public struct WeaveMergeSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "weavemergesort")
  public let metadata = AlgorithmMetadata(
    displayName: "Weave Merge Sort",
    category: .hybrid,
    sizeRange: 16...256,
    stable: false,
    timeComplexity: ComplexityBounds(best: "O(n^2)", average: "O(n^2)", worst: "O(n^2)"),
    spaceComplexity: "O(log n)",
    iconName: "square.stack.3d.up"
  )

  public init() {}

  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 1 else { return }
    weaveMergeSort(into: &engine, min: 0, max: n - 1)
  }

  /// Ports `weaveMergeSort(array, min, max)`. `max` is an INCLUSIVE upper index throughout this
  /// whole recursive family (matching `runSort`'s own `weaveMergeSort(array, 0, currentLength -
  /// 1)` top-level call), not an exclusive length.
  private func weaveMergeSort(into engine: inout RecordingEngine, min: Int, max: Int) {
    if max - min == 0 {
      // Single element — ArrayV's branch is a bare `Delays.sleep(1)`, no read or write.
      return
    } else if max - min == 1 {
      // Exactly two elements: `Reads.compareValues(array[min], array[max]) == 1` is a
      // strictly-greater-than check performed via ArrayV's non-marking `compareValues`
      // (not the marking `compareIndices`), so this reads `engine.values` directly rather
      // than going through `engine.compare` — the same convention `DoubleInsertionSort`/
      // `WeavedMergeSort` already use for comparisons ArrayV itself performs via
      // `compareValues` rather than `compareIndices`. Ties are left untouched.
      if engine.values[min] > engine.values[max] {
        engine.swap(min, max)
      }
    } else {
      let mid = (min + max) / 2  // Swift integer division already floors for non-negative bounds.
      weaveMergeSort(into: &engine, min: min, max: mid)
      weaveMergeSort(into: &engine, min: mid + 1, max: max)
      weaveMerge(into: &engine, min: min, max: max, mid: mid)
    }
  }

  /// Ports `weaveMerge(array, min, max, mid)`: the riffle-interleave of the two now-sorted
  /// halves `[min, mid]`/`[mid + 1, max]` via `multiSwap`, followed by a full insertion-sort
  /// pass (`weaveInsert`) over the combined range to actually restore sorted order.
  private func weaveMerge(into engine: inout RecordingEngine, min: Int, max: Int, mid: Int) {
    let target = mid - min
    var i = 1
    while i <= target {
      multiSwap(into: &engine, pos: mid + i, to: min + (i * 2) - 1)
      i += 1
    }
    // `end` is exclusive here — ArrayV calls `weaveInsert(arr, min, max + 1)`.
    weaveInsert(into: &engine, start: min, end: max + 1)
  }

  /// Ports `Writes.multiSwap(array, pos, to, ...)` — a chain of adjacent swaps, NOT a single
  /// two-element exchange despite the name. Walks the element at `pos` to slot `to`, shifting
  /// everything between over by one.
  private func multiSwap(into engine: inout RecordingEngine, pos: Int, to: Int) {
    if to - pos > 0 {
      var i = pos
      while i < to {
        engine.swap(i, i + 1)
        i += 1
      }
    } else {
      var i = pos
      while i > to {
        engine.swap(i, i - 1)
        i -= 1
      }
    }
  }

  /// Ports `weaveInsert(array, start, end)` — `end` is exclusive. A classic insertion sort, but
  /// with a non-strict (`<=`, i.e. tie-swapping) shift condition, matching ArrayV's `while (pos >
  /// start && Reads.compareValues(arr[pos], arr[pos - 1]) < 1)`. As with the base-case compare
  /// above, `Reads.compareValues` is the non-marking variant, so this reads `engine.values`
  /// directly rather than calling `engine.compare` — see `DoubleInsertionSort`'s identical
  /// convention for shift-loop conditions ArrayV performs via `compareValues`. The tie-swapping
  /// (rather than the usual strict `<`) is exactly what makes this algorithm unstable — see the
  /// stability note on the type itself.
  private func weaveInsert(into engine: inout RecordingEngine, start: Int, end: Int) {
    guard start < end else { return }
    for j in start..<end {
      var pos = j
      while pos > start && engine.values[pos] <= engine.values[pos - 1] {
        engine.swap(pos, pos - 1)
        pos -= 1
      }
    }
  }
}
