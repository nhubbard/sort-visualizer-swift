import AlgorithmKit
import SortEngineKit

/// ArrayV's `sorts/merge/RotateMergeSort.java` — a genuine in-place merge, unlike
/// `InPlaceMergeSort`'s one-element-at-a-time insertion-shifting. It is bottom-up like
/// `BottomUpMergeSort` (`rotateMergeSort` doubles a merge-width `j`, merging adjacent runs of that
/// width across the array on each pass), but each individual merge (`rotateMerge`) never allocates
/// an O(n) temp buffer. Instead:
///
/// 1. Whichever of the two runs being merged is the larger half decides direction (`m-a >= b-m`).
/// 2. That larger half's own midpoint value is captured once, then `binarySearch` finds where that
///    value would land within the *other* run.
/// 3. `rotate` (built from `multiSwap`, a block-swap of two equal-length adjacent ranges) swaps the
///    block between the two found midpoints into correct relative order — a full merge step with no
///    aux storage, just index arithmetic and swaps.
/// 4. `rotateMerge` recurses into the two sub-merges the rotation produced.
///
/// `binarySearch`'s `left`/`right`-biased comparison (`<=` vs `<`) is what keeps this stable:
/// depending on which run the search value came from, the search finds either the leftmost or the
/// leftmost-strictly-after-equal insertion point, so equal elements never cross each other's
/// relative order. Because rotation-based merging with a binary-searched split point still performs
/// a full, linear-in-the-merged-range amount of rotation work per merge (rotation is a
/// constant-multiple of a linear scan, not the quadratic shifting `InPlaceMergeSort`'s `push` does),
/// the overall bound stays the ordinary merge sort O(n log n) — the sophistication here buys
/// in-place-ness without `InPlaceMergeSort`'s quadratic degradation.
public struct RotateMergeSort: SortAlgorithm {
    public let id = AlgorithmID(rawValue: "rotatemergesort")
    public let metadata = AlgorithmMetadata(
        displayName: "Rotate Merge Sort",
        category: .merge,
        sizeRange: 16...512,
        // The `left`/`right`-biased binary search exists specifically to preserve relative order
        // among equal elements across the rotation — verified empirically with tagged-duplicate
        // input (index-tagged values sorted purely on the untagged key retain their original
        // relative order among ties).
        stable: true,
        // Every merge is a real linear-time (in the size of the two runs) merge — the binary search
        // is O(log n) and the rotation it drives moves each element a bounded number of times, so
        // summed across the doubling bottom-up passes this is the ordinary merge sort O(n log n),
        // not `InPlaceMergeSort`'s degraded O(n^2) (that algorithm's `push` step can rescan an
        // entire run per out-of-order element, which this rotation-based merge never does).
        timeComplexity: ComplexityBounds(
            best: "O(n log n)", average: "O(n log n)", worst: "O(n log n)"),
        // No aux array is ever created — `rotate`/`multiSwap` shuffle elements within the array
        // itself. The only extra memory is the recursion stack `rotateMerge` uses.
        spaceComplexity: "O(1)",
        iconName: "arrow.clockwise"
    )

    public init() {}

    public func record(into engine: inout RecordingEngine) {
        let n = engine.count
        guard n >= 2 else { return }

        // Block-swaps the two equal-length adjacent ranges `[a, a+len)` and `[b, b+len)`, one
        // position at a time. Mirrors ArrayV's `multiSwap(array, a, b, len)`.
        func multiSwap(_ a: Int, _ b: Int, _ len: Int) {
            for i in 0..<len {
                engine.swap(a + i, b + i)
            }
        }

        // Rotates the two adjacent blocks `[a, m)` and `[m, b)` so their relative order swaps,
        // without any auxiliary storage — repeatedly block-swapping the smaller of the two
        // remaining sides against an equal-length slice of the other, shrinking whichever side
        // was just fully consumed. Mirrors ArrayV's `rotate(array, a, m, b)`.
        func rotate(_ a: Int, _ m: Int, _ b: Int) {
            var a = a, m = m, b = b
            var l = m - a, r = b - m
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

        // Finds the insertion point for the held `value` within `[a, b)`. `left` selects the
        // comparison bias: `true` finds the leftmost position where `value` could be inserted
        // (`value <= array[mid]`), `false` finds the leftmost position strictly after any equal
        // elements (`value < array[mid]`) — the bias `rotateMerge` picks depends on which run
        // `value` came from, which is what keeps the merge stable. `value` is a held value (read
        // once by the caller, from an index outside the `[a, b)` range being searched here, and
        // never written to during the search), so per this codebase's convention (see `CycleSort`'s
        // `countLesser`), it's compared with plain Swift `<=`/`<` against freshly-read
        // `engine.values[mid]` rather than through `engine.compare`. Mirrors ArrayV's
        // `binarySearch(array, a, b, value, left)`.
        func binarySearch(_ a: Int, _ b: Int, _ value: Int, _ left: Bool) -> Int {
            var a = a, b = b
            while a < b {
                let mid = a + (b - a) / 2
                let comp = left ? value <= engine.values[mid] : value < engine.values[mid]
                if comp {
                    b = mid
                } else {
                    a = mid + 1
                }
            }
            return a
        }

        // Merges the two adjacent sorted runs `[a, m)` and `[m, b)` in place via a single rotation,
        // then recurses into the two sub-merges that rotation produces. Mirrors ArrayV's
        // `rotateMerge(array, a, m, b)`.
        func rotateMerge(_ a: Int, _ m: Int, _ b: Int) {
            let m1: Int, m3: Int
            var m2: Int
            if m - a >= b - m {
                m1 = a + (m - a) / 2
                let value = engine.values[m1]
                m2 = binarySearch(m, b, value, true)
                m3 = m1 + (m2 - m)
            } else {
                m2 = m + (b - m) / 2
                let value = engine.values[m2]
                m1 = binarySearch(a, m, value, false)
                // Java's `m3 = (m2++)-(m-m1)` post-increment: `m3` is computed from `m2`'s value
                // *before* the increment, and only then does `m2` advance by one for use below.
                m3 = m2 - (m - m1)
                m2 += 1
            }
            rotate(m1, m, m2)

            if m2 - (m3 + 1) > 0 && b - m2 > 0 {
                rotateMerge(m3 + 1, m2, b)
            }
            if m1 - a > 0 && m3 - m1 > 0 {
                rotateMerge(a, m1, m3)
            }
        }

        // Bottom-up doubling pass over merge-width `j`, merging every adjacent pair of runs of that
        // width, with one trailing partial merge per pass if `b - a` isn't a multiple of `2*j`.
        // Mirrors ArrayV's `rotateMergeSort(array, a, b)`.
        func rotateMergeSort(_ a: Int, _ b: Int) {
            let len = b - a
            var j = 1
            while j < len {
                var i = a
                while i + 2 * j <= b {
                    rotateMerge(i, i + j, i + 2 * j)
                    i += 2 * j
                }
                if i + j < b {
                    rotateMerge(i, i + j, b)
                }
                j *= 2
            }
        }

        rotateMergeSort(0, n)
    }
}
