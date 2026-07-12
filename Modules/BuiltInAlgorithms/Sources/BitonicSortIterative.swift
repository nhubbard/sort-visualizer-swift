import AlgorithmKit
import SortEngineKit

public struct BitonicSortIterative: SortAlgorithm {
    public let id = AlgorithmID(rawValue: "bitonicsortiterative")
    public let metadata = AlgorithmMetadata(
        displayName: "Bitonic Sort (Iterative)",
        category: .concurrent,
        sizeRange: 16...256,
        stable: false,
        timeComplexity: ComplexityBounds(
            best: "O(log^2 n)", average: "O(log^2 n)", worst: "O(log^2 n)"),
        spaceComplexity: "O(n log^2 n)",
        iconName: "waveform"
    )

    public init() {}

    public func record(into engine: inout RecordingEngine) {
        let n = engine.count

        var k = 2
        while k < n * 2 {
            let m = ((n + (k - 1)) / k) % 2 != 0

            var j = k >> 1
            while j > 0 {
                for i in 0..<n {
                    let ij = i ^ j
                    if ij > i && ij < n {
                        if ((i & k) == 0) == m && !engine.compare(ij, i) {
                            engine.swap(i, ij)
                        }
                        if ((i & k) != 0) == m && !engine.compare(i, ij) {
                            engine.swap(i, ij)
                        }
                    }
                }
                j = j >> 1
            }

            k = 2 * k
        }
    }
}
