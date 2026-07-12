import AlgorithmKit
import SortEngineKit

/// Ported from ArrayV's `Shuffles.DOUBLE_LAYERED`. Swaps every other element with its mirror
/// across the array's center, for the first half only — every fourth element (indices 0, 4, 8, ...)
/// trades places with its mirror, leaving the rest untouched.
public struct DoubleLayeredShuffle: ShuffleAlgorithm {
    public let id = ShuffleID(rawValue: "doublelayered")
    public let metadata = ShuffleMetadata(displayName: "Double Layered")
    public init() {}
    public func record(into engine: inout RecordingEngine) {
        let n = engine.count
        var i = 0
        while i < n / 2 {
            engine.swap(i, n - i - 1)
            i += 2
        }
    }
}
