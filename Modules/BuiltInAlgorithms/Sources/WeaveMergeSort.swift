import AlgorithmKit
import SortEngineKit

/// ArrayV's `io.github.arrayv.sorts.hybrid.WeaveMergeSort` — despite the name and the "Merge
/// Sorts"-adjacent recursive shape, this algorithm never actually *merges* by comparing values at
/// all. `weaveMergeSort(min, max)` splits `[min, max]` at `mid = floor((min + max) / 2)`, sorts
/// each contiguous half recursively (same shape as an ordinary top-down merge sort), and then
/// hands the two now-individually-sorted halves to `weaveMerge`, which does two very different
/// things in sequence:
///
/// 1. **Weave**: a purely positional, value-blind "riffle shuffle" of the two sorted halves —
///    left[0], right[0], left[1], right[1], ... — implemented as a chain of adjacent swaps
///    (`multiSwap`) that walks each right-half element leftward into its interleaved slot. This
///    never looks at a single value; it only repositions.
/// 2. **Insert**: `weaveInsert` then runs a full insertion sort (with a tie-swapping shift
///    condition — see the stability note below) over the *entire* just-woven range to actually
///    restore sorted order, since interleaving two sorted runs by position (rather than by value)
///    does not itself produce anything close to a sorted sequence in general.
///
/// This means the "merge" step here does strictly more comparison/shift work than a textbook
/// merge — see the complexity note below — in exchange for code simplicity: the whole algorithm
/// is built from two primitives (`multiSwap`'s swap-chain and a classic insertion-sort shift)
/// instead of a merge routine that has to track two read cursors into two already-ordered runs.
///
/// ## Translating `Writes.multiSwap`
///
/// ArrayV's `Writes.multiSwap(array, pos, to, ...)` is NOT a single two-element swap despite the
/// name suggesting an atomic multi-way exchange — it is a *chain* of adjacent single swaps that
/// walks the element originally at `pos` all the way to slot `to`, shifting every element between
/// them over by one, exactly like repeatedly bubbling one element past its neighbors:
/// ```java
/// if (to - pos > 0) {
///     for (int i = pos; i < to; i++) { this.swap(array, i, i + 1, ...); }
/// } else {
///     for (int i = pos; i > to; i--) { this.swap(array, i, i - 1, ...); }
/// }
/// ```
/// There is no `multiSwap` primitive on `RecordingEngine` (nor should there be — every other
/// ported algorithm that needs a "shift" builds it from repeated `engine.swap` calls too, e.g.
/// `BinaryInsertionSort`), so `multiSwap` below is a direct transliteration of that same loop.
///
/// `weaveMerge`'s two `multiSwap` calls per iteration — `multiSwap(mid + i, min + i*2 - 1)` for
/// `i` in `1...(mid - min)` — always walk *backward* (`to < pos`, since `mid + i <= max` and
/// `min + i*2 - 1` is always well to the left of it for every `i` in range), each one dragging the
/// right half's `i`-th element leftward into the next open interleaved slot while shifting the
/// left half's tail rightward by one to make room. Hand-simulating this on paper for several
/// `(min, mid, max)` triples (both the even-length case, e.g. `min=0, mid=3, max=7`, and the
/// odd-length case where the left half is exactly one element longer, e.g. `min=0, mid=4, max=8`
/// — `mid - min` is always either equal to `max - mid` or exactly one more, since `mid` is a floor
/// midpoint, so the left half is never shorter than the right) confirms the loop's net effect,
/// once every iteration has run: the range `[min, max]` ends up holding `left[0], right[0],
/// left[1], right[1], ..., ` with any single unpaired leftover left-half element (only possible
/// when the left half is longer) appended at the very end. That is exactly a riffle/weave
/// interleave of the two already-sorted halves — hence the algorithm's name.
///
/// ## Stability: empirically `false`
///
/// The naive argument for instability is the `weaveInsert` shift condition itself: ArrayV's
/// `while (pos > start && Reads.compareValues(arr[pos], arr[pos - 1]) < 1)` continues shifting
/// while `arr[pos] <= arr[pos - 1]` — a **non-strict** condition, so a newly-encountered element
/// keeps sliding left *past* every element already in place that is merely equal to it (not just
/// the ones strictly greater), rather than stopping the instant it meets an equal element the way
/// a stable insertion-sort shift (`<` rather than `<=`) would. That reverses the relative order of
/// any run of ties within a single `weaveInsert` pass: whichever equal element `weaveInsert`'s
/// outer loop reaches *later* (i.e. sits further right in the just-woven array) ends up shifted to
/// the *left* of — output-order *before* — any equal element already resting there from an
/// earlier outer-loop iteration.
///
/// Working out by hand whether that reversal at the `weaveInsert` stage cancels out or compounds
/// with the position-blind weave stage and the recursive calls below it (each level of recursion
/// runs this exact same algorithm on a sub-range, so any instability at a deeper level feeds back
/// into a shallower level's weave/insert pass) is not tractable by inspection alone — unlike
/// `DoubleInsertionSort`, there is no clean invariant here that visibly cancels the asymmetry out.
/// So, mirroring the empirical approach `WeavedMergeSort`/`StaticSort`/`FlashSort` already
/// establish in this codebase: rather than trust a hand-proof, this was checked directly by
/// recording tagged-duplicate input (values combined with an original-index tag, sorting purely on
/// the untagged key while tracking each tag's final resting position by replaying the recorded
/// tape's swaps) across hundreds of randomized trials with heavy duplication. Ties do come out
/// reordered relative to their original input order — see
/// `NativeAlgorithmCorrectnessTests.weaveMergeSortTiedElementsCanLoseTheirOriginalRelativeOrder`
/// — so this is **not** a stable sort, confirming the naive argument above rather than
/// contradicting it.
///
/// ## Complexity
///
/// There is no scratch buffer anywhere in this algorithm — `multiSwap`'s shift-chain and
/// `weaveInsert`'s shift-chain are both built entirely from in-place `swap`s, unlike
/// `WeavedMergeSort`'s real `O(n)` merge buffer. The only space this recursion consumes is its own
/// call stack: `weaveMergeSort` halves its range on every recursive call (same shape as an
/// ordinary top-down merge sort's recursion), so the stack depth is `O(log n)` — matching
/// `QuickSort`'s in-place-partition recursion rather than a buffer-backed sort like `MergeSort`.
///
/// Time complexity is quadratic in every case, not `O(n log n)` the way the "Merge"-shaped
/// recursion might suggest. Even on already-sorted input, weaving two sorted halves together by
/// *position* rather than by value produces a sequence with `O(n^2)` inversions in general — e.g.
/// for a fully ascending input split into contiguous halves, every element of the (necessarily
/// larger-valued) right half is `>` every element of the left half's tail, so the woven sequence
/// `left[0], right[0], left[1], right[1], ...` has `right[0]` sitting out of place ahead of most of
/// `left`, `right[1]` ahead of most of what's left of `left`, and so on — `Θ((n/2)^2)` inversions
/// for that single weave, which `weaveInsert`'s insertion sort then has to pay `Θ(1)` work per
/// inversion to fix. Summed geometrically over `O(log n)` recursion levels (each level's combine
/// cost dominates the sum, the same way it does in a naive `O(n^2)`-merge mergesort variant), the
/// total is `Θ(n^2)` — for the best, average, *and* worst case alike, since the adversarial-looking
/// interleaving inversion count shows up even on already-sorted input.
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
            let mid = (min + max) / 2 // Swift integer division already floors for non-negative bounds.
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
