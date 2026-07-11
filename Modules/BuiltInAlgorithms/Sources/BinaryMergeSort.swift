import AlgorithmKit
import SortEngineKit

public struct BinaryMergeSort: SortAlgorithm {
    public let id = AlgorithmID(rawValue: "binarymergesort")
    public let metadata = AlgorithmMetadata(
        displayName: "Binary Merge Sort",
        category: .hybrid,
        sizeRange: 16...256,
        stable: true,
        timeComplexity: ComplexityBounds(best: "O(n log n)", average: "O(n log n)", worst: "O(n log n)"),
        spaceComplexity: "O(n)",
        iconName: "arrow.triangle.merge"
    )

    public init() {}

    public func record(into engine: inout RecordingEngine) {
        let n = engine.count
        guard n >= 2 else { return }

        let threshold = 32
        let tempHandle = engine.createAuxArray(length: n)

        func insertionSort(_ start: Int, _ end: Int) {
            var i = start + 1
            while i < end {
                var j = i
                while j > start && !engine.compare(j, j - 1) {
                    engine.swap(j - 1, j)
                    j -= 1
                }
                i += 1
            }
        }

        func merge(_ start: Int, _ mid: Int, _ end: Int) {
            var low = start
            var high = mid
            var merged: [Int] = []
            while low < mid && high < end {
                if engine.compare(high, low) {
                    merged.append(engine.values[low])
                    low += 1
                } else {
                    merged.append(engine.values[high])
                    high += 1
                }
            }
            while low < mid {
                merged.append(engine.values[low])
                low += 1
            }
            while high < end {
                merged.append(engine.values[high])
                high += 1
            }
            for i in 0..<merged.count {
                engine.writeAux(tempHandle, at: start + i, value: merged[i])
            }
            for i in 0..<merged.count {
                engine.setValue(start + i, merged[i])
            }
        }

        func mergeSort(_ start: Int, _ end: Int) {
            if end - start <= threshold {
                insertionSort(start, end)
                return
            }
            let mid = start + (end - start) / 2
            mergeSort(start, mid)
            mergeSort(mid, end)
            merge(start, mid, end)
        }

        mergeSort(0, n)

        engine.deleteAuxArray(tempHandle)
    }
}
