import AlgorithmKit
import SortEngineKit

public struct MergeSort: SortAlgorithm {
    public let id = AlgorithmID(rawValue: "mergesort")
    public let metadata = AlgorithmMetadata(
        displayName: "Merge Sort",
        category: .merge,
        sizeRange: 16...512,
        stable: true,
        timeComplexity: ComplexityBounds(
            best: "O(n log n)", average: "O(n log n)", worst: "O(n log n)"),
        spaceComplexity: "O(n)",
        iconName: "arrow.triangle.merge"
    )

    public init() {}

    public func record(into engine: inout RecordingEngine) {
        let n = engine.count
        guard n >= 2 else { return }

        let tempHandle = engine.createAuxArray(length: n)

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
            if end - start < 2 { return }
            let mid = start + (end - start) / 2
            mergeSort(start, mid)
            mergeSort(mid, end)
            merge(start, mid, end)
        }

        mergeSort(0, n)

        engine.deleteAuxArray(tempHandle)
    }
}
