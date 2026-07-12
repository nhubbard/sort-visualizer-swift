import AlgorithmKit
import SortEngineKit

/// Ported from ArrayV's `Shuffles.QSORT_BAD`. A self-contained adversarial arrangement targeting
/// last-element-pivot quicksort's worst case — it doesn't need `LLQuickSort` itself to exist, it
/// just constructs the specific pattern that trips up that partition scheme.
public struct QuicksortAdversaryShuffle: ShuffleAlgorithm {
    public let id = ShuffleID(rawValue: "qsortbad")
    public let metadata = ShuffleMetadata(displayName: "Quicksort Adversary")
    public init() {}
    public func record(into engine: inout RecordingEngine) {
        let n = engine.count
        var j = n - n % 2 - 2
        var i = j - 1
        while i >= 0 {
            engine.swap(i, j)
            i -= 2
            j -= 1
        }
    }
}
