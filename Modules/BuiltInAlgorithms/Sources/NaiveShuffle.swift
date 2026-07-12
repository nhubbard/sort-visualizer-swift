import AlgorithmKit
import SortEngineKit

/// Ported from ArrayV's `Shuffles.NAIVE`. The "naive" way to shuffle: swap every position with a
/// uniformly random position in the *whole* array (not just the remaining suffix, unlike a real
/// Fisher-Yates shuffle) — biased and not a genuine uniform permutation, which is exactly the
/// point of shipping it alongside the real `RandomShuffle`.
public struct NaiveShuffle: ShuffleAlgorithm {
    public let id = ShuffleID(rawValue: "naive")
    public let metadata = ShuffleMetadata(displayName: "Naive Randomly")
    public init() {}
    public func record(into engine: inout RecordingEngine) {
        let n = engine.count
        guard n > 0 else { return }
        for i in 0..<n {
            engine.swap(i, Int.random(in: 0..<n))
        }
    }
}
