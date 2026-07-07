import AlgorithmKit
import SortEngineKit

public struct SelectionSort: SortAlgorithm {
    public let id = AlgorithmID(rawValue: "selectionsort")
    public let metadata = AlgorithmMetadata(
        displayName: "Selection Sort",
        category: .selection,
        sizeRange: 16...512,
        stable: false,
        timeComplexity: ComplexityBounds(best: "O(n^2)", average: "O(n^2)", worst: "O(n^2)"),
        spaceComplexity: "O(1)",
        iconName: "checkmark.circle"
    )
    public init() {}
    public func record(into engine: inout RecordingEngine) {
        let n = engine.count
        guard n > 1 else { return }
        for i in 0..<(n - 1) {
            var lowestIndex = i
            for j in (i + 1)..<n {
                if !engine.compare(j, lowestIndex) {
                    lowestIndex = j
                }
            }
            engine.swap(i, lowestIndex)
        }
    }
}
