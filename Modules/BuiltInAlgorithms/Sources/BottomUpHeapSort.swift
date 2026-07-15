import AlgorithmKit
import SortEngineKit

public struct BottomUpHeapSort: SortAlgorithm {
    public let id = AlgorithmID(rawValue: "bottomupheapsort")
    public let metadata = AlgorithmMetadata(
        displayName: "Bottom-up Heap Sort",
        category: .selection,
        sizeRange: 16...256,
        stable: false,
        timeComplexity: ComplexityBounds(
            best: "O(n log n)", average: "O(n log n)", worst: "O(n log n)"),
        spaceComplexity: "O(1)",
        iconName: "arrow.up.square.fill"
    )
    public init() {}

    /// The "bottom-up heapsort" optimization (see
    /// https://en.wikipedia.org/wiki/Heapsort#Bottom-up_heapsort): ordinary `siftDown`
    /// (`MaxHeapSort.swift`) compares the sift value against each level on the way down. This
    /// variant instead descends straight to a leaf via always the larger child — no comparison
    /// against the sift value at all — then climbs back UP from that leaf while the sift value is
    /// still greater than the current ancestor, to find exactly where it belongs. The third loop
    /// then shifts every node between that resting level and `i` one step toward the root (each
    /// position takes its child's value) and drops the original sift value in at the leaf end —
    /// fewer comparisons on average than plain sift-down, same end result.
    public func record(into engine: inout RecordingEngine) {
        let n = engine.count
        guard n > 1 else { return }

        func siftDown(_ i: Int, _ b: Int) {
            var j = i
            while 2 * j + 1 < b {
                if 2 * j + 2 < b {
                    j = engine.compare(2 * j + 2, 2 * j + 1, by: (>)) ? 2 * j + 2 : 2 * j + 1
                } else {
                    j = 2 * j + 1
                }
            }
            while engine.compare(i, j, by: (>)) {
                j = (j - 1) / 2
            }
            while j > i {
                engine.swap(i, j)
                j = (j - 1) / 2
            }
        }

        for i in stride(from: (n - 1) / 2, through: 0, by: -1) {
            siftDown(i, n)
        }

        for i in stride(from: n - 1, to: 0, by: -1) {
            engine.swap(0, i)
            siftDown(0, i)
        }
    }
}
