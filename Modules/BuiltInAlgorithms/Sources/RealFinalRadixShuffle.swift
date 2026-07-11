import AlgorithmKit
import SortEngineKit

/// Ported from ArrayV's `Shuffles.REAL_FINAL_RADIX`. Computes a bitmask covering roughly the lower
/// half of the bits needed to represent the array's maximum value, then redistributes every element
/// via a stable counting sort keyed on just those low bits — undoing the final low-bit pass an LSD
/// radix sort would need to finish.
public struct RealFinalRadixShuffle: ShuffleAlgorithm {
    public let id = ShuffleID(rawValue: "realfinalradix")
    public let metadata = ShuffleMetadata(displayName: "Real Final Radix")
    public init() {}
    public func record(into engine: inout RecordingEngine) {
        let n = engine.count
        guard n > 0 else { return }

        var mask = 0
        for i in 0..<n {
            while mask < engine.values[i] {
                mask = (mask << 1) + 1
            }
        }
        mask >>= 1

        var counts = [Int](repeating: 0, count: mask + 2)
        let original = engine.values

        for i in 0..<n {
            counts[(original[i] & mask) + 1] += 1
        }
        for i in 1..<counts.count {
            counts[i] += counts[i - 1]
        }
        for i in 0..<n {
            let bucket = original[i] & mask
            engine.setValue(counts[bucket], original[i])
            counts[bucket] += 1
        }
    }
}
