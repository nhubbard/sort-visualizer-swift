import AlgorithmKit
import SortEngineKit

/// ArrayV's `CircleSortRecursive` (`sorts/exchange/CircleSortRecursive.java`), built on the shared
/// `sorts/templates/CircleSorting.java` base that ``CircleSortIterative`` (if/when ported) also
/// extends. Both siblings share the same fundamental idea — a symmetric compare-and-swap pass that
/// converges a range's two ends toward its middle — but this one reaches the next level down via
/// genuine recursion into the two resulting half-ranges, rather than the iterative version's
/// explicit nested `gap`/`start` loop structure.
///
/// Like the iterative sibling, the recursion's working size (`n`, the initial `hi` bound passed to
/// ``circleSortRoutine``) is padded up to the next power of two at or above the real array length
/// (`end`), while every actual array access — both the compare/swap itself and the decision to
/// recurse into the second half — stays guarded against `end`. Two guards matter here, both ported
/// exactly from ArrayV's `CircleSorting.circleSortRoutine`:
/// - `hi < end` gates only the compare-and-swap, not the convergence loop itself, so `lo`/`hi` keep
///   marching toward the middle (and `mid` keeps being computed from their original span) even
///   while `hi` still points past the real array.
/// - `low + mid + 1 < end` gates whether the *second* half is even worth recursing into — mirroring
///   ArrayV's own asymmetry: the first half `[low, low + mid]` is always recursed into, but the
///   second half `[low + mid + 1, high]` is skipped entirely once it would start beyond `end`.
///
/// One pass is a full top-to-bottom recursive sweep; ArrayV's `runSort` repeats that sweep
/// (`do { ... } while (numberOfSwaps != 0)`) until a sweep performs zero swaps, at which point the
/// array is sorted. `circleSortRoutine`'s own swap-count return value is a plain running total —
/// unlike ArrayV's Java, which threads an accumulator parameter through both recursive calls, this
/// port sums the while-loop's own count with both recursive calls' returned counts directly, which
/// is arithmetically identical (addition doesn't care which side already had which partial sum) and
/// avoids an extra parameter with no behavioral difference.
public struct CircleSortRecursive: SortAlgorithm {
    public let id = AlgorithmID(rawValue: "circlesortrecursive")
    public let metadata = AlgorithmMetadata(
        displayName: "Circle Sort (Recursive)",
        category: .exchange,
        sizeRange: 16...512,
        stable: false,
        timeComplexity: ComplexityBounds(
            best: "O(n \\log{n})", average: "O(n \\log^2{n})", worst: "O(n \\log^2{n})"),
        // Distinct from CircleSortIterative's O(1): this version genuinely recurses into two
        // half-ranges per level, so it carries a real O(log n) recursion-stack depth on top of the
        // otherwise in-place compare-and-swap work.
        spaceComplexity: "O(\\log{n})",
        iconName: "repeat.circle.fill"
    )

    public init() {}

    public func record(into engine: inout RecordingEngine) {
        let end = engine.count
        guard end > 1 else { return }

        var n = 1
        while n < end {
            n *= 2
        }

        func circleSortRoutine(_ lo: Int, _ hi: Int) -> Int {
            if lo == hi { return 0 }

            let low = lo
            let high = hi
            let mid = (hi - lo) / 2

            var lo = lo
            var hi = hi
            var swapCount = 0
            while lo < hi {
                if hi < end, engine.compare(lo, hi, by: (>)) {
                    engine.swap(lo, hi)
                    swapCount += 1
                }
                lo += 1
                hi -= 1
            }

            swapCount += circleSortRoutine(low, low + mid)
            if low + mid + 1 < end {
                swapCount += circleSortRoutine(low + mid + 1, high)
            }
            return swapCount
        }

        var numberOfSwaps: Int
        repeat {
            numberOfSwaps = circleSortRoutine(0, n - 1)
        } while numberOfSwaps != 0
    }
}
