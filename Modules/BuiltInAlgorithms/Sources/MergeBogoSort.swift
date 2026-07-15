import AlgorithmKit
import SortEngineKit

public struct MergeBogoSort: SortAlgorithm {
    public let id = AlgorithmID(rawValue: "mergebogosort")
    public let metadata = AlgorithmMetadata(
        displayName: "Merge Bogo Sort",
        category: .impractical,
        sizeRange: 4...22,
        stable: false,
        timeComplexity: ComplexityBounds(best: "O(n)", average: "O(n \\times 2^n)", worst: "O(n \\times 2^n)"),
        spaceComplexity: "O(n)",
        iconName: "shuffle.circle.fill"
    )
    public init() {}

    /// ArrayV's `MergeBogoSort` recursively sorts each half, then randomly "weaves" the two
    /// already-sorted runs back together — repeatedly picking a random subset of positions to pull
    /// from the right run (and the rest from the left) until the merged result happens to be
    /// sorted — the same open-ended random walk `BogoSort` already fixed, just over the space of
    /// interleavings of two fixed runs rather than permutations of the whole range.
    ///
    /// Substitutes a deterministic walk over that same interleaving space: every bitmask of length
    /// `end - start` with exactly `end - mid` bits set corresponds to one candidate interleaving
    /// (bit set = pull from the right run next); walking masks in increasing integer order and
    /// skipping any whose bit count doesn't match is a simple, correctly-bounded way to visit every
    /// one exactly once with no combinatorics helper beyond `Int.nonzeroBitCount`. The correct
    /// merge interleaving is always among them, so this is guaranteed to terminate.
    ///
    /// ArrayV reuses the main array itself as scratch space for the random mask; this uses a real
    /// aux array for the pre-weave snapshot instead (matching `MergeSort.swift`'s own convention),
    /// which avoids a confusing "values flash to 0/1 mid-sort" visual and gives proper
    /// `auxWriteCount` credit for the snapshot.
    public func record(into engine: inout RecordingEngine) {
        let n = engine.count
        guard n > 1 else { return }

        var tmp = [Int](repeating: 0, count: n)
        let tmpHandle = engine.createAuxArray(length: n)

        func isRangeSorted(_ start: Int, _ end: Int) -> Bool {
            for i in start..<(end - 1) where engine.compare(i, i + 1, by: (>)) { return false }
            return true
        }

        func applyWeave(_ start: Int, _ mid: Int, _ end: Int, mask: Int) {
            var low = start
            var high = mid
            for offset in 0..<(end - start) {
                let pullFromHigh = (mask >> offset) & 1 == 1
                if pullFromHigh {
                    engine.setValue(start + offset, tmp[high])
                    high += 1
                } else {
                    engine.setValue(start + offset, tmp[low])
                    low += 1
                }
            }
        }

        func mergeBogo(_ start: Int, _ end: Int) {
            guard start < end - 1 else { return }
            let mid = (start + end) / 2
            mergeBogo(start, mid)
            mergeBogo(mid, end)

            for i in start..<end {
                tmp[i] = engine.values[i]
                engine.writeAux(tmpHandle, at: i, value: tmp[i])
            }

            let popcountTarget = end - mid
            var mask = -1
            while !isRangeSorted(start, end) {
                repeat { mask += 1 } while mask.nonzeroBitCount != popcountTarget
                applyWeave(start, mid, end, mask: mask)
            }
        }

        mergeBogo(0, n)

        engine.deleteAuxArray(tmpHandle)
    }
}
