import AlgorithmKit
import SortEngineKit

/// Ported from ArrayV's `SlowSort` (`sorts/exchange/SlowSort.java`) — a deliberately inefficient
/// "multiply and surrender" sort in the same spirit as `StoogeSort`, but structurally different and
/// asymptotically worse. `slowSort(i, j)` recursively sorts the two halves `[i, m]`/`[m+1, j]`
/// (`m` the midpoint), settles the larger of `A[m]`/`A[j]` into position `j` via a single strict
/// compare-and-swap, then recurses on everything *except* that now-settled position, `[i, j-1]`.
/// The net effect is a recursive, divide-and-conquer restatement of selection sort: each top-level
/// call finds the maximum of `[i, j]` (itself via a tournament of recursive calls, not a linear
/// scan) and settles it at `j`, then repeats one slot to the left. ArrayV's own
/// `setUnreasonablySlow(true)`/`setUnreasonableLimit(150)` flags this as deliberately impractical,
/// though — unlike Bogo/Bozo Sort — it is fully deterministic with a real (if enormous) bound, not
/// an open-ended random walk.
public struct SlowSort: SortAlgorithm {
    public let id = AlgorithmID(rawValue: "slowsort")
    /// `16...64`, deliberately smaller than `StoogeSort`'s `16...128`: Slow Sort's true worst-case
    /// growth (`O(n^(log n))`, i.e. `n` raised to a *growing* exponent) far outpaces Stooge Sort's
    /// merely-polynomial `O(n^2.71)`. Empirically, sorting a random 64-element array here takes
    /// ~166,000 `compare` calls (vs. Stooge Sort's ~266,000 calls at its own max of 128) — a
    /// comparable recorded-tape footprint, even though Slow Sort's `n` is half of Stooge's. Pushing
    /// much past 64 grows the tape catastrophically (a random 128-element run takes ~7.4 million
    /// compares, and 150 — ArrayV's own cap — takes ~19 million), so 64 is chosen as the practical
    /// ceiling for this engine's fully-instrumented recording rather than ArrayV's own raw-loop cap.
    /// `stable: false`. Even though the settling swap only fires on a *strict* `A[m] > A[j]` (so
    /// two equal elements are never directly swapped against each other), the recursive "tournament
    /// of maxima" that decides what ends up at `m`/`j` in the first place shuffles equal-valued
    /// elements past one another well before that final compare ever sees them — confirmed by
    /// simulating the recursion over `(value, originalIndex)` pairs with several repeated values:
    /// elements sharing a value do not come out in their original relative order.
    public let metadata = AlgorithmMetadata(
        displayName: "Slow Sort",
        category: .exchange,
        sizeRange: 16...64,
        stable: false,
        timeComplexity: ComplexityBounds(best: "O(n^(log n))", average: "O(n^(log n))", worst: "O(n^(log n))"),
        spaceComplexity: "O(log n)",
        iconName: "tortoise.fill"
    )

    public init() {}

    public func record(into engine: inout RecordingEngine) {
        guard engine.count > 1 else { return }
        slowSort(&engine, 0, engine.count - 1)
    }

    /// Ported faithfully from ArrayV's `SlowSort.slowSort(A, i, j)`. `Reads.compareValues(A[m],
    /// A[j]) == 1` is a STRICT greater-than on the two array *values* at indices `m`/`j`, so it maps
    /// to `engine.compare(m, j, by: (>))` rather than the engine's default `(>=)` comparator —
    /// using `>=` here would swap even when `A[m] == A[j]`, which changes nothing about the final
    /// sorted values but would corrupt the relative order of equal elements even further than this
    /// algorithm already does on its own (see the stability note on `metadata` below).
    private func slowSort(_ engine: inout RecordingEngine, _ i: Int, _ j: Int) {
        if i >= j {
            return
        }
        let m = i + (j - i) / 2
        slowSort(&engine, i, m)
        slowSort(&engine, m + 1, j)
        if engine.compare(m, j, by: (>)) {
            engine.swap(m, j)
        }
        slowSort(&engine, i, j - 1)
    }
}
