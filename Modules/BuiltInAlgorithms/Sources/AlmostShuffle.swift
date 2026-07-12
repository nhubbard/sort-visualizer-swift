import AlgorithmKit
import SortEngineKit

/// Ported from ArrayV's `Shuffles.ALMOST`. Barely disturbs the array: swaps `max(n/20, 1)` random
/// pairs (with replacement — the same pair, or even the same index twice, can be picked again),
/// leaving most of the array's original order intact.
public struct AlmostShuffle: ShuffleAlgorithm {
    public let id = ShuffleID(rawValue: "almost")
    public let metadata = ShuffleMetadata(displayName: "Slight Shuffle")
    public init() {}
    public func record(into engine: inout RecordingEngine) {
        let n = engine.count
        guard n > 0 else { return }
        for _ in 0..<max(n / 20, 1) {
            engine.swap(Int.random(in: 0..<n), Int.random(in: 0..<n))
        }
    }
}
