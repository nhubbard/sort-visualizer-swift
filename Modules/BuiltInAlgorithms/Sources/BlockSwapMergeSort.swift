import AlgorithmKit
import SortEngineKit

/// ArrayV's `BlockSwapMergeSort` — a bottom-up merge sort (same doubling-width driver shape as
/// `BottomUpMergeSort`/`RotateMergeSort`) with an in-place merge: `binarySearchMid` finds how many
/// trailing elements of the left run are out of place against the head of the right run, then a
/// single block-swap plus a recursive merge of the leftover finishes the pass — no scratch buffer
/// and no rotation needed, because the swap always exchanges two blocks of equal length.
///
/// This file's private `multiSwap(a, b, len)` swaps two equal-length blocks elementwise. Despite
/// the name, it is NOT `WeaveMergeSort`'s `Writes.multiSwap` swap-*chain* — unrelated helpers that
/// happen to share a name.
///
/// Stable: `binarySearchMid` uses a strict `>` comparison, so a tie never gets pulled into the
/// block-swap and the left run's copy of an equal element always stays first.
///
/// `O(n log n)` time in every case, including best case: each element crosses the run boundary via
/// `multiSwap` at most once per doubling pass, so swap work per pass is still `O(n)` even though
/// comparisons use an `O(log(run length))` binary search instead of a linear merge scan.
/// `O(log n)` space — merge recursion depth only, no aux array anywhere.
public struct BlockSwapMergeSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "blockswapmergesort")
  public let metadata = AlgorithmMetadata(
    displayName: "Block-Swap Merge Sort",
    category: .merge,
    sizeRange: 16...256,
    stable: true,
    timeComplexity: ComplexityBounds(
      best: "O(n log n)", average: "O(n log n)", worst: "O(n log n)"),
    spaceComplexity: "O(log n)",
    iconName: "rectangle.split.2x1"
  )

  public init() {}

  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n > 1 else { return }

    // Swaps the two equal-length, non-overlapping contiguous blocks `[a, a+len)` and
    // `[b, b+len)` elementwise. Mirrors ArrayV's `multiSwap(array, a, b, len)`.
    func multiSwap(_ a: Int, _ b: Int, _ len: Int) {
      for i in 0..<len {
        engine.swap(a + i, b + i)
      }
    }

    // Binary-searches for `m`, the number of elements at the tail of the left run `[start,
    // mid)` that are each strictly greater than their mirrored counterpart at the head of the
    // right run `[mid, end)`. Non-marking (`Reads.compareValues` in ArrayV), so this reads
    // `engine.values` directly rather than calling `engine.compare`.
    func binarySearchMid(_ start: Int, _ mid: Int, _ end: Int) -> Int {
      var a = 0
      var b = min(mid - start, end - mid)
      var m = a + (b - a) / 2
      while b > a {
        if engine.values[mid - m - 1] > engine.values[mid + m] {
          a = m + 1
        } else {
          b = m
        }
        m = a + (b - a) / 2
      }
      return m
    }

    // Merges the two adjacent sorted runs `[start, mid)` and `[mid, end)` in place via a
    // sequence of same-length block-swaps, each one immediately followed by a recursive merge
    // of the leftover portion it produces. Mirrors ArrayV's `multiSwapMerge(array, start, mid, end)`.
    func multiSwapMerge(_ start: Int, _ midIn: Int, _ endIn: Int) {
      var mid = midIn
      var end = endIn
      var m = binarySearchMid(start, mid, end)
      while m > 0 {
        multiSwap(mid - m, mid, m)
        multiSwapMerge(mid, mid + m, end)
        end = mid
        mid -= m
        m = binarySearchMid(start, mid, end)
      }
    }

    // Bottom-up doubling pass over merge-width `j`, merging every adjacent pair of runs of
    // that width, with one trailing partial merge per pass if `b - a` isn't a multiple of
    // `2*j` — identical shape to `RotateMergeSort.rotateMergeSort`/`BottomUpMergeSort`.
    // Mirrors ArrayV's `multiSwapMergeSort(array, a, b)`.
    func multiSwapMergeSort(_ a: Int, _ b: Int) {
      let len = b - a
      var i = a
      var j = 1
      while j < len {
        i = a
        while i + 2 * j <= b {
          multiSwapMerge(i, i + j, i + 2 * j)
          i += 2 * j
        }
        if i + j < b {
          multiSwapMerge(i, i + j, b)
        }
        j *= 2
      }
    }

    multiSwapMergeSort(0, n)
  }
}
