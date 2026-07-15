import AlgorithmKit
import SortEngineKit

public struct SmartBogoBogoSort: SortAlgorithm {
    public let id = AlgorithmID(rawValue: "smartbogobogosort")
    public let metadata = AlgorithmMetadata(
        displayName: "Smart Bogo Bogo Sort",
        category: .impractical,
        sizeRange: 4...11,
        stable: false,
        timeComplexity: ComplexityBounds(best: "O(n)", average: "O(n \\times n!)", worst: "O(n \\times n!)"),
        spaceComplexity: "O(1)",
        iconName: "questionmark.app.fill"
    )
    public init() {}

    /// ArrayV's `SmartBogoBogoSort` recursively sorts the prefix `[0, length - 1)` first, then —
    /// while the last two elements are out of order — reshuffles the *whole* `[0, length)` range
    /// and re-sorts the prefix again. The reshuffle is the same open-ended random walk `BogoSort`
    /// already fixed; substitutes a lexicographic `nextPermutation` walk of `[0, length)` (same
    /// technique `LessBogoSort`/`CocktailBogoSort` already use, just always anchored at 0 rather
    /// than a shrinking window) for it.
    public func record(into engine: inout RecordingEngine) {
        let n = engine.count
        guard n > 1 else { return }

        func nextPermutation(_ end: Int) -> Bool {
            var i = end - 2
            while i >= 0, engine.compare(i, i + 1) { i -= 1 }
            guard i >= 0 else { return false }

            var j = end - 1
            while !engine.compare(j, i, by: (>)) { j -= 1 }

            engine.swap(i, j)
            engine.reversal(i + 1, end - 1)
            return true
        }

        func smartBogoBogo(_ length: Int) {
            guard length > 1 else { return }
            smartBogoBogo(length - 1)
            while engine.compare(length - 2, length - 1, by: (>)) {
                if !nextPermutation(length) {
                    engine.reversal(0, length - 1)
                }
                smartBogoBogo(length - 1)
            }
        }

        smartBogoBogo(n)
    }
}
