import AlgorithmKit
import Foundation
import SortEngineKit

public struct CountingSort: SortAlgorithm {
    public let id = AlgorithmID(rawValue: "countingsort")
    public let metadata = AlgorithmMetadata(
        displayName: "Counting Sort",
        category: .distribution,
        sizeRange: 16...256,
        stable: true,
        timeComplexity: ComplexityBounds(best: "O(n+k)", average: "O(n+k)", worst: "O(n+k)"),
        spaceComplexity: "O(n+k)",
        iconName: "chart.bar.fill"
    )

    public init() {}

    public func record(into engine: inout RecordingEngine) {
        let n = engine.count
        guard n > 0 else { return }

        // ArrayV's `Reads.analyzeMax` reads values directly (no stat-tracked compares), so the
        // scan for the maximum here does the same via `engine.values` rather than `engine.compare`.
        var maxValue = engine.values[0]
        for i in 1..<n where engine.values[i] > maxValue {
            maxValue = engine.values[i]
        }

        var values = [Int]()
        values.reserveCapacity(n)
        for i in 0..<n {
            values.append(engine.values[i])
        }

        // ArrayV's per-value `counts` table is bookkeeping the visualizer never renders as a bar
        // array in its own right (same precedent as LSDRadixSort's per-digit `counts`), so it stays
        // a plain local Swift array here; only the `output` permutation array is wired through the
        // aux-array API so it's visible in the replay.
        var counts = [Int](repeating: 0, count: maxValue + 1)
        for value in values {
            counts[value] += 1
        }
        for i in 1..<counts.count {
            counts[i] += counts[i - 1]
        }

        let outputHandle = engine.createAuxArray(length: n)
        var output = [Int](repeating: 0, count: n)
        for i in stride(from: n - 1, through: 0, by: -1) {
            let value = values[i]
            counts[value] -= 1
            output[counts[value]] = value
            engine.writeAux(outputHandle, at: counts[value], value: value)
        }

        // Extra loop to simulate the results from the "output" array being written back to the
        // visual array, mirroring ArrayV's own comment/structure in `CountingSort.runSort`.
        for i in 0..<n {
            engine.setValue(i, output[i])
        }

        engine.deleteAuxArray(outputHandle)
    }
}
