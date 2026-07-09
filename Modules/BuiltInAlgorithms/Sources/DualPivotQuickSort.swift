import AlgorithmKit
import SortEngineKit

/// Yaroslavskiy's dual-pivot quicksort — partitions around *two* pivots per pass instead of one,
/// splitting the working range into three regions (`< pivot1`, `[pivot1, pivot2]`, `> pivot2`)
/// each recursion instead of two. This is the same algorithm family real-world Java's
/// `Arrays.sort` has used for primitive-type arrays since Java 7.
///
/// Ported from ArrayV's `DualPivotQuickSort.dualPivot`, preserving its inclusive `[left, right]`
/// ranges, three-way recursion, and self-adjusting `divisor` (which widens the "thirds" used to
/// pick pivot candidates once a partition's middle region turns out small) exactly.
public struct DualPivotQuickSort: SortAlgorithm {
    public let id = AlgorithmID(rawValue: "dualpivotquicksort")
    public let metadata = AlgorithmMetadata(
        displayName: "Dual-Pivot Quick Sort",
        category: .exchange,
        sizeRange: 16...512,
        stable: false,
        timeComplexity: ComplexityBounds(best: "O(n log n)", average: "O(n log n)", worst: "O(n^2)"),
        spaceComplexity: "O(log n)",
        iconName: "divide.circle.fill"
    )

    public init() {}

    public func record(into engine: inout RecordingEngine) {
        guard engine.count > 1 else { return }
        dualPivot(&engine, 0, engine.count - 1, 3)
    }

    /// ArrayV's `insertSorter.customInsertSort(array, left, right + 1, 1, false)` base case for
    /// ranges shorter than 4 elements — sorts the half-open range `[start, end)`, matching the
    /// `right + 1` exclusive upper bound ArrayV passes at every call site below. The guard also
    /// safely no-ops for the degenerate/inverted ranges that fall out of the recursive boundary
    /// arithmetic (e.g. `less - 2 < left`), exactly as ArrayV's own loop would.
    private func insertionSort(_ engine: inout RecordingEngine, _ start: Int, _ end: Int) {
        guard start + 1 < end else { return }
        for i in (start + 1)..<end {
            var j = i
            while j > start && !engine.compare(j, j - 1) {
                engine.swap(j - 1, j)
                j -= 1
            }
        }
    }

    private func dualPivot(_ engine: inout RecordingEngine, _ left: Int, _ right: Int, _ divisor: Int) {
        let length = right - left
        // Insertion sort for tiny ranges (also covers empty/inverted ranges produced by the
        // recursive boundary arithmetic below, since `length` is then negative and always < 4).
        if length < 4 {
            insertionSort(&engine, left, right + 1)
            return
        }

        let third = length / divisor
        var med1 = left + third
        var med2 = right - third
        if med1 <= left { med1 = left + 1 }
        if med2 >= right { med2 = right - 1 }

        if engine.compare(med1, med2, by: (<)) {
            engine.swap(med1, left)
            engine.swap(med2, right)
        } else {
            engine.swap(med1, right)
            engine.swap(med2, left)
        }

        // Held pivot values, captured now — right after `left`/`right` were placed by the swaps
        // above — read directly via `engine.values` rather than `engine.compare`, since the
        // partitioning loop below moves other elements through positions `left`/`right` while
        // `pivot1`/`pivot2` must stay fixed at the values captured here. Same held-value pattern
        // as `CycleSort.swift`'s cached `t`.
        let pivot1 = engine.values[left]
        let pivot2 = engine.values[right]

        var less = left + 1
        var great = right - 1

        var k = less
        while k <= great {
            if engine.values[k] < pivot1 {
                engine.swap(k, less)
                less += 1
            } else if engine.values[k] > pivot2 {
                while k < great && engine.values[great] > pivot2 {
                    great -= 1
                }
                engine.swap(k, great)
                great -= 1
                if engine.values[k] < pivot1 {
                    engine.swap(k, less)
                    less += 1
                }
            }
            k += 1
        }

        var divisor = divisor
        let dist = great - less
        if dist < 13 { divisor += 1 }

        engine.swap(less - 1, left)
        engine.swap(great + 1, right)

        dualPivot(&engine, left, less - 2, divisor)
        if pivot1 < pivot2 {
            dualPivot(&engine, less, great, divisor)
        }
        dualPivot(&engine, great + 2, right, divisor)
    }
}
