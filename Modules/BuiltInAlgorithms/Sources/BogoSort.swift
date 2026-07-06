import AlgorithmKit
import SortEngineKit

public struct BogoSort: SortAlgorithm {
    public let id = AlgorithmID(rawValue: "bogosort")
    public let metadata = AlgorithmMetadata(
        displayName: "Bogo Sort",
        category: .weird,
        sizeRange: 4...16,
        stable: false,
        timeComplexity: ComplexityBounds(best: "O(n)", average: "O(n * n!)", worst: "O(n * n!)"),
        spaceComplexity: "O(1)",
        iconName: "die.face.5.fill"
    )
    public init() {}

    public func record(into engine: inout RecordingEngine) {
        let n = engine.count

        func isSorted() -> Bool {
            for i in 1..<n {
                if !engine.compare(i, i - 1) { return false }
            }
            return true
        }

        func shuffle() {
            for i in 0..<n {
                let j = i + Int.random(in: 0..<(n - i))
                engine.swap(i, j)
            }
        }

        while !isSorted() {
            shuffle()
        }
    }
}
