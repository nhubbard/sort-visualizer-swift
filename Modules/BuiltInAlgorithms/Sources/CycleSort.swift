import AlgorithmKit
import SortEngineKit

public struct CycleSort: SortAlgorithm {
    public let id = AlgorithmID(rawValue: "cyclesort")
    public let metadata = AlgorithmMetadata(
        displayName: "Cycle Sort",
        category: .selection,
        sizeRange: 16...512,
        stable: false,
        timeComplexity: ComplexityBounds(best: "O(n^2)", average: "O(n^2)", worst: "O(n^2)"),
        spaceComplexity: "O(1)",
        iconName: "arrow.triangle.2.circlepath"
    )
    public init() {}

    public func record(into engine: inout RecordingEngine) {
        let n = engine.count
        guard n > 1 else { return }

        // ArrayV's `countLesser(array, a, b, t)`: starting at `a`, count how many of the
        // remaining elements in `[a+1, b)` are *strictly* less than the held value `t`. `t`
        // isn't necessarily live at any array index while a cycle is in flight (see below), so
        // this reads `engine.values` directly rather than going through `engine.compare` —
        // the same held-value-vs-array-value pattern IntroSort's `partition` uses for its
        // cached `pivotValue`.
        func countLesser(_ a: Int, _ b: Int, _ t: Int) -> Int {
            var r = a
            for i in (a + 1)..<b where engine.values[i] < t {
                r += 1
            }
            return r
        }

        for i in 0..<(n - 1) {
            // Hold the value currently at `i`; position `i` itself is left untouched until the
            // cycle that starts here closes, exactly as ArrayV does (`Writes.write(array, i,
            // t, ...)` only happens once, at the very end of the `if (r != i)` block).
            var t = engine.values[i]
            var r = countLesser(i, n, t)

            // `t` is already where it belongs — nothing to rotate for this `i`.
            guard r != i else { continue }

            repeat {
                // Skip past any elements already equal to `t`: since `countLesser` only counts
                // *strictly* lesser elements, every duplicate of `t` maps to the same `r`, and
                // without this skip the cycle would try to write `t` on top of a slot that
                // already holds `t`, looping forever. This is exactly ArrayV's own duplicate
                // handling (`while (Reads.compareIndexValue(array, r, t, ...) == 0) r++;`).
                while engine.values[r] == t {
                    r += 1
                }

                // Pick up whatever is at `r`, drop `t` there, then carry the picked-up value
                // forward as the new `t` for the next link in the cycle. ArrayV uses
                // `Writes.write`, not a swap, for this step, so `setValue` is the matching
                // primitive here — each element is written at most once to its final resting
                // place, which is Cycle Sort's defining minimal-writes property.
                let t1 = engine.values[r]
                engine.setValue(r, t)
                t = t1

                r = countLesser(i, n, t)
            } while r != i

            // Close the cycle: the last value carried through the rotation belongs back at `i`.
            engine.setValue(i, t)
        }
    }
}
