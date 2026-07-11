import AlgorithmKit
import SortEngineKit

public struct SwaplessBubbleSort: SortAlgorithm {
    public let id = AlgorithmID(rawValue: "swaplessbubblesort")
    public let metadata = AlgorithmMetadata(
        displayName: "Swapless Bubble Sort",
        category: .exchange,
        sizeRange: 16...256,
        stable: true,
        timeComplexity: ComplexityBounds(best: "O(n)", average: "O(n^2)", worst: "O(n^2)"),
        spaceComplexity: "O(1)",
        iconName: "circle.grid.2x2"
    )
    public init() {}

    public func record(into engine: inout RecordingEngine) {
        let n = engine.count
        guard n > 1 else { return }

        // ArrayV's `for (int i = length; i > 0; i = last)`: each pass sweeps the still-unsorted
        // prefix `[0, i)`, and the next pass's bound becomes wherever the last shift happened
        // (`last`) — exactly bubble sort's usual "shrink to the last swap" optimization, just
        // expressed without ever calling `swap`.
        var i = n
        while i > 0 {
            var last = 0
            var pos = 0
            // `comp` is a carried value, not something that's necessarily live at any array
            // index once the sweep gets going (it starts as `array[0]`, but from then on it's
            // whichever value the sweep is currently "holding") — the same held-value-vs-
            // array-value shape as CycleSort's `t`/IntroSort's `pivotValue`. So the comparisons
            // below read `engine.values` directly and compare with plain `>`/`<=` rather than
            // going through `engine.compare`, which only knows how to compare two live indices
            // against each other.
            var comp = engine.values[0]

            for j in 1..<i {
                let arrJ = engine.values[j]
                if comp > arrJ {
                    // `comp` is the larger of the two: the lesser value (`array[j]`) shifts one
                    // slot left, `comp` keeps being carried rightward, and `last` remembers this
                    // as the rightmost point where a "swap-like" shift happened.
                    engine.setValue(j - 1, arrJ)
                    last = j
                } else {
                    // `comp` has settled relative to `array[j]` (comp <= array[j]): write it
                    // into `j - 1`, but only if it actually moved since the last settle point —
                    // ArrayV's `pos + 1 < j` guard, which skips the no-op write of `comp` back
                    // onto the very slot it already occupies. Either way, `array[j]` becomes the
                    // new carried value going forward.
                    if pos + 1 < j {
                        engine.setValue(j - 1, comp)
                    }
                    pos = j
                    comp = arrJ
                }
            }

            // Whatever the sweep ends up holding belongs at the new right edge.
            engine.setValue(i - 1, comp)
            i = last
        }
    }
}
