import AlgorithmKit
import SortEngineKit

/// ArrayV's own doc comment: "Bingo Sort is a variant of Selection Sort which looks through all
/// elements, using the element with the maximum VALUE instead of the item to be swapped instead
/// of the item. This is best suited to use when there are duplicate values in the array because
/// the sort will run quicker (similar to Counting Sort) - running on O(n+m^2) best case scenario,
/// otherwise it will run at O(n*m) time complexity, where 'm' is the amount of unique values in
/// the array."
///
/// Working backward from the end, each round targets the current maximum *value* (`val`) rather
/// than a single index: every element equal to `val` gets swapped into the shrinking tail in one
/// pass, while the pass simultaneously tracks the second-highest value seen (`next`) to become the
/// following round's target. Plain Selection Sort would need one full pass per single element even
/// among ties — Bingo Sort clears every tied duplicate in the same pass its target was found in.
public struct BingoSort: SortAlgorithm {
    public let id = AlgorithmID(rawValue: "bingosort")
    public let metadata = AlgorithmMetadata(
        displayName: "Bingo Sort",
        category: .selection,
        sizeRange: 16...512,
        stable: false,
        timeComplexity: ComplexityBounds(best: "O(n+m^2)", average: "O(n\\times m)", worst: "O(n\\times m)"),
        spaceComplexity: "O(1)",
        iconName: "target"
    )
    public init() {}

    public func record(into engine: inout RecordingEngine) {
        let n = engine.count
        guard n > 1 else { return }

        var maximum = n - 1
        // `next` is a held value, not a live index — same held-value-vs-array-value pattern as
        // CycleSort's cached `t`, so this reads `engine.values` directly instead of going through
        // `engine.compare` (which only supports index-vs-index comparisons).
        var next = engine.values[maximum]
        var i = maximum - 1
        while i >= 0 {
            if engine.values[i] > next {
                next = engine.values[i]
            }
            i -= 1
        }
        // Skip past any elements at the tail that already equal the true maximum — nothing to do
        // for them yet.
        while maximum > 0 && engine.values[maximum] == next {
            maximum -= 1
        }

        while maximum > 0 {
            let val = next
            next = engine.values[maximum]

            // `j`'s starting bound is fixed here, before any swaps in this pass can move
            // `maximum` — mirrors ArrayV's `for (int j = maximum - 1; j >= 0; j--)`, whose
            // initializer runs exactly once even though the loop body mutates `maximum`.
            var j = maximum - 1
            while j >= 0 {
                // Held-value equality against the local `val` — ArrayV routes this one through
                // `Reads.compareValues` for its own stat tracking, but `val` is still a local, not
                // a live index, so the held-value pattern applies regardless: read directly.
                if engine.values[j] == val {
                    engine.swap(j, maximum)
                    maximum -= 1
                } else if engine.values[j] > next {
                    next = engine.values[j]
                }
                j -= 1
            }
            while maximum > 0 && engine.values[maximum] == next {
                maximum -= 1
            }
        }
    }
}
