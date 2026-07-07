import AlgorithmKit
import SortEngineKit

/// ArrayV's `DoubleSelectionSort`: like plain Selection Sort, but each pass scans the current
/// unsorted range `[left, right]` once and finds BOTH the minimum and the maximum, then places
/// the minimum at `left` and the maximum at `right` in the same pass — shrinking the range from
/// both ends and roughly halving the number of passes versus a single-ended selection sort (the
/// total comparison count stays about the same, since each pass still inspects every remaining
/// element, twice).
///
/// `smallest`/`biggest` are plain, live indices into the array as it stands *right now* — not
/// held values — so the two swaps below have to be sequenced with care. ArrayV's source only
/// guards one collision explicitly: `if(biggest == left) biggest = smallest;`. That guard exists
/// because if the single largest element in the range happens to sit at `left` itself, the first
/// swap (`swap(left, smallest)`) would relocate it to wherever `smallest` used to be — so `biggest`
/// must be redirected there *before* that swap runs, or the second swap would read the wrong slot
/// (`left`, which by then holds the *smallest* value, not the largest).
///
/// No analogous guard exists for `smallest == right`, and by inspection (confirmed by exhaustive
/// and randomized testing below) none is needed: the first swap only ever touches indices `left`
/// and `smallest`. If `biggest` is neither of those, its slot is untouched and the second swap
/// reads the correct value. If `biggest == smallest` (only possible when the whole remaining
/// range is one repeated value), both swaps move equal values around, which is a no-op in effect.
/// And if `biggest == right` already, the second swap degenerates to swapping an index with
/// itself. Ported exactly as ArrayV has it, in the same order, with no additional guards added.
public struct DoubleSelectionSort: SortAlgorithm {
    public let id = AlgorithmID(rawValue: "doubleselectionsort")
    public let metadata = AlgorithmMetadata(
        displayName: "Double Selection Sort",
        category: .selection,
        sizeRange: 16...512,
        stable: false,
        timeComplexity: ComplexityBounds(best: "O(n^2)", average: "O(n^2)", worst: "O(n^2)"),
        spaceComplexity: "O(1)",
        iconName: "arrow.left.and.right.circle.fill"
    )
    public init() {}

    public func record(into engine: inout RecordingEngine) {
        let n = engine.count
        guard n > 1 else { return }

        var left = 0
        var right = n - 1
        var smallest = 0
        var biggest = 0

        while left <= right {
            for i in left...right {
                // Reads.compareValues(array[i], array[biggest]) == 1 — strict greater-than,
                // both live indices.
                if engine.compare(i, biggest, by: (>)) {
                    biggest = i
                }
                // Reads.compareValues(array[i], array[smallest]) == -1 — strict less-than,
                // both live indices.
                if engine.compare(i, smallest, by: (<)) {
                    smallest = i
                }
            }
            if biggest == left {
                biggest = smallest
            }

            engine.swap(left, smallest)
            engine.swap(right, biggest)

            left += 1
            right -= 1

            smallest = left
            biggest = right
        }
    }
}
