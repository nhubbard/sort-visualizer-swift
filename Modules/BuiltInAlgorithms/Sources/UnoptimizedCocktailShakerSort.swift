import AlgorithmKit
import SortEngineKit

/// ArrayV's `io.github.arrayv.sorts.exchange.UnoptimizedCocktailShakerSort` — the same bidirectional
/// bubble-sweep shape as `CocktailShakerSort.swift` and `OptimizedCocktailShakerSort.swift`, but with
/// every adaptive optimization those two siblings rely on deliberately stripped out.
///
/// ## What makes this "unoptimized" relative to its two siblings
///
/// `CocktailShakerSort` tracks a single `sorted` flag across each full forward-then-backward pass
/// and `break`s out of its outer loop the instant a pass makes zero swaps.
/// `OptimizedCocktailShakerSort` goes further, tracking a *consecutive-no-swap* counter separately
/// for each sweep direction and shrinking `start`/`end` by exactly that amount every pass — so a
/// sweep that finishes several already-sorted trailing elements skips re-scanning them next time.
///
/// This variant does neither. The outer loop runs a hard-coded `n / 2` times no matter what — there
/// is no swap-tracking flag anywhere, so nothing can ever `break` out early — and each pass always
/// scans the exact range `[i, n - i - 1)` forward and `(i, n - i - 1]` backward, where `i` is simply
/// the outer loop's own counter. That range shrinks by exactly one element per side per pass
/// (mirroring `i`'s own increment), regardless of whether the array became fully sorted on pass one
/// or is still a mess on the second-to-last pass — the shrink is scheduled by the loop counter, not
/// by anything the sort observes about the data.
///
/// ## Complexity: the "unoptimized" label costs a best case, not just a constant factor
///
/// For `CocktailShakerSort`/`OptimizedCocktailShakerSort`, an already-sorted input is detected on the
/// very first pass (zero swaps happen, the no-swap counter immediately covers the whole remaining
/// range), giving both siblings a genuine `O(n)` best case. This algorithm has no mechanism that
/// could ever short-circuit that way: the number of outer iterations is `n / 2` unconditionally, and
/// each iteration's forward sweep alone costs `(n - 2i - 1)` comparisons regardless of whether every
/// single one of them finds elements already in order. Summed across `i = 0, ..., n/2 - 1`, that is
/// still `Θ(n^2)` total comparisons even when the input is already sorted — the exact same asymptotic
/// bound as the average and worst cases. So **best, average, and worst case are all `Θ(n^2)`** —
/// unlike its two siblings, this variant cannot do better than quadratic on any input, which is
/// precisely the "unoptimized" cost ArrayV's naming calls out: the two adaptive optimizations that
/// give the siblings their `O(n)` best case are exactly the two things removed here. Space is `O(1)`:
/// only the loop counters `i`/`j` are used, no auxiliary buffers.
///
/// ## Stability: `true`, same reasoning as both siblings
///
/// Every swap decision uses a strict comparison — `engine.compare(j, j + 1, by: (>))` on the forward
/// sweep, `engine.compare(j, j - 1, by: (<))` on the backward sweep — never the default `>=`/`<=`.
/// Two adjacent equal elements therefore never trigger a swap in either direction, so equal-valued
/// elements can never cross past one another, which is exactly what keeps `CocktailShakerSort` and
/// `OptimizedCocktailShakerSort` stable too; removing the early-exit/shrink optimizations changes
/// nothing about which swaps happen, only how many *comparisons* are spent confirming that the
/// remaining ones don't need to.
public struct UnoptimizedCocktailShakerSort: SortAlgorithm {
    public let id = AlgorithmID(rawValue: "unoptimizedcocktailshakersort")
    public let metadata = AlgorithmMetadata(
        displayName: "Unoptimized Cocktail Shaker Sort",
        category: .exchange,
        sizeRange: 16...256,
        stable: true,
        timeComplexity: ComplexityBounds(best: "O(n^2)", average: "O(n^2)", worst: "O(n^2)"),
        spaceComplexity: "O(1)",
        iconName: "arrow.left.arrow.right.square"
    )
    public init() {}

    public func record(into engine: inout RecordingEngine) {
        let n = engine.count
        guard n > 1 else { return }

        // Fixed `n / 2` outer passes — no swap-tracking flag, so nothing can ever break out early,
        // unlike `CocktailShakerSort`'s single `sorted` flag or `OptimizedCocktailShakerSort`'s
        // per-direction consecutive-no-swap counters. See the doc comment above for why that is the
        // whole point of this variant.
        var i = 0
        while i < n / 2 {
            // Forward sweep over the fixed range [i, n - i - 1), carrying larger values rightward.
            // Strict `>` (not the default `>=`) is what keeps this stable: a tie never swaps, so
            // equal-valued elements never cross past each other.
            var j = i
            while j < n - i - 1 {
                if engine.compare(j, j + 1, by: (>)) {
                    engine.swap(j, j + 1)
                }
                j += 1
            }

            // Backward sweep over the fixed range (i, n - i - 1], carrying smaller values leftward.
            // Strict `<` mirrors the forward sweep's strict `>` for the same stability reason.
            j = n - i - 1
            while j > i {
                if engine.compare(j, j - 1, by: (<)) {
                    engine.swap(j, j - 1)
                }
                j -= 1
            }

            i += 1
        }
    }
}
