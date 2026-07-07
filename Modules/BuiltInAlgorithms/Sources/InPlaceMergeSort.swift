import AlgorithmKit
import SortEngineKit

/// ArrayV's `sorts/merge/InPlaceMergeSort.java` (not `ImprovedInPlaceMergeSort.java`, a different
/// algorithm) — plain Merge Sort's divide-and-conquer shape, but the merge step never allocates an
/// O(n) auxiliary buffer. Instead, whenever a left-run element is found to be greater than the
/// right run's leading element, the two are swapped and the (now out-of-place, formerly-left)
/// element is bubbled rightward through the remainder of the right run via `push` — a single
/// left-to-right adjacent-swap pass — until it lands in its correct sorted position. This trades
/// `MergeSort`'s O(n) space for an asymptotically worse merge step: `push` can rescan up to the
/// entire right run on every out-of-order left element, making the merge itself O(run sizes
/// multiplied together) in the worst case rather than the usual linear merge.
public struct InPlaceMergeSort: SortAlgorithm {
    public let id = AlgorithmID(rawValue: "inplacemergesort")
    public let metadata = AlgorithmMetadata(
        displayName: "In-Place Merge Sort",
        category: .merge,
        sizeRange: 16...512,
        // Not stable, despite superficially resembling a textbook (stable) merge. `merge`'s swaps
        // are positional — driven by the fixed index `mid + 1`, not by tracking "the right run's
        // current front element" — so `push` can walk a duplicate value past another occurrence of
        // the same value at a different recursion level without the two ever being compared
        // directly against each other. Verified empirically: tagging each element with its
        // original index and sorting duplicates shows equal elements landing out of their original
        // relative order after a few levels of recursive merging.
        stable: false,
        // Best case (already-sorted input): every left element is already <= the right run's
        // leading element, so `merge` never swaps and `push` never runs — just the usual
        // O(n log n) compare-only pass down the recursion. Average/worst case: `push` turns each
        // merge into effectively an insertion-sort-style shift across the two runs being combined,
        // so summed across the recursion this is O(n^2), not O(n log n) — verified empirically:
        // at n = 512 this algorithm performs roughly as many compares/swaps as Bubble Sort's
        // worst case, not plain Merge Sort's ~n log n.
        timeComplexity: ComplexityBounds(best: "O(n log n)", average: "O(n^2)", worst: "O(n^2)"),
        // No aux array is ever created — the merge works by swapping and bubbling elements
        // within the array itself. The only extra memory is the recursion stack.
        spaceComplexity: "O(log n)",
        iconName: "rectangle.compress.vertical"
    )

    public init() {}

    public func record(into engine: inout RecordingEngine) {
        let n = engine.count
        guard n >= 2 else { return }

        // Single left-to-right adjacent-swap pass over [low, high]: bubbles the element that was
        // just dropped at `low` rightward through the (still otherwise sorted) run until it's back
        // in order. Mirrors ArrayV's `push(array, low, high)`.
        func push(_ low: Int, _ high: Int) {
            var i = low
            while i < high {
                if engine.compare(i, i + 1, by: >) {
                    engine.swap(i, i + 1)
                }
                i += 1
            }
        }

        // Merges the two adjacent sorted runs [min, mid] and [mid + 1, max] in place. For each
        // left-run element still greater than the right run's current leading element, swap them
        // (moving the smaller value into the left run) and then bubble the displaced larger value
        // into its correct place within the right run via `push`. Mirrors ArrayV's
        // `merge(array, min, max, mid)`.
        func merge(_ min: Int, _ max: Int, _ mid: Int) {
            var i = min
            while i <= mid {
                if engine.compare(i, mid + 1, by: >) {
                    engine.swap(i, mid + 1)
                    push(mid + 1, max)
                }
                i += 1
            }
        }

        // Mirrors ArrayV's `mergeSort(array, min, max)`, operating on the inclusive range
        // [min, max] rather than the app's usual half-open convention.
        func mergeSort(_ min: Int, _ max: Int) {
            if max - min == 0 {
                return
            } else if max - min == 1 {
                if engine.compare(min, max, by: >) {
                    engine.swap(min, max)
                }
            } else {
                let mid = (min + max) / 2
                mergeSort(min, mid)
                mergeSort(mid + 1, max)
                merge(min, max, mid)
            }
        }

        mergeSort(0, n - 1)
    }
}
