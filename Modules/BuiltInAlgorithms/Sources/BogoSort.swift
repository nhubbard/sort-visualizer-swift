import AlgorithmKit
import SortEngineKit

public struct BogoSort: SortAlgorithm {
    public let id = AlgorithmID(rawValue: "bogosort")
    public let metadata = AlgorithmMetadata(
        displayName: "Bogo Sort",
        category: .impractical,
        sizeRange: 4...7,
        stable: false,
        timeComplexity: ComplexityBounds(best: "O(n)", average: "O(n * n!)", worst: "O(n * n!)"),
        spaceComplexity: "O(1)",
        iconName: "die.face.5.fill"
    )
    public init() {}

    /// Classic Bogo Sort shuffles randomly and hopes, but `RecordingEngine` has to pre-record the
    /// *entire* run before a single frame plays back — a real random walk has no memory of which
    /// arrangements it's already tried, so the tape can balloon for a very long time (n! shuffles
    /// in expectation, with no guaranteed ceiling) before it happens to land on sorted. Swapping
    /// the coin flip for deterministic lexicographic permutation generation (the standard
    /// `next_permutation` technique) keeps the same "try every arrangement" spirit but puts a hard
    /// n!-step ceiling on the tape instead of an open-ended random one, with no repeats along the
    /// way — this is the same fix used in this app's original SwiftUI version, which enumerated
    /// `values.permutations(ofCount:)` instead of reshuffling blindly.
    ///
    /// The fully-sorted ascending array is lexicographically *first*, so walking forward via
    /// `next_permutation` never lands on it directly except by wrapping all the way around — the
    /// wrap point is exactly the fully *descending* array (lexicographically last), which
    /// `engine.reversal` flips straight to sorted in one step.
    public func record(into engine: inout RecordingEngine) {
        let n = engine.count
        guard n > 1 else { return }

        func isSorted() -> Bool {
            for i in 1..<n {
                if !engine.compare(i, i - 1) { return false }
            }
            return true
        }

        if isSorted() { return }

        func nextPermutation() -> Bool {
            var i = n - 2
            while i >= 0, engine.compare(i, i + 1) { i -= 1 }
            guard i >= 0 else { return false }

            var j = n - 1
            while !engine.compare(j, i, by: (>)) { j -= 1 }

            engine.swap(i, j)
            engine.reversal(i + 1, n - 1)
            return true
        }

        while nextPermutation() {}
        // `nextPermutation` only returns false once the array is the fully descending
        // permutation — the next one, cyclically, is the fully sorted ascending array.
        engine.reversal(0, n - 1)
    }
}
