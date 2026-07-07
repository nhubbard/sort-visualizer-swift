import AlgorithmKit
import SortEngineKit

public struct CircleSortIterative: SortAlgorithm {
    public let id = AlgorithmID(rawValue: "circlesortiterative")
    public let metadata = AlgorithmMetadata(
        displayName: "Circle Sort (Iterative)",
        category: .exchange,
        sizeRange: 16...512,
        stable: false,
        timeComplexity: ComplexityBounds(best: "O(n log n)", average: "O(n log n)", worst: "O(n log^2 n)"),
        spaceComplexity: "O(1)",
        iconName: "arrow.down.right.and.arrow.up.left"
    )

    public init() {}

    public func record(into engine: inout RecordingEngine) {
        // `end` is the real array length. Just like BoseNelsonSortIterative, the routine below
        // conceptually operates over `n`, the next power of two at or above `end` (ArrayV's local
        // `n` in `CircleSortIterative.runSort`) — `n` is never used to resize anything, it only
        // controls how many gap/start window combinations get iterated over. Every real array
        // access is separately guarded against `end`, so nothing ever reads or writes out of range.
        let end = engine.count
        guard end > 1 else { return }

        var n = 1
        while n < end {
            n <<= 1
        }

        // Mirrors `IterativeCircleSorting.circleSortRoutine`: for each shrinking `gap`, slide a
        // window of size `2 * gap` across the (padded) conceptual array, and within each window walk
        // `low`/`high` inward from its ends toward its center — a single "circle" of comparisons
        // folding inward. `low`/`high` still advance every iteration regardless of whether `high` is
        // in bounds; only the compare-and-swap itself is gated by `high < end`.
        func circleSortRoutine(_ length: Int) -> Int {
            var swapCount = 0
            var gap = length / 2
            while gap > 0 {
                var start = 0
                while start + gap < end {
                    var low = start
                    var high = start + 2 * gap - 1
                    while low < high {
                        if high < end {
                            if engine.compare(low, high, by: (>)) {
                                engine.swap(low, high)
                                swapCount += 1
                            }
                        }
                        low += 1
                        high -= 1
                    }
                    start += 2 * gap
                }
                gap /= 2
            }
            return swapCount
        }

        var numberOfSwaps: Int
        repeat {
            numberOfSwaps = circleSortRoutine(n)
        } while numberOfSwaps != 0
    }
}
