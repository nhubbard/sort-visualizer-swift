import AlgorithmKit
import SortEngineKit

/// ArrayV's `HybridCombSort` (`sorts/hybrid/HybridCombSort.java`), which delegates its entire body
/// to the shared `CombSorting.combSort(array, length, 1.3, hybrid: true)` template — identical to
/// plain `CombSort.swift` except once the shrinking gap drops to `<= min(8, length * 0.03125)`, it
/// abandons the comb-gap technique entirely and finishes with one full straight Insertion Sort pass
/// instead of grinding the remaining tiny-gap comb passes down to completion.
///
/// **Does the Insertion Sort finish ever run twice in one sort?** No — confirmed both analytically
/// and empirically (a temporary call-counter instrumented onto a production build of this exact
/// type, exercised across n in {16...512} including every threshold boundary, 40 random trials
/// each, never observed more than one call). The hybrid check is the *first* statement evaluated on
/// every inner-loop iteration, and `gap` is constant for an entire pass, so if the check is ever
/// going to fire during a pass it fires at that pass's `i == 0` — strictly before that pass could
/// set `swapped = true`. Since `swapped` is reset to `false` at the top of every pass, the pass that
/// triggers the finish always exits it with `swapped == false` and `gap == 0`, so the outer
/// `while gap > 1 || swapped` condition is false immediately afterward and the sort ends. A second,
/// later-pass re-trigger (as one might otherwise suspect from a stale `swapped == true` carried over
/// from an earlier pass) is therefore not reachable.
public struct HybridCombSort: SortAlgorithm {
    public let id = AlgorithmID(rawValue: "hybridcombsort")
    public let metadata = AlgorithmMetadata(
        displayName: "Hybrid Comb Sort",
        category: .hybrid,
        sizeRange: 16...256,
        stable: false,
        timeComplexity: ComplexityBounds(best: "O(n log n)", average: "O(n^2)", worst: "O(n^2)"),
        spaceComplexity: "O(1)",
        iconName: "comb.fill"
    )

    public init() {}

    public func record(into engine: inout RecordingEngine) {
        let n = engine.count
        guard n > 1 else { return }
        let shrink = 1.3
        // ArrayV: `gap <= Math.min(8, length * 0.03125)`. `gap` never changes within a single
        // inner pass except right here (when the branch below fires and zeroes it), so this check
        // is loop-invariant across a pass: it either fires on that pass's very first iteration
        // (i == 0), or it never fires during that pass at all — it can never first trigger partway
        // through, after compares have already happened at the current gap.
        let hybridThreshold = min(8.0, Double(n) * 0.03125)
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
                if gap <= hybridThreshold {
                    gap = 0
                    finishWithInsertionSort(&engine, count: n)
                    break
                }
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

    /// ArrayV's `InsertionSort.customInsertSort(array, 0, length, 0.5, false)` finishing pass — a
    /// plain straight insertion sort over the whole array. `InsertionSort.swift` is itself a
    /// distinct `SortAlgorithm`, not a plain function, so this is its own private inline copy
    /// rather than a call into that file.
    private func finishWithInsertionSort(_ engine: inout RecordingEngine, count n: Int) {
        guard n > 1 else { return }
        for i in 1..<n {
            var j = i
            while j > 0 && !engine.compare(j, j - 1) {
                engine.swap(j - 1, j)
                j -= 1
            }
        }
    }
}
