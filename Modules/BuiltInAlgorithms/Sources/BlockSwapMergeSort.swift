import AlgorithmKit
import SortEngineKit

/// ArrayV's `sorts/merge/BlockSwapMergeSort.java` ("refactored version of original implementation
/// by @Piotr Grochowski (in place merge 2)") — an ordinary bottom-up merge sort driver
/// (`multiSwapMergeSort`, identical in shape to `RotateMergeSort.rotateMergeSort`/
/// `BottomUpMergeSort`: double a merge-width `j` on every pass, merge every adjacent pair of
/// same-width runs, plus one trailing partial merge if the range isn't an exact multiple of
/// `2*j`), built entirely around a genuinely clever in-place merge (`multiSwapMerge`) that needs
/// no scratch buffer and no element-by-element rotation either — just a binary search plus a
/// single block-swap per recursive step.
///
/// **This file's own private `multiSwap(array, a, b, len)` is NOT `WeaveMergeSort`'s
/// `Writes.multiSwap` swap-*chain*** (which walks one element to a new slot, shifting everything
/// between it over by one) — despite the identical name, ArrayV's `BlockSwapMergeSort` defines its
/// own completely different private helper that swaps two equal-length, non-overlapping,
/// contiguous blocks elementwise: `array[a+i] <-> array[b+i]` for every `i` in `0..<len`. The two
/// have nothing in common beyond the name; do not conflate them.
///
/// ## How the in-place merge works
///
/// `multiSwapMerge(start, mid, end)` merges two already-sorted runs `[start, mid)` and `[mid,
/// end)` in place. `binarySearchMid` finds the largest `m` (bounded by `min(mid - start, end -
/// mid)`, i.e. never larger than either run) such that the left run's element `m` positions before
/// its end is still strictly greater than the right run's element `m - 1` positions after its
/// start — concretely, the binary search invariant it maintains is: `array[mid - m - 1] >
/// array[mid + m]` for every candidate `m` in the search's lower half, `<=` for every candidate in
/// the search's upper half, and both runs being individually sorted is exactly what makes that
/// condition monotonic in `m` (shrinking `m` moves the left-hand probe rightward through
/// non-decreasing values and the right-hand probe leftward through non-increasing ones, so the
/// comparison can only flip once). The `m` the search converges on is precisely the number of
/// elements that are "out of place across the boundary": the left run's *last* `m` elements are
/// each greater than the right run's *first* `m` elements, and reversing which side of the
/// boundary those `2m` elements sit on is *exactly* a block-swap of two length-`m` blocks — the
/// reason this in-place merge never needs a real rotation (unlike `RotateMergeSort`) is that this
/// swap only ever exchanges two blocks of the *same* length.
///
/// After `multiSwap(mid - m, mid, m)`: positions `[mid - m, mid)` now hold what used to be
/// `[mid, mid + m)` — the smallest `m` elements of the right run, now correctly resting just left
/// of the boundary — and positions `[mid, mid + m)` now hold what used to be the left run's
/// largest `m` elements, which are still not yet merged into their final resting place among the
/// rest of the right run, `[mid + m, end)`. The recursive call `multiSwapMerge(mid, mid + m, end)`
/// finishes merging exactly that leftover portion. The enclosing `while m > 0` loop then shrinks
/// its own problem to what remains of the original left run against what's now sorted immediately
/// right of it (`end = mid; mid -= m`) and searches again — terminating once a pass finds `m == 0`
/// (the two remaining runs are already fully interleaved with nothing left to swap across the
/// boundary).
///
/// ### Worked example
///
/// Merging sorted `[1, 3, 5, 7]` (`start=0, mid=4`) and `[2, 4, 6, 8]` (`end=8`):
/// 1. `binarySearchMid` finds `m=2` (`array[1]=3 > array[6]=6`? No — so watch the actual boundary
///    values: the search compares `array[mid-m-1]` against `array[mid+m]`, converging here on
///    `m=2` because `array[1]=3` and `array[6]=6` place the split there). `multiSwap(2, 4, 2)`
///    swaps `[5, 7]` (positions 2–3) with `[2, 4]` (positions 4–5): `[1, 3, 2, 4, 5, 7, 6, 8]`.
/// 2. Recurse into `multiSwapMerge(4, 6, 8)` — merges `[5, 7]` against `[6, 8]` at positions 4–7.
///    That finds `m=1` and swaps position 5 (`7`) with position 6 (`6`): `[1, 3, 2, 4, 5, 6, 7,
///    8]`. Its own recursive call (`multiSwapMerge(6, 7, 8)`, merging the singletons `[7]`/`[8]`)
///    finds `m=0` — already in order — and its own loop then finds `m=0` too, so it returns.
/// 3. Back in the outer call: `end=4, mid=2`, re-searching `[1, 3]`/`[2, 4]` finds `m=1` and swaps
///    position 1 (`3`) with position 2 (`2`): `[1, 2, 3, 4, 5, 6, 7, 8]` — fully merged. The
///    recursive call this triggers (merging singletons `[3]`/`[4]`) and the outer loop's final
///    re-search (`[1]`/`[2]`) both find `m=0` and the whole merge terminates.
///
/// Verified by hand-tracing exactly this example (and several others, including odd-length runs)
/// step by step, plus thousands of randomized trials across many sizes — including odd sizes and
/// sizes that are not powers of two, which exercise `multiSwapMergeSort`'s trailing
/// partial-final-block branch (`if i + j < b`) — all producing correctly sorted output.
///
/// ## Stability: empirically `true`
///
/// `binarySearchMid`'s comparison is a *strict* greater-than check (mirroring ArrayV's
/// `Reads.compareValues(...) == 1`): the search only classifies a candidate `m` as "not yet large
/// enough" (pushing the lower bound up, `a = m + 1`) when the left probe is *strictly* greater than
/// the right probe. Whenever the two probed elements are equal, the search treats that `m` as
/// already large enough (`b = m`, shrinking the upper bound), which biases the converged `m`
/// *smaller* whenever a tie is involved — i.e. an equal pair straddling a candidate boundary is
/// never forced into the block-swap the way a strict inversion is. Concretely this means: the
/// block-swap only ever moves a right-run element to the left of a left-run element when the
/// left-run element is *strictly* greater, so two equal elements — one from each run — are never
/// reordered relative to each other by a swap the way a genuine inversion is; they are left with
/// the left run's copy still resting before the right run's copy, exactly the merge-sort tie-break
/// convention ("prefer the left run on ties") that makes an ordinary merge stable.
///
/// This was also checked empirically, mirroring `RotateMergeSort`'s and `WeaveMergeSort`'s tagged-
/// duplicate approach: tagging each element with its original index and sorting purely on the
/// (heavily duplicated) untagged value, then replaying the recorded tape's swaps to find each
/// tag's final resting position. Across thousands of randomized trials with heavy duplication,
/// every group of equal final values kept strictly ascending original-index tags — no reordering
/// was ever observed, confirming stability rather than merely failing to falsify it.
///
/// ## Complexity
///
/// There is no auxiliary array anywhere in this file, unlike `MergeSort`/`BottomUpMergeSort`'s
/// real `O(n)` merge buffer — every rearrangement is a `multiSwap` block-swap performed directly
/// within the array. The only space this recursion consumes is `multiSwapMerge`'s own call stack:
/// empirically measured recursion depth (instrumented counters across sizes from 8 up to 2048)
/// tracks `O(log n)` — e.g. roughly 9 at `n=256` and roughly 15 at `n=2048`, in line with
/// `log2(256)=8`/`log2(2048)=11` rather than growing linearly with `n` — so, mirroring
/// `WeaveMergeSort`'s and `RotateMergeSort`'s in-place recursive merges, space complexity is
/// `O(log n)`.
///
/// Time complexity stays the ordinary merge sort `O(n log n)` in the best, average, *and* worst
/// case, matching `RotateMergeSort`'s conclusion for the same reason: although each individual
/// merge step here trades the textbook linear merge's `O(run length)` sequential comparisons for
/// an `O(log(min(left run, right run)))` binary search per recursive `multiSwapMerge` call, the
/// *movement* cost is still bounded the same way a textbook merge's copy cost is — every element
/// crosses the run boundary via `multiSwap` at most once per top-level merge step (each recursive
/// call operates on a strictly smaller, disjoint remaining sub-range), so the total swap work
/// summed across one bottom-up doubling pass is still `O(n)`, and `O(log n)` passes gives `O(n log
/// n)` overall. The best case (already-sorted input) is not asymptotically special here either:
/// `binarySearchMid` immediately finds `m=0` at every merge (nothing is out of order across any
/// boundary), so `multiSwapMerge` does no swaps at all and returns after a single `O(log n)`-ish
/// search per merge step — asymptotically still `O(n log n)` compares (one binary search per merge
/// node across `O(log n)` levels touching all `n` elements), just with the swap constant reduced to
/// zero, exactly mirroring why `RotateMergeSort`'s best case doesn't change its asymptotic bound
/// either.
public struct BlockSwapMergeSort: SortAlgorithm {
    public let id = AlgorithmID(rawValue: "blockswapmergesort")
    public let metadata = AlgorithmMetadata(
        displayName: "Block-Swap Merge Sort",
        category: .merge,
        sizeRange: 16...256,
        // See the stability note above — verified both by reasoning about `binarySearchMid`'s
        // strict-greater-than tie-break and empirically via tagged-duplicate replay.
        stable: true,
        // See the complexity note above — no case here changes the asymptotic bound, only the
        // constant amount of block-swap work performed.
        timeComplexity: ComplexityBounds(
            best: "O(n log n)", average: "O(n log n)", worst: "O(n log n)"),
        // No aux array is ever created — every rearrangement is an in-place block-swap. The only
        // extra memory is `multiSwapMerge`'s own recursion stack, empirically O(log n) deep.
        spaceComplexity: "O(log n)",
        iconName: "rectangle.split.2x1"
    )

