import AlgorithmKit
import SortEngineKit

public struct UnoptimizedBubbleSort: SortAlgorithm {
    public let id = AlgorithmID(rawValue: "unoptimizedbubblesort")
    public let metadata = AlgorithmMetadata(
        displayName: "Unoptimized Bubble Sort",
        category: .exchange,
        sizeRange: 16...512,
        stable: true,
        timeComplexity: ComplexityBounds(best: "O(n)", average: "O(n^2)", worst: "O(n^2)"),
        spaceComplexity: "O(1)",
        iconName: "repeat"
    )
    public init() {}
    public func record(into engine: inout RecordingEngine) {
        let n = engine.count
        guard n > 1 else { return }
        var sorted = false
        while !sorted {
            sorted = true
            for i in 0..<(n - 1) {
                if engine.compare(i, i + 1, by: (>)) {
                    engine.swap(i, i + 1)
                    sorted = false
                }
            }
        }
    }
}
