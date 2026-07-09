import AlgorithmKit
import SortEngineKit

/// ArrayV's `LLQuickSort` ("Quick Sort, Left/Left Pointers") — the classic Lomuto partition
/// scheme: the pivot is always the last element (`array[hi]`), and a single forward-scanning
/// pointer `i` marks the boundary of "confirmed less-than-pivot" elements as `j` sweeps the rest
/// of the range, swapping any strictly-lesser element into that boundary and advancing it. The
/// pivot itself is swapped into its resting place at `i` once the sweep finishes. This is a
/// distinct algorithm from this app's own `QuickSort` (a two-pointer/Hoare-style partition ported
/// from the v1/JS prototype) and from `TernaryLLQuickSort`/`TernaryLRQuickSort` (three-way
/// partition variants) — no pivot randomization or median-of-three selection here, which is why
/// already-sorted/reverse-sorted input triggers this scheme's classic O(n^2) worst case.
public struct LLQuickSort: SortAlgorithm {
    public let id = AlgorithmID(rawValue: "llquicksort")
    public let metadata = AlgorithmMetadata(
        displayName: "LL Quick Sort",
        category: .exchange,
        sizeRange: 16...512,
        stable: false,
        timeComplexity: ComplexityBounds(best: "O(n log n)", average: "O(n log n)", worst: "O(n^2)"),
        spaceComplexity: "O(log n)",
        iconName: "arrow.right.to.line"
    )

    public init() {}

    public func record(into engine: inout RecordingEngine) {
        guard engine.count > 1 else { return }
        quickSort(&engine, 0, engine.count - 1)
    }

    private func partition(_ engine: inout RecordingEngine, _ lo: Int, _ hi: Int) -> Int {
        // Held-value pattern (matching `CycleSort`'s precedent): `hi` is never written to until
        // the final pivot-placement swap below, so reading `engine.values[hi]` once up front is
        // equivalent to ArrayV's `Reads.compareValues(array[j], pivot) < 0` against a value that
        // never changes mid-sweep.
        let pivot = engine.values[hi]
        var i = lo
        for j in lo..<hi where engine.values[j] < pivot {
            engine.swap(i, j)
            i += 1
        }
        engine.swap(i, hi)
        return i
    }

    private func quickSort(_ engine: inout RecordingEngine, _ lo: Int, _ hi: Int) {
        guard lo < hi else { return }
        let p = partition(&engine, lo, hi)
        quickSort(&engine, lo, p - 1)
        quickSort(&engine, p + 1, hi)
    }
}