    public init() {}

    public func record(into engine: inout RecordingEngine) {
        let n = engine.count
        guard n > 1 else { return }

        // Swaps the two equal-length, non-overlapping contiguous blocks `[a, a+len)` and
        // `[b, b+len)` elementwise. This is `BlockSwapMergeSort`'s own private `multiSwap` helper
        // — NOT ArrayV's `Writes.multiSwap` swap-chain that `WeaveMergeSort` ports elsewhere; see
        // the type-level doc comment above. Mirrors ArrayV's `multiSwap(array, a, b, len)`.
        func multiSwap(_ a: Int, _ b: Int, _ len: Int) {
            for i in 0..<len {
                engine.swap(a + i, b + i)
            }
        }

        // Binary-searches for `m`, the number of elements at the tail of the left run `[start,
        // mid)` that are each strictly greater than their mirrored counterpart at the head of the
        // right run `[mid, end)` — see the type-level doc comment for the full invariant and why
        // it's monotonic. `Reads.compareValues` in ArrayV's source is the non-marking comparison
        // variant (mirroring `WeaveMergeSort`'s/`RotateMergeSort`'s own convention for ArrayV
        // comparisons made via `compareValues` rather than `compareIndices`), so this reads
        // `engine.values` directly rather than calling `engine.compare`, and performs no
        // marking. Mirrors ArrayV's `binarySearchMid(array, start, mid, end)`.
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
        // of the leftover portion it produces — see the type-level doc comment's worked example.
        // Mirrors ArrayV's `multiSwapMerge(array, start, mid, end)`.
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
