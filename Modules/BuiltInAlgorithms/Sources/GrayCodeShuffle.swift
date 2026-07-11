import AlgorithmKit
import SortEngineKit

/// Ported from ArrayV's `Shuffles.GRAY_CODE`. Similar to `RecursiveReversalShuffle`'s nested
/// halving, but each level reverses only one of its two halves — the left half normally, unless the
/// recursion arrived via the right branch of its parent, in which case it's the right half's turn
/// instead — alternating which side gets reversed as the recursion descends, the same alternation
/// pattern that produces a Gray code sequence.
public struct GrayCodeShuffle: ShuffleAlgorithm {
    public let id = ShuffleID(rawValue: "graycode")
    public let metadata = ShuffleMetadata(displayName: "Gray Code Fractal")
    public init() {}
    public func record(into engine: inout RecordingEngine) {
        reversalRec(&engine, a: 0, b: engine.count, reverseLeft: false)
    }

    private func reversalRec(_ engine: inout RecordingEngine, a: Int, b: Int, reverseLeft: Bool) {
        guard b - a >= 3 else { return }
        let m = (a + b) / 2

        if reverseLeft {
            engine.reversal(a, m - 1)
        } else {
            engine.reversal(m, b - 1)
        }

        reversalRec(&engine, a: a, b: m, reverseLeft: false)
        reversalRec(&engine, a: m, b: b, reverseLeft: true)
    }
}
