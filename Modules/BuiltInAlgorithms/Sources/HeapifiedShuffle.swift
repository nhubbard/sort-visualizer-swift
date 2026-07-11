import AlgorithmKit
import SortEngineKit

/// Ported from ArrayV's `Shuffles.HEAPIFIED`, which calls directly into `MaxHeapSort`'s own
/// `makeHeap` step rather than reimplementing it — this mirrors that by reusing
/// `MaxHeapSort.swift`'s exact build-heap phase (the same sift-down loop, stopping short of the
/// second, sorting phase), leaving the array as a valid max-heap rather than fully sorted.
public struct HeapifiedShuffle: ShuffleAlgorithm {
    public let id = ShuffleID(rawValue: "heapified")
    public let metadata = ShuffleMetadata(displayName: "Heapified")
    public init() {}
    public func record(into engine: inout RecordingEngine) {
        let n = engine.count

        func siftDown(_ root: Int, _ size: Int) {
            var root = root
            while true {
                var largest = root
                let left = 2 * root + 1
                let right = 2 * root + 2
                if left < size && !engine.compare(largest, left) {
                    largest = left
                }
                if right < size && !engine.compare(largest, right) {
                    largest = right
                }
                if largest == root { break }
                engine.swap(root, largest)
                root = largest
            }
        }

        var i = n / 2 - 1
        while i >= 0 {
            siftDown(i, n)
            i -= 1
        }
    }
}
