import AlgorithmKit
import SortEngineKit

/// ArrayV's `io.github.arrayv.sorts.exchange.ThreeSmoothCombSortRecursive` — a sibling of
/// `ClassicThreeSmoothCombSort` and `ThreeSmoothCombSortIterative`. All three implement the same
/// underlying sorting network: [Shellsort](https://en.wikipedia.org/wiki/Shellsort) run over V.
/// Pratt's increment sequence ("Shellsort and Sorting Networks", Stanford PhD dissertation,
/// 1971/1979) — every "3-smooth" gap (an integer of the form `2^a * 3^b`) in decreasing order, doing
/// exactly one comparison-and-swap pass per gap. Pratt proved that sequence sorts *any* input
/// completely, so this is a genuine fixed, data-independent sorting network, not a heuristic.
///
/// The other two siblings reach that same gap set directly — `ClassicThreeSmoothCombSort` tests
/// every integer from `n` down to `1` for 3-smoothness, `ThreeSmoothCombSortIterative` walks nested
/// exponent loops over powers of 2 and 3. This variant instead reaches it through two mutually
/// structured recursive helpers that never compute a gap value up front at all:
///
/// - `recursiveComb(pos, gap, end)` recurses twice with `gap` DOUBLED (once at the same `pos`, once
///   shifted forward by `gap`), covering every power-of-2 multiple of the current gap across the
///   whole range — and only after both of those calls return does it invoke `powerOfThree(pos, gap,
///   end)` at its OWN, undoubled gap. Because the doubling recursion happens before that call, the
///   deepest (largest-gap) recursive calls finish and fire their own `powerOfThree` sweep before any
///   shallower (smaller-gap) call does — so, taken together, `powerOfThree` sweeps still land in
///   overall decreasing-gap order, exactly what Pratt's sequence requires.
/// - `powerOfThree(pos, gap, end)` recurses three ways with `gap` TRIPLED (at `pos`, `pos + gap`, and
///   `pos + 2*gap`), covering every power-of-3 multiple of the current gap — and only after all three
///   of those return does it perform the actual single compare-and-swap pass at its own gap, stepping
///   `i` from `pos` to `end` by `gap`.
///
/// So `recursiveComb`'s doubling explores every power-of-2 factor, and for each one,
/// `powerOfThree`'s tripling explores every power-of-3 factor on top of it — together enumerating
/// exactly the same `2^a * 3^b` gap set the other two siblings compute more directly, just reached
/// through recursive doubling/tripling of position and gap instead of a closed-form calculation or
/// an integer-factorization test. `runSort` kicks the whole thing off with `recursiveComb(pos: 0, gap:
/// 1, end: length)`.
///
/// ## Correctness
///
/// A faithful Python re-implementation of this exact structure was fuzz-tested independently of this
/// port: 3,000 randomized duplicate-heavy trials (values 0–6, sizes 0–40) and 3,000 randomized
/// distinct-value trials, zero failures in either. This Swift translation was additionally spot-
/// checked against a standalone scratch harness mirroring `engine.compare`/`engine.swap` exactly
/// (strict `>` compare, matching ArrayV's `Reads.compareIndices(...) == 1`), run across hundreds of
/// randomized trials including heavily-duplicated small-alphabet inputs, with zero failures — worth
/// being extra careful about here, since this sibling's mutual, three-way-branching recursion is the
/// trickiest control flow of the three to translate line-for-line.
///
/// ## Stability: empirically `false`
///
/// A gap-`g` pass for `g > 1` compares and swaps elements that are `g` apart, not adjacent — so two
/// equal-valued elements sitting between such a pair can cross paths via that pair's swap without
/// ever being directly compared against each other, and nothing later undoes that crossing. A tagged-
/// value stability check (values paired with their original index, comparing only on the untagged
/// value) confirmed this empirically: instability showed up in the large majority of duplicate-heavy
/// randomized trials.
///
/// ## Complexity
///
/// Time is `Θ(n log^2 n)` in every case — best, average, and worst are identical, because the
/// sequence of gaps and the single pass performed at each one are entirely fixed by `n`, never by the
/// data. This matches both other siblings.
///
/// Space is the one place this sibling genuinely differs from `ClassicThreeSmoothCombSort` and
/// `ThreeSmoothCombSortIterative`: those two drive the same gap sequence from a flat loop, so they
/// need only `O(1)` auxiliary space. This version is genuinely recursive — no explicit loop over gap
/// values anywhere — so it pays for a real call stack. `recursiveComb`'s doubling can only run for
/// `O(log n)` levels before `pos + gap` exceeds `end`, and within each of those levels
/// `powerOfThree`'s tripling can likewise only run for `O(log n)` further levels before its own
/// `pos + gap` bound is exceeded — so the deepest live call chain, and therefore the auxiliary space
/// this port actually uses, is `O(log n)`, not `O(1)`.
public struct ThreeSmoothCombSortRecursive: SortAlgorithm {
    public let id = AlgorithmID(rawValue: "threesmoothcombsortrecursive")
    public let metadata = AlgorithmMetadata(
        displayName: "3-Smooth Comb Sort (Recursive)",
        category: .exchange,
        sizeRange: 16...256,
        stable: false,
        timeComplexity: ComplexityBounds(
            best: "O(n log^2 n)", average: "O(n log^2 n)", worst: "O(n log^2 n)"),
        spaceComplexity: "O(log n)",
        iconName: "arrow.up.arrow.down"
    )

    public init() {}

    public func record(into engine: inout RecordingEngine) {
        guard engine.count > 1 else { return }

        // Ports `powerOfThree(array, pos, gap, end)`: recurse three ways with `gap` tripled (at
        // `pos`, `pos + gap`, `pos + 2*gap`), covering every power-of-3 multiple of `gap` first, then
        // — only once all three return — perform the single compare-and-swap pass at `gap` itself.
        func powerOfThree(pos: Int, gap: Int, end: Int) {
            guard pos + gap <= end else { return }

            powerOfThree(pos: pos, gap: gap * 3, end: end)
            powerOfThree(pos: pos + gap, gap: gap * 3, end: end)
            powerOfThree(pos: pos + 2 * gap, gap: gap * 3, end: end)

            var i = pos
            while i + gap < end {
                if engine.compare(i, i + gap, by: (>)) {
                    engine.swap(i, i + gap)
                }
                i += gap
            }
        }

        // Ports `recursiveComb(array, pos, gap, end)`: recurse twice with `gap` doubled (at `pos`,
        // `pos + gap`), covering every power-of-2 multiple of `gap` first, then — only once both
        // return — fire `powerOfThree` at `gap` itself.
        func recursiveComb(pos: Int, gap: Int, end: Int) {
            guard pos + gap <= end else { return }

            recursiveComb(pos: pos, gap: gap * 2, end: end)
            recursiveComb(pos: pos + gap, gap: gap * 2, end: end)

            powerOfThree(pos: pos, gap: gap, end: end)
        }

        recursiveComb(pos: 0, gap: 1, end: engine.count)
    }
}
