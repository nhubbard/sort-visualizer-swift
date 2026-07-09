import AlgorithmKit
import SortEngineKit

public struct CombSort: SortAlgorithm {
    public let id = AlgorithmID(rawValue: "combsort")
    public let metadata = AlgorithmMetadata(
        displayName: "Comb Sort",
        category: .exchange,
        sizeRange: 16...512,
        stable: false,
        timeComplexity: ComplexityBounds(best: "O(n \\log{n})", average: "O(n^2)", worst: "O(n^2)"),
        spaceComplexity: "O(1)",
        iconName: "arrow.up.and.down.text.horizontal"
    )

    public init() {}

    public func record(into engine: inout RecordingEngine) {
        let n = engine.count
        let shrink = 1.3
        var gap = Double(n)
        var swapped = false

        while gap > 1 || swapped {
            if gap > 1 {
                gap = (gap / shrink).rounded(.down)
            }
            swapped = false
            let gapInt = Int(gap)
            var i = 0
            while gapInt + i < n {
                // Strict "values[i] > values[i+gap]": engine.compare is always >=, and using it
                // as-is here would swap equal adjacent elements forever once gap settles at 1.
                // a > b  <=>  !(b >= a), i.e. !engine.compare(i + gap, i).
                if !engine.compare(gapInt + i, i) {
                    engine.swap(i, gapInt + i)
                    swapped = true
                }
                i += 1
            }
        }
    }
}
