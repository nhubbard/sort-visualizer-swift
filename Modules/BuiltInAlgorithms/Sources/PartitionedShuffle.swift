import AlgorithmKit
import SortEngineKit

/// Ported from ArrayV's `Shuffles.PARTITIONED`. Pigeonhole-sorts the whole array first, then
/// separately Fisher-Yates shuffles each half — the result is "partitioned" in the sense that every
/// element in the first half is still no greater than every element in the second half, even though
/// neither half is internally ordered anymore.
public struct PartitionedShuffle: ShuffleAlgorithm {
    public let id = ShuffleID(rawValue: "partitioned")
    public let metadata = ShuffleMetadata(displayName: "Partitioned")
    public init() {}
    public func record(into engine: inout RecordingEngine) {
        let n = engine.count
        guard n > 0 else { return }
        pigeonholeSortRange(&engine, from: 0, to: n)
        shuffleRange(&engine, from: 0, to: n / 2)
        shuffleRange(&engine, from: n / 2, to: n)
    }

    private func shuffleRange(_ engine: inout RecordingEngine, from start: Int, to end: Int) {
        for i in start..<end {
            engine.swap(i, Int.random(in: i..<end))
        }
    }

    private func pigeonholeSortRange(_ engine: inout RecordingEngine, from start: Int, to end: Int) {
        guard start < end else { return }
        var minValue = engine.values[start]
        var maxValue = minValue
        for i in (start + 1)..<end {
            let v = engine.values[i]
            if v < minValue { minValue = v }
            if v > maxValue { maxValue = v }
        }

        var holes = [Int](repeating: 0, count: maxValue - minValue + 1)
        for i in start..<end {
            holes[engine.values[i] - minValue] += 1
        }

        var j = start
        for i in 0..<holes.count {
            while holes[i] > 0 {
                holes[i] -= 1
                engine.setValue(j, i + minValue)
                j += 1
            }
        }
    }
}
