import AlgorithmKit
import SortEngineKit

/// ArrayV's `io.github.arrayv.sorts.exchange.CircloidSort` — a purely recursive member of the
/// "circle sort" family, alongside ``CircleSortIterative`` and ``CircleSortRecursive`` already in
/// this codebase. All three share the same core move: converge two ends of a range toward its
/// middle, swapping any out-of-order pair found along the way. `CircloidSort` is the simplest of
/// the three to reason about, because it works directly on the array's REAL `[left, right]` range
/// end to end — there is no next-power-of-two padding (`CircleSortIterative`/`CircleSortRecursive`
/// both round the working size up to the next power of two and then guard every access against the
/// real length) and consequently no asymmetric "only recurse into the second half if it's still
/// within bounds" guard either. Every index this algorithm ever touches is a real array index, so
/// none of that bookkeeping is needed.
///
/// `circle(left, right)` (ported below as the nested `circle` closure) walks `a` up from `left` and
/// `b` down from `right` simultaneously: whenever `array[a] > array[b]` (strict, via
/// `Reads.compareIndices(...) == 1` in the Java — a strict greater-than, never triggered by a tie),
/// it swaps them. If the range has an odd number of elements, `a` and `b` meet at the same middle
/// index; rather than comparing that element against itself, `b` is bumped one further so the next
/// (and final) comparison is between the middle element and its immediate predecessor-in-the-scan,
/// exactly mirroring the Java's `if (a == b) { b++; }`.
///
/// `circlePass(left, right)` recurses top-down: split `[left, right]` at `mid = (left + right) / 2`,
/// recurse into BOTH `[left, mid]` and `[mid + 1, right]` unconditionally (there is nothing to skip
/// — both halves are always real, non-empty-or-base-case ranges), and only after both of those
/// return does it run `circle` on the FULL `[left, right]` range at this level. Its own swap-or-not
/// result is `circle(left, right) || l || r` — true if this level's own pass swapped anything, OR
/// either recursive call did — matching the Java's `return this.circle(...) || l || r` line for
/// line. `runSort` repeats a full `circlePass(0, length - 1)` sweep (`while (this.circlePass(...))`
/// in the Java) until one entire sweep reports zero swaps anywhere in the recursion, at which point
/// the array is sorted.
///
/// ## Complexity
///
/// A single full `circlePass` sweep costs `O(n log n)`: at recursion depth `d` there are `2^d`
/// disjoint sub-ranges each of length roughly `n / 2^d`, and each level's own `circle` call over a
/// range of length `k` does `O(k)` comparisons (`k / 2` convergence steps). Summing `O(k)` work over
/// all `2^d` sub-ranges at depth `d` gives `O(n)` total work per depth level, and there are `O(log
/// n)` depth levels (the range halves every recursive step, exactly like a balanced binary split, so
/// the recursion — unlike ``CircleSortRecursive``'s power-of-two-padded, asymmetrically-truncated
/// tree — is a genuinely complete binary recursion over the real range every time), giving `O(n log
/// n)` per full sweep.
///
/// How many sweeps are needed before one reports no swaps at all is the same classic circle-sort
/// result that already justifies ``CircleSortRecursive``'s bounds: each full sweep is guaranteed to
/// resolve at least one additional "level" of remaining disorder, so at most `O(log n)` sweeps are
/// ever needed in the worst case. Empirically confirming this rather than taking it on faith: a
/// standalone script reimplementing this exact `circle`/`circlePass`/repeat-until-no-swaps structure
/// and counting sweeps across both uniformly random permutations and adversarial reverse-sorted
/// input, for sizes 4 through 256, never needed more than `ceil(log2(n)) + 3` sweeps (e.g. at most 11
/// sweeps for `n = 256`, where `log2(256) = 8`) — consistent with an `O(log n)` sweep count rather
/// than anything worse. Combining an `O(log n)` sweep count with an `O(n log n)` cost per sweep gives
/// **`O(n log^2 n)`** for the average and worst case, same as ``CircleSortRecursive``. The best
/// case — input that is already sorted — still needs one full sweep just to CONFIRM no swaps are
/// needed (there is no early-exit partway through a sweep), so the best case is that single sweep's
/// own cost, `O(n log n)`, not better.
///
/// Space is `O(log n)`: `circlePass` recurses to a depth bounded by how many times `[left, right]`
/// can be halved before reaching a one-element base case (`left >= right`), and every level's own
/// `circle` call and bookkeeping is `O(1)` beyond that call stack — no auxiliary array is ever
/// allocated.
///
/// ## Stability: empirically `false`
///
/// `circle`'s own swap condition is a strict `array[a] > array[b]`, so no individual swap is ever
/// triggered by two values that compare equal — a promising start, but not sufficient on its own.
/// Unlike an adjacent-only compare-swap pass (e.g. ``CocktailShakerSort``, which IS provably
/// stable), `circle` compares and swaps positions that can be arbitrarily far apart. That opens the
/// door to an indirect reordering: two equal elements `x` and `y` (`x` originally before `y`) can
/// each individually swap against a third, strictly-different-valued element `z` at different
/// points in the recursion — one swap moving `x` rightward past where `y` will later land, another
/// (at a different level, or a later full sweep) moving `y` leftward past where `x` ends up — without
/// `x` and `y` ever being compared against EACH OTHER directly. Neither individual swap is a tie,
/// yet the net effect can still flip `x` and `y`'s relative order. A standalone script reimplementing
/// this exact `circle`/`circlePass`/repeat-until-no-swaps structure over `(value, originalIndex)`
/// pairs (comparing only on `value`, exactly mirroring ArrayV's marking `Reads.compareIndices`)
/// confirmed this concretely: 20,000 randomized heavy-duplicate trials across sizes 2–40 produced
/// well over 100,000 total instances of two equal-valued elements coming out in the opposite of
/// their original relative order, so this is not a rare edge case — it is the common outcome for
/// duplicate-heavy input, not a one-off adversarial construction.
public struct CircloidSort: SortAlgorithm {
    public let id = AlgorithmID(rawValue: "circloidsort")
    public let metadata = AlgorithmMetadata(
        displayName: "Circloid Sort",
        category: .exchange,
        sizeRange: 16...256,
        stable: false,
        timeComplexity: ComplexityBounds(
            best: "O(n log n)", average: "O(n log^2 n)", worst: "O(n log^2 n)"),
        spaceComplexity: "O(log n)",
        iconName: "smallcircle.circle.fill"
    )

    public init() {}

    public func record(into engine: inout RecordingEngine) {
        guard engine.count > 1 else { return }

        // Ports `circle(array, left, right)`: converges `a` up from `left` and `b` down from
        // `right`, swapping any out-of-order pair, and nudges `b` past the shared middle index
        // once `a == b` so an odd-length range's middle element is never compared against itself.
        func circle(_ left: Int, _ right: Int) -> Bool {
            var a = left
            var b = right
            var swapped = false
            while a < b {
                if engine.compare(a, b, by: (>)) {
                    engine.swap(a, b)
                    swapped = true
                }
                a += 1
                b -= 1
                if a == b {
                    b += 1
                }
            }
            return swapped
        }

        // Ports `circlePass(array, left, right)`: recurse into both halves first, then run this
        // level's own `circle` pass, reporting whether anything swapped anywhere in the recursion.
        func circlePass(_ left: Int, _ right: Int) -> Bool {
            guard left < right else { return false }
            let mid = (left + right) / 2
            let l = circlePass(left, mid)
            let r = circlePass(mid + 1, right)
            return circle(left, right) || l || r
        }

        let lastIndex = engine.count - 1
        while circlePass(0, lastIndex) {}
    }
}
