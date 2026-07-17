import AlgorithmKit
import SortEngineKit

public struct DeterministicBogoSort: SortAlgorithm {
    public let id = AlgorithmID(rawValue: "deterministicbogosort")
    public let metadata = AlgorithmMetadata(
        displayName: "Deterministic Bogo Sort",
        category: .impractical,
        sizeRange: 4...8,
        stable: false,
        timeComplexity: ComplexityBounds(best: "O(n)", average: "O(n \\times n!)", worst: "O(n \\times n!)"),
        spaceComplexity: "O(1)",
        iconName: "die.face.4.fill"
    )
    public init() {}

    /// Already fully deterministic in ArrayV — no `randInt` in the Java source, true to its name.
    /// Heap's algorithm walking every permutation, same technique `BozoSort` already ported, just
    /// structured as forward recursion counting a `depth` up from 0 (checking sortedness once
    /// `depth` reaches `n - 1`) rather than `BozoSort`'s own `k` counting down from `n`.
    public func record(into engine: inout RecordingEngine) {
        let n = engine.count
        guard n > 1 else { return }

        func isSorted() -> Bool {
            for i in 1..<n where !engine.compare(i, i - 1) { return false }
            return true
        }

        func permutationSort(_ depth: Int) -> Bool {
            if depth >= n - 1 {
                return isSorted()
            }
            for i in stride(from: n - 1, through: depth + 1, by: -1) {
                if permutationSort(depth + 1) { return true }
                if (n - depth).isMultiple(of: 2) {
                    engine.swap(depth, i)
                } else {
                    engine.swap(depth, n - 1)
                }
            }
            return permutationSort(depth + 1)
        }

        _ = permutationSort(0)
    }
}
