import AlgorithmKit
import SortEngineKit

public struct StableSelectionSort: SortAlgorithm {
    public let id = AlgorithmID(rawValue: "stableselectionsort")
    public let metadata = AlgorithmMetadata(
        displayName: "Stable Selection Sort",
        category: .selection,
        sizeRange: 16...512,
        stable: true,
        timeComplexity: ComplexityBounds(best: "O(n^2)", average: "O(n^2)", worst: "O(n^2)"),
        spaceComplexity: "O(1)",
        iconName: "arrow.up.arrow.down.circle"
    )
    public init() {}
    public func record(into engine: inout RecordingEngine) {
        let n = engine.count
        guard n > 1 else { return }
        for i in 0..<(n - 1) {
            var min = i
            for j in (i + 1)..<n {
                if engine.compare(j, min, by: (<)) {
                    min = j
                }
            }
            let tmp = engine.values[min]
            var pos = min
            while pos > i {
                engine.setValue(pos, engine.values[pos - 1])
                pos -= 1
            }
            engine.setValue(pos, tmp)
        }
    }
}
