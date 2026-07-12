import AlgorithmKit
import SortEngineKit

public struct BubbleSort: SortAlgorithm {
    public let id = AlgorithmID(rawValue: "bubblesort")
    public let metadata = AlgorithmMetadata(
        displayName: "Bubble Sort",
        category: .exchange,
        sizeRange: 16...256,
        stable: true,
        timeComplexity: ComplexityBounds(best: "O(n)", average: "O(n^2)", worst: "O(n^2)"),
        spaceComplexity: "O(1)",
        iconName: "circle.grid.2x2.fill"
    )
    public init() {}
    public func record(into engine: inout RecordingEngine) {
        let n = engine.count
        guard n > 1 else { return }
        for i in 1..<n {
            for j in 0..<(n - i) where engine.compare(j, j + 1) {
                engine.swap(j, j + 1)
            }
        }
    }
}
