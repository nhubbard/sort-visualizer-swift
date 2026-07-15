import AlgorithmKit
import SortEngineKit

public struct BubbleBogoSort: SortAlgorithm {
    public let id = AlgorithmID(rawValue: "bubblebogosort")
    public let metadata = AlgorithmMetadata(
        displayName: "Bubble Bogo Sort",
        category: .impractical,
        sizeRange: 16...256,
        stable: false,
        timeComplexity: ComplexityBounds(best: "O(n)", average: "O(n^2)", worst: "O(n^2)"),
        spaceComplexity: "O(1)",
        iconName: "questionmark.bubble.fill"
    )
    public init() {}

    /// ArrayV's `BubbleBogoSort` repeatedly picks a RANDOM adjacent pair and swaps it if inverted,
    /// repeating until the whole array happens to be sorted — an open-ended random walk with no
    /// hard ceiling, the same `RecordingEngine`-can't-pre-record-an-unbounded-tape problem
    /// documented on `BogoSort`. Every accepted swap strictly fixes one inversion, so — mirroring
    /// `ExchangeBogoSort`'s own choice to substitute a fixed deterministic sweep rather than a
    /// permutation walk, since that's the character actually being preserved here — repeatedly
    /// sweeping every adjacent pair left-to-right and swapping whenever inverted, until a full
    /// sweep finds nothing left to fix, is exactly bubble sort's own mechanic: it preserves "pick
    /// an adjacent pair, fix it if needed" faithfully while guaranteeing termination in O(n^2), a
    /// genuinely cheap substitute unlike the rest of this family — hence the much larger
    /// `sizeRange` than a typical bogo variant, matching `ExchangeBogoSort`'s own precedent.
    public func record(into engine: inout RecordingEngine) {
        let n = engine.count
        guard n > 1 else { return }

        var swapped = true
        while swapped {
            swapped = false
            for i in 0..<(n - 1) where engine.compare(i, i + 1, by: (>)) {
                engine.swap(i, i + 1)
                swapped = true
            }
        }
    }
}
