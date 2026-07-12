import AlgorithmKit
import SortEngineKit

/// ArrayV's `BinaryDoubleInsertionSort`: a binary-search-accelerated sibling of
/// `DoubleInsertionSort` (see that file's header for the shared middle-outward-growth shape).
/// `i`/`j` still start as the pair of indices straddling the midpoint (swapped into order first,
/// via the one and only `swap` this algorithm ever does) and still step outward one slot per
/// iteration, absorbing one new element from each side per pass. The difference is entirely in
/// *how* each of those two new elements gets inserted: instead of a linear scan-while-shifting
/// loop that compares against one array slot at a time, this binary-searches the sorted middle
/// region for the element's exact destination first (`leftBinarySearch`/`rightBinarySearch`),
/// then performs a single shift-and-drop pass to get it there (`insertToLeft`/`insertToRight`).
/// Binary search cuts the number of *comparisons* per insertion from O(n) to O(log n), but the
/// shift itself is still a linear walk over the elements between the old and new position, so the
/// total element-move count — and thus the overall time bound — is unchanged from the sibling.
///
/// Stability: empirically and by construction this *is* stable, for exactly the sibling's
/// reason, just phrased in terms of binary-search insertion points instead of scan-stop
/// conditions:
///   - An element captured from `j` (a larger original index) is searched for with
///     `rightBinarySearch`'s *strict* `<` (an upper-bound search: the first position whose
///     resident value is strictly greater), so it lands *after* every element already resident
///     that compares equal to it. Correct: larger index stays later.
///   - An element captured from `i` (a smaller original index) is searched for with
///     `leftBinarySearch`'s *non-strict* `<=` (a lower-bound search: the first position whose
///     resident value is greater-or-equal), so it lands *before* every element already resident
///     that compares equal to it. Correct: smaller index stays earlier.
/// Every move inside `insertToLeft`/`insertToRight` is a single-element write walking one slot at
/// a time — never a swap of non-adjacent elements — so equal elements never leapfrog each other.
public struct BinaryDoubleInsertionSort: SortAlgorithm {
    public let id = AlgorithmID(rawValue: "binarydoubleinsertionsort")
    public let metadata = AlgorithmMetadata(
        displayName: "Binary Double Insertion Sort",
        category: .insertion,
        sizeRange: 16...256,
        stable: true,
        timeComplexity: ComplexityBounds(best: "O(n)", average: "O(n^2)", worst: "O(n^2)"),
        spaceComplexity: "O(1)",
        iconName: "square.split.2x1"
    )
    public init() {}

    public func record(into engine: inout RecordingEngine) {
        let n = engine.count

        // ArrayV's `leftBinarySearch(array, a, b, val, sleep)`: `val` is a value already read out
        // into a local (see the `l`/`r` captures in `doubleInsertion` below) rather than a value
        // still live at some index, so this is the held-value-vs-array-value pattern (matching
        // `CycleSort.countLesser`/`SimplifiedLibrarySort.gapSearch`), not `engine.compare`.
        // Reads.compareValues(val, array[m]) <= 0 — NON-STRICT: this is a lower-bound search, so
        // ties resolve toward the left (`val` ends up *before* any resident equal elements).
        func leftBinarySearch(_ a: Int, _ b: Int, _ val: Int) -> Int {
            var lo = a
            var hi = b
            while lo < hi {
                let mid = lo + (hi - lo) / 2
                if val <= engine.values[mid] {
                    hi = mid
                } else {
                    lo = mid + 1
                }
            }
            return lo
        }

        // ArrayV's `rightBinarySearch(array, a, b, val, sleep)`: same held-value shape as above,
        // but Reads.compareValues(val, array[m]) < 0 — STRICT: an upper-bound search, so ties
        // resolve toward the right (`val` ends up *after* any resident equal elements).
        func rightBinarySearch(_ a: Int, _ b: Int, _ val: Int) -> Int {
            var lo = a
            var hi = b
            while lo < hi {
                let mid = lo + (hi - lo) / 2
                if val < engine.values[mid] {
                    hi = mid
                } else {
                    lo = mid + 1
                }
            }
            return lo
        }

        // ArrayV's `insertToLeft(array, a, b, temp, sleep)`: the destination `b` was already
        // pinned down by an exact binary search above, so there's nothing left to compare here —
        // just shift the block `(b, a]` one slot toward `a`, then drop `temp` at `b`.
        func insertToLeft(_ a: Int, _ b: Int, _ temp: Int) {
            var a = a
            while a > b {
                engine.setValue(a, engine.values[a - 1])
                a -= 1
            }
            engine.setValue(b, temp)
        }

        // ArrayV's `insertToRight(array, a, b, temp, sleep)`: mirror image of the above, shifting
        // the block `[a, b)` one slot toward `b`.
        func insertToRight(_ a: Int, _ b: Int, _ temp: Int) {
            var a = a
            while a < b {
                engine.setValue(a, engine.values[a + 1])
                a += 1
            }
            engine.setValue(a, temp)
        }

        // ArrayV's `doubleInsertion(array, a, b, compSleep, sleep)`.
        func doubleInsertion(_ a: Int, _ b: Int) {
            guard b - a >= 2 else { return }

            // Same seed-index arithmetic as the sibling `DoubleInsertionSort.insertionSort`'s
            // `left`/`right`, just renamed `i`/`j` to match ArrayV's own names in this file. For
            // odd-length ranges the two seed indices coincide on a single middle element (`j` ==
            // `i`); the `j > i` guard below skips the swap check in that case, since a lone
            // element trivially needs no ordering fix.
            let j0 = a + (b - a - 2) / 2 + 1
            let i0 = a + (b - a - 1) / 2
            var i = i0
            var j = j0

            // Reads.compareIndices(array, i, j, ..., true) == 1 — STRICT greater-than, both
            // indices live.
            if j > i && engine.compare(i, j, by: (>)) {
                engine.swap(i, j)
            }
            i -= 1
            j += 1

            while j < b {
                // Reads.compareIndices(array, i, j, ..., true) == 1 — STRICT greater-than, both
                // indices live.
                if engine.compare(i, j, by: (>)) {
                    // `l`/`r` are captured *before* either insertion below writes anything,
                    // matching ArrayV's `int l = array[j]; int r = array[i];` ordering exactly.
                    let l = engine.values[j]
                    let r = engine.values[i]

                    // `l` came from `j` (the larger original index): find its destination with
                    // `rightBinarySearch` (strict, upper-bound — lands after resident equals),
                    // then shift it into place with a single `insertToRight` pass.
                    let m = rightBinarySearch(i + 1, j, l)
                    insertToRight(i, m - 1, l)
                    // `r` came from `i` (the smaller original index): find its destination with
                    // `leftBinarySearch` (non-strict, lower-bound — lands before resident
                    // equals), then shift it into place with a single `insertToLeft` pass.
                    let dest = leftBinarySearch(m, j, r)
                    insertToLeft(j, dest, r)
                } else {
                    let l = engine.values[i]
                    let r = engine.values[j]

                    // Branches swapped relative to the `if` above: `l` (from `i`, the smaller
                    // original index) now uses `leftBinarySearch` (non-strict, lower-bound), and
                    // `r` (from `j`, the larger original index) uses `rightBinarySearch` (strict,
                    // upper-bound) — exactly ArrayV's asymmetry, preserved.
                    let m = leftBinarySearch(i + 1, j, l)
                    insertToRight(i, m - 1, l)
                    let dest = rightBinarySearch(m, j, r)
                    insertToLeft(j, dest, r)
                }

                i -= 1
                j += 1
            }
        }

        doubleInsertion(0, n)
    }
}
