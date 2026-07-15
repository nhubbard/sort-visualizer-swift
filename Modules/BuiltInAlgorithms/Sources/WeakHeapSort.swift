import AlgorithmKit
import SortEngineKit

public struct WeakHeapSort: SortAlgorithm {
    public let id = AlgorithmID(rawValue: "weakheapsort")
    public let metadata = AlgorithmMetadata(
        displayName: "Weak Heap Sort",
        category: .selection,
        sizeRange: 16...256,
        stable: false,
        timeComplexity: ComplexityBounds(
            best: "O(n log n)", average: "O(n log n)", worst: "O(n log n)"),
        spaceComplexity: "O(n)",
        iconName: "flag.fill"
    )
    public init() {}

    /// A weak heap relaxes the ordinary heap invariant: instead of every node being `>=` both
    /// children, each node keeps one "reverse" bit per index recording which of its two subtrees
    /// currently holds the larger root, so a node only needs to dominate ONE of its children
    /// directly (the other comparison is deferred, tracked by the bit) — fewer comparisons overall
    /// than an ordinary heap for the same `n`. ArrayV bit-packs these flags into a byte array
    /// (`getBitwiseFlag`/`toggleBitwiseFlag`); that packing is a memory micro-optimization
    /// irrelevant to this port, so `flags` here is a plain `Bool` array indexed directly by
    /// position instead — identical logical behavior, no bit unpacking. ArrayV's own explicit
    /// zero-fill loop is also skipped: it only zeroes `n/8` of the `bits` array's `(n+7)/8` bytes
    /// anyway, redundant regardless since Java (and Swift's `repeating: false`) already
    /// zero-initializes a freshly created array.
    public func record(into engine: inout RecordingEngine) {
        let n = engine.count
        guard n > 1 else { return }

        var flags = [Bool](repeating: false, count: n)

        func weakHeapMerge(_ i: Int, _ j: Int) {
            if engine.compare(i, j, by: (<)) {
                flags[j].toggle()
                engine.swap(i, j)
            }
        }

        for i in stride(from: n - 1, through: 1, by: -1) {
            var j = i
            while (j & 1) == (flags[j >> 1] ? 1 : 0) {
                j >>= 1
            }
            let gparent = j >> 1
            weakHeapMerge(gparent, i)
        }

        for i in stride(from: n - 1, through: 2, by: -1) {
            engine.swap(0, i)

            var x = 1
            while true {
                let y = 2 * x + (flags[x] ? 1 : 0)
                guard y < i else { break }
                x = y
            }
            while x > 0 {
                weakHeapMerge(0, x)
                x >>= 1
            }
        }
        engine.swap(0, 1)
    }
}
