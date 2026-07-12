import AlgorithmKit
import SortEngineKit

public struct BozoSort: SortAlgorithm {
    public let id = AlgorithmID(rawValue: "bozosort")
    public let metadata = AlgorithmMetadata(
        displayName: "Bozo Sort",
        category: .impractical,
        sizeRange: 4...7,
        stable: false,
        timeComplexity: ComplexityBounds(best: "O(n)", average: "O(n \\times n!)", worst: "O(n \\times n!)"),
        spaceComplexity: "O(1)",
        iconName: "arrow.triangle.swap"
    )
    public init() {}

    /// Classic Bozo Sort swaps two random elements and checks if the array happens to be sorted,
    /// repeating until it is — but like `BogoSort`, a real random walk has no memory of which
    /// arrangements it's already tried, and `RecordingEngine` has to pre-record the *entire* run
    /// before a single frame plays back, so an open-ended random walk has no ceiling on how large
    /// that tape can grow. Heap's algorithm keeps Bozo Sort's defining "one swap, then check"
    /// shape but makes it deterministic: it visits every permutation of the array exactly once,
    /// reaching each one via exactly one swap from the last, giving a hard n!-step ceiling with no
    /// repeats instead of an open-ended random walk (the same fix `BogoSort` applies via
    /// lexicographic `next_permutation`, just built from single swaps instead of full rotations,
    /// matching Bozo's own single-swap character).
    public func record(into engine: inout RecordingEngine) {
        let n = engine.count
        guard n > 1 else { return }

        func isSorted() -> Bool {
            for i in 1..<n where !engine.compare(i, i - 1) { return false }
            return true
        }

        var done = false

        func heap(_ k: Int) {
            guard !done else { return }
            if k == 1 {
                if isSorted() { done = true }
                return
            }
            for i in 0..<(k - 1) {
                heap(k - 1)
                guard !done else { return }
                engine.swap(k.isMultiple(of: 2) ? i : 0, k - 1)
            }
            heap(k - 1)
        }

        heap(n)
    }
}
