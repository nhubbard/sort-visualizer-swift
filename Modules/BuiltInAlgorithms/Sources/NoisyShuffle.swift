import AlgorithmKit
import SortEngineKit

/// Ported from ArrayV's `Shuffles.NOISY`. Walks the array in windows of a size proportional to
/// `sqrt(n)`, Fisher-Yates shuffling each window in place before advancing by a random amount (at
/// least 1, at most the window size minus 1) — the windows overlap the walk unevenly, and whatever
/// is left after the last full window fits is shuffled once more as a final, possibly undersized,
/// window.
public struct NoisyShuffle: ShuffleAlgorithm {
    public let id = ShuffleID(rawValue: "noisy")
    public let metadata = ShuffleMetadata(displayName: "Noisy")
    public init() {}
    public func record(into engine: inout RecordingEngine) {
        let n = engine.count
        guard n > 0 else { return }
        let size = max(4, Int(Double(n).squareRoot() / 2))

        var i = 0
        while i + size <= n {
            shuffleRange(&engine, from: i, to: i + size)
            i += Int.random(in: 1...(size - 1))
        }
        shuffleRange(&engine, from: i, to: n)
    }

    private func shuffleRange(_ engine: inout RecordingEngine, from start: Int, to end: Int) {
        for i in start..<end {
            let randomIndex = Int.random(in: i..<end)
            engine.swap(i, randomIndex)
        }
    }
}
