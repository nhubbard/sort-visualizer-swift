import AlgorithmKit
import SortEngineKit

/// ArrayV's `DoubleInsertionSort`: an insertion sort that grows its sorted region from the
/// *middle* of the array outward in both directions at once, rather than growing a single
/// sorted prefix from one end. `left`/`right` start as the pair of indices straddling the
/// midpoint (swapped into order first, via the one and only `swap` this algorithm ever does —
/// every other move below is a single-element write, never a two-element swap). Each iteration
/// then absorbs one new element from each side — the (new, live) `array[left]` and
/// `array[right]` — and inserts both into their correct position within the already-sorted
/// middle region, before stepping `left`/`right` one slot further outward.
///
/// Stability: empirically and by construction this *is* stable. The two branches below are
/// asymmetric on purpose (see the strict-vs-non-strict comments inline), and that asymmetry is
/// exactly what preserves original relative order for equal elements:
///   - An element captured from `right` (a larger original index) is shifted with a *non-strict*
///     `<=`/`>=` comparison, so it slides past — and ends up *after* — any equal elements already
///     resident in the region, which all have smaller original indices. Correct: larger index
///     stays later.
///   - An element captured from `left` (a smaller original index) is shifted with a *strict*
///     `<`/`>` comparison in the "else" branch, so it stops *before* any equal elements, ending
///     up *before* them. Correct: smaller index stays earlier.
/// Every move is a single-element write walking one slot at a time — never a swap of
/// non-adjacent elements — so equal elements never leapfrog each other.
public struct DoubleInsertionSort: SortAlgorithm {
    public let id = AlgorithmID(rawValue: "doubleinsertionsort")
    public let metadata = AlgorithmMetadata(
        displayName: "Double Insertion Sort",
        category: .insertion,
        sizeRange: 16...256,
        stable: true,
        timeComplexity: ComplexityBounds(best: "O(n)", average: "O(n^2)", worst: "O(n^2)"),
        spaceComplexity: "O(1)",
        iconName: "distribute.horizontal"
    )
    public init() {}

    public func record(into engine: inout RecordingEngine) {
        let n = engine.count
        guard n > 1 else { return }
        insertionSort(into: &engine, start: 0, end: n)
    }

    /// Ports ArrayV's `insertionSort(array, start, end, sleep, auxwrite)`.
    private func insertionSort(into engine: inout RecordingEngine, start: Int, end: Int) {
        var left = start + (end - start) / 2 - 1
        var right = left + 1

        // Reads.compareIndices(array, left, right, ..., true) > 0 — strict, both indices live.
        if engine.compare(left, right, by: (>)) {
            engine.swap(left, right)
        }
        left -= 1
        right += 1

        while left >= start && right < end {
            // Reads.compareIndices(array, left, right, ..., true) > 0 — strict, both indices live.
            if engine.compare(left, right, by: (>)) {
                // `leftItem`/`rightItem` are captured *before* either while-loop below writes
                // anything, matching ArrayV's `leftItem = array[right]; rightItem = array[left];`
                // ordering exactly.
                let leftItem = engine.values[right]
                let rightItem = engine.values[left]

                var pos = left + 1
                // Reads.compareValues(array[pos], leftItem) <= 0 — non-strict: `leftItem` came
                // from `right` (a larger original index), so it must slide past any elements
                // already equal to it and land *after* them to stay stable.
                while pos <= right && engine.values[pos] <= leftItem {
                    engine.setValue(pos - 1, engine.values[pos])
                    pos += 1
                }
                engine.setValue(pos - 1, leftItem)

                pos = right - 1
                // Reads.compareValues(array[pos], rightItem) >= 0 — non-strict: `rightItem` came
                // from `left` (a smaller original index), so it must slide past any elements
                // already equal to it and land *before* them to stay stable.
                while pos >= left && engine.values[pos] >= rightItem {
                    engine.setValue(pos + 1, engine.values[pos])
                    pos -= 1
                }
                engine.setValue(pos + 1, rightItem)
            } else {
                let leftItem = engine.values[left]
                let rightItem = engine.values[right]

                var pos = left + 1
                // Reads.compareValues(array[pos], leftItem) < 0 — strict (unlike the `if`
                // branch's `<=` above): this branch's `leftItem` is the smaller-or-equal of the
                // two new elements (array[left] <= array[right] is exactly why we're in this
                // branch), so it must stop *before* any equal elements to land ahead of them.
                // No `pos <= right` bound check here — ArrayV's own source omits it, and it's
                // safe: the scan can advance at most as far as `right`, whose live value
                // (`rightItem`, unwritten until the second loop below runs) is >= `leftItem` by
                // this branch's own condition, so the loop is guaranteed to stop at or before
                // `pos == right`.
                while engine.values[pos] < leftItem {
                    engine.setValue(pos - 1, engine.values[pos])
                    pos += 1
                }
                engine.setValue(pos - 1, leftItem)

                pos = right - 1
                // Reads.compareValues(array[pos], rightItem) > 0 — strict, held value; same
                // "no explicit bound needed" reasoning as above, mirrored for the left edge.
                while engine.values[pos] > rightItem {
                    engine.setValue(pos + 1, engine.values[pos])
                    pos -= 1
                }
                engine.setValue(pos + 1, rightItem)
            }

            left -= 1
            right += 1
        }

        // Even-length ranges consume both `left` and `right` leftovers in lockstep inside the
        // loop above, so `left` never has unconsumed room once `right` runs out — the trailing
        // block below only ever has to handle a single leftover element, and only on the
        // `right` side (odd-length ranges "waste" their extra element there, since `left`/
        // `right` start straddling the midpoint and step outward one-for-one).
        if right < end {
            var pos = right - 1
            let current = engine.values[right]
            // Reads.compareValues(array[pos], current) > 0 — strict, held value. ArrayV's own
            // source has no `pos >= start` bound check here, but unlike every other unbounded
            // scan in this method, this one is NOT provably safe: the trailing element can be
            // smaller than *every* element of the sorted region built so far (e.g. reverse-sorted
            // input `[2, 1, 0]` inserts a swap-checked `[1, 2]` pair, then this block has to walk
            // `current = 0` all the way past both of them). ArrayV's Java would throw
            // ArrayIndexOutOfBoundsException on that input; a literal port would make Swift trap
            // instead. Confirmed by exhaustive testing (all permutations up to length 7, plus
            // hundreds of thousands of random/duplicate-heavy trials) that this is the *only*
            // unguarded access in the whole algorithm that can actually go out of bounds — every
            // other unbounded scan above really is safe by the invariants noted at each site. So
            // this one spot gets the same kind of `pos >= start &&` guard ArrayV's own `if`
            // branch already uses for its analogous scans, without touching the comparison's
            // strictness.
            while pos >= start && engine.values[pos] > current {
                engine.setValue(pos + 1, engine.values[pos])
                pos -= 1
            }
            engine.setValue(pos + 1, current)
        }
    }
}
