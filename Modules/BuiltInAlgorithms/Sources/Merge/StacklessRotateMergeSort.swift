import AlgorithmKit
import SortEngineKit

/// Ported from ArrayV's `StacklessRotateMergeSort` — an in-place merge sort with no recursion (or
/// stack-emulating state machine) at all: it presorts adjacent pairs, then for doubling block
/// widths `j`, uses `partitionMerge` to select-and-rotate the correct smallest-`j` elements of
/// each `2j`-block into its front half in one rotation (a merge-path/co-rank binary search over
/// whichever half is smaller, not a plain value search), then `rotateMerge` re-fixes the seams
/// left inside each half at successively finer granularities (`k = j/2, j/4, ..., 2`), and finally
/// re-runs the pairwise presort at the finest level to catch anything the coarser passes missed.
///
/// `rotate` is the identical Gries-Mills block-rotation primitive
/// `RotateMergeSort`/`RotateLSDRadixSort`/`RotateMSDRadixSort` already ship (confirmed against
/// ArrayV's own `Rotations.griesMills`) — this port keeps its own copy rather than sharing one,
/// matching this codebase's existing convention for that primitive. `partitionMerge`'s selection
/// search is a different technique from `RotateMergeSort`'s own `rotateMerge`, though: it searches
/// by *count* (find the split that selects exactly the `c` smallest elements combined) rather than
/// by value.
///
/// `partitionMerge`'s binary search is a real, genuine bug fix over ArrayV's own Java, found via
/// this codebase's fuzz coverage (a reverse-sorted-length-62-style discovery, in the same spirit as
/// `PoplarHeapSort`'s own real bug): ArrayV initializes the search's lower bound `r1` to a bare
/// `0`, but the standard merge-path/co-rank formulation this technique is based on requires
/// `r1 >= max(0, c - otherSideLength)` — without it, whenever `c` alone already exceeds the
/// *other* side's length (easy to trigger once array sizes stop being tidy powers of two, e.g. a
/// 100-element array reliably hits it), the search probes indices past the array's real bounds.
/// Added the missing lower bound here; everything else translates directly.
public struct StacklessRotateMergeSort: SortAlgorithm {
  public let id = AlgorithmID(rawValue: "stacklessrotatemergesort")
  public let metadata = AlgorithmMetadata(
    displayName: "Stackless Rotate Merge Sort",
    category: .merge,
    sizeRange: 16...256,
    growthModel: OperationGrowthModel(
      anchorSize: 788, coefficients: [230375, 398.357, 0.0874784],
      measuredSafeCeiling: nil),
    detectedGrowthModel: DetectedGrowthModel(
      family: .powerLog, coefficients: [10.6138, 1.21265], rSquared: 0.997967),
    stable: true,
    timeComplexity: ComplexityBounds(
      best: "O(n log n)", average: "O(n log n)", worst: "O(n log n)"),
    spaceComplexity: "O(1)",
    iconName: "arrow.triangle.swap"
  )

  public init() {}

  public func record(into engine: inout RecordingEngine) {
    let n = engine.count
    guard n >= 2 else { return }

    func multiSwap(_ a: Int, _ b: Int, _ len: Int) {
      for i in 0..<len { engine.swap(a + i, b + i) }
    }

    func rotate(_ aIn: Int, _ mIn: Int, _ bIn: Int) {
      var a = aIn
      var m = mIn
      var b = bIn
      var l = m - a
      var r = b - m
      while l > 0 && r > 0 {
        if r < l {
          multiSwap(m - r, m, r)
          b -= r
          m -= r
          l -= r
        } else {
          multiSwap(a, m, l)
          a += l
          m += l
          r -= l
        }
      }
    }

    // Selects the `c` smallest combined elements of already-sorted `[a, m)`/`[m, b)` into the
    // front via one rotation, via a merge-path binary search over whichever half is smaller.
    func partitionMerge(_ a: Int, _ m: Int, _ b: Int, _ cIn: Int) {
      let lenA = m - a
      let lenB = b - m
      guard lenA >= 1, lenB >= 1 else { return }

      if lenB < lenA {
        let c = (lenA + lenB) - cIn
        // Standard merge-path/co-rank bounds: `r1` (elements taken from the `b`-side tail) can
        // never be so small that `c - r1` would exceed `lenA` (ArrayV's own Java omits this lower
        // bound — `r1` starts at a bare 0 — which reads out of range whenever `c` alone already
        // exceeds `lenA`; found via fuzzing, not from the source).
        var r1 = max(0, c - lenA)
        var r2 = min(c, lenB)
        while r1 < r2 {
          let ml = (r1 + r2) / 2
          if engine.compare(m - (c - ml), b - ml - 1, by: (>)) {
            r2 = ml
          } else {
            r1 = ml + 1
          }
        }
        rotate(m - (c - r1), m, b - r1)
      } else {
        var r1 = max(0, cIn - lenB)
        var r2 = min(cIn, lenA)
        while r1 < r2 {
          let ml = (r1 + r2) / 2
          if engine.compare(a + ml, m + (cIn - ml) - 1, by: (>)) {
            r2 = ml
          } else {
            r1 = ml + 1
          }
        }
        rotate(a + r1, m, m + (cIn - r1))
      }
    }

    // Finds the first internal seam in `[a, b)` (the boundary where ascending order breaks) and
    // partition-merges the two sorted pieces on either side of it; a no-op if `[a, b)` is already
    // one ascending run.
    func rotateMerge(_ a: Int, _ b: Int, _ c: Int) {
      var i = a + 1
      while i < b, !engine.compare(i - 1, i, by: (>)) { i += 1 }
      if i < b { partitionMerge(a, i, b, c) }
    }

    func rotatePartitionMergeSort(_ a: Int, _ b: Int) {
      let len = b - a

      var i = a + 1
      while i < b {
        if engine.compare(i - 1, i, by: (>)) { engine.swap(i - 1, i) }
        i += 2
      }

      var j = 2
      while j < len {
        var b1 = 0
        var blockStart = a
        while blockStart + j < b {
          b1 = min(blockStart + 2 * j, b)
          partitionMerge(blockStart, blockStart + j, b1, j)
          blockStart += 2 * j
        }

        var k = j / 2
        while k > 1 {
          var seamStart = a
          while seamStart + k < b1 {
            rotateMerge(seamStart, min(seamStart + 2 * k, b), k)
            seamStart += 2 * k
          }
          k /= 2
        }

        var m = a + 1
        while m < b1 {
          if engine.compare(m - 1, m, by: (>)) { engine.swap(m - 1, m) }
          m += 2
        }

        j *= 2
      }
    }

    rotatePartitionMergeSort(0, n)
  }
}
