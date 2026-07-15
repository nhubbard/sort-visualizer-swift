import AlgorithmKit
import SortEngineKit

public struct LazyHeapSort: SortAlgorithm {
    public let id = AlgorithmID(rawValue: "lazyheapsort")
    public let metadata = AlgorithmMetadata(
        displayName: "Lazy Heap Sort",
        category: .selection,
        sizeRange: 16...256,
        stable: false,
        timeComplexity: ComplexityBounds(
            best: "O(n \\times \\sqrt{n})", average: "O(n \\times \\sqrt{n})", worst: "O(n \\times \\sqrt{n})"),
        spaceComplexity: "O(1)",
        iconName: "square.dashed"
    )
    public init() {}

    /// Not actually heap-based despite the name — a sqrt-decomposition selection sort. The array
    /// is divided into blocks of size `~sqrt(n)`, each block's maximum moved to its own front; the
    /// main loop then finds the largest of those block-front maxima, swaps it to the end of the
    /// shrinking unsorted range, and re-establishes that one block's own max (cheaper than
    /// rescanning everything, hence "lazy"). `maxToFront` prefers the EARLIEST index on a tie
    /// (strict `>`); the block-of-maxima scan prefers the LATEST (non-strict `>=`) — both match
    /// ArrayV's own asymmetric tie-breaks exactly, not a typo.
    public func record(into engine: inout RecordingEngine) {
        let n = engine.count
        guard n > 1 else { return }

        // `b` can equal (never exceed) `a` when the block just extracted from happened to already
        // be empty — Java's `for (i = a+1; i < b; i++)` simply doesn't execute in that case, but
        // Swift's `(a+1)..<b` Range validates `lowerBound <= upperBound` at construction time and
        // traps if `b <= a`, so this stays a `while` loop to match Java's lazy condition check.
        func maxToFront(_ a: Int, _ b: Int) {
            var max = a
            var i = a + 1
            while i < b {
                if engine.compare(i, max, by: (>)) {
                    max = i
                }
                i += 1
            }
            engine.swap(max, a)
        }

        let s = Int(Double(n - 1).squareRoot()) + 1

        var i = 0
        while i < n {
            maxToFront(i, min(i + s, n))
            i += s
        }

        var j = n
        while j > 0 {
            var max = 0
            var k = max + s
            while k < j {
                if engine.compare(k, max, by: (>=)) {
                    max = k
                }
                k += s
            }
            j -= 1
            engine.swap(max, j)
            maxToFront(max, min(max + s, j))
        }
    }
}
