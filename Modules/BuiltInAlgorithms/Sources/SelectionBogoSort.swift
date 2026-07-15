import AlgorithmKit
import SortEngineKit

public struct SelectionBogoSort: SortAlgorithm {
    public let id = AlgorithmID(rawValue: "selectionbogosort")
    public let metadata = AlgorithmMetadata(
        displayName: "Selection Bogo Sort",
        category: .impractical,
        sizeRange: 16...256,
        stable: false,
        timeComplexity: ComplexityBounds(best: "O(n^2)", average: "O(n^2)", worst: "O(n^2)"),
        spaceComplexity: "O(1)",
        iconName: "checkmark.diamond.fill"
    )
    public init() {}

    /// ArrayV's `SelectionBogoSort` randomly swaps an element out of the remaining unsorted range
    /// to the front, repeating until that front element happens to be the minimum of the range —
    /// "an optimized variation of Less Bogosort," per its own doc comment, and the same open-ended
    /// random walk `BogoSort` already fixed. Unlike `LessBogoSort` (which needed a permutation
    /// walk over the whole remaining range, since ANY arrangement of it could be the eventual
    /// target), this one only ever needs ONE swap — the range's true minimum is always at *some*
    /// index in `[i, n)`, so deterministically scanning every candidate `j` exactly once and
    /// tracking the minimum, then swapping the true minimum into place, is guaranteed to leave
    /// `array[i]` holding the minimum after a single pass. That's just selection sort's own inner
    /// loop — a genuinely cheap O(n) per position, hence a much larger `sizeRange` than a typical
    /// bogo variant, matching `ExchangeBogoSort`'s own precedent.
    public func record(into engine: inout RecordingEngine) {
        let n = engine.count
        guard n > 1 else { return }

        for i in 0..<n {
            var minIndex = i
            for j in (i + 1)..<n where engine.compare(minIndex, j, by: (>)) {
                minIndex = j
            }
            if minIndex != i {
                engine.swap(i, minIndex)
            }
        }
    }
}
