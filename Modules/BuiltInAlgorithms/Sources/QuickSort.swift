import AlgorithmKit
import SortEngineKit

/// Native proof-of-concept for Phase 2 — proves record-then-replay actually produces a correct,
/// replayable tape before JavaScriptCore enters the picture at all. Scaffolding, not a keeper:
/// deleted in Phase 3 once the scripted Bubble Sort proves the JS path and `BuiltInAlgorithms`
/// goes back to empty per §2.6's "everything is scripted" policy.
public struct QuickSort: SortAlgorithm {
    public let id = AlgorithmID(rawValue: "quicksort")
    public let metadata = AlgorithmMetadata(
        displayName: "Quick Sort",
        category: .logarithmic,
        sizeRange: 16...512,
        stable: false,
        timeComplexity: ComplexityBounds(best: "O(n log n)", average: "O(n log n)", worst: "O(n²)"),
        spaceComplexity: "O(n)",
        iconName: "quick"
    )

    public init() {}

    /// Ported from `Legacy/Shared/Data/Implementations/Logarithmic/QuickSortImpl.swift`: every
    /// `await`/`enforceRunning()`/color/audio call is replaced with the matching `RecordingEngine`
    /// call or deleted outright — the partitioning logic itself (a two-pointer scheme pivoting on
    /// the leftmost element) is unchanged.
    public func record(into engine: inout RecordingEngine) {
        guard engine.count > 1 else { return }
        quickSort(&engine, 0, engine.count - 1)
    }

    private func quickSort(_ engine: inout RecordingEngine, _ left: Int, _ right: Int) {
        guard left < right else { return }
        let pivot = left
        var i = left
        var j = right
        while i < j {
            while engine.compare(pivot, i) && i < j {
                i += 1
            }
            while !engine.compare(pivot, j) {
                j -= 1
            }
            if i < j {
                engine.swap(i, j)
            }
        }
        engine.swap(pivot, j)
        quickSort(&engine, left, j - 1)
        quickSort(&engine, j + 1, right)
    }
}
