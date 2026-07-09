import AlgorithmKit
import SortEngineKit

/// ArrayV's `BitonicSortRecursive` — H.W. Lang's generalized recursive formulation of Bitonic
/// Sort (http://www.inf.fh-flensburg.de/lang/algorithmen/sortieren/bitonic/oddn.htm), which is
/// structurally different from the already-shipped ``BitonicSortIterative``: that one pads the
/// input up to the next power of two and walks it iteratively; this one works directly on any
/// `n`, no padding required. The trick lives entirely in ``bitonicMerge``: it splits its range at
/// `m = greatestPowerOfTwoLessThan(n)` — not `n / 2` — and only compares `i` against `i + m` for
/// the first `n - m` positions (not the whole range), which is exactly the generalization that
/// makes arbitrary-length merging correct.
///
/// `dir` alternates `true`/`false` through the ``bitonicSort`` recursion (one half ascending, the
/// other descending) to build the bitonic sequence that ``bitonicMerge`` then merges; the
/// top-level call always sorts ascending (`dir = true`), matching ArrayV's own `direction` field,
/// which defaults to `true` and this app never flips.
///
/// ``compare`` ports ArrayV's `if (dir == (cmp == 1)) swap(...)` exactly, including its asymmetry:
/// the ascending case (`dir == true`) only swaps on a *strict* `A[i] > A[j]`, while the descending
/// case (`dir == false`) swaps whenever `A[i]` is *not* strictly greater than `A[j]` — i.e. on
/// `<=`, including ties. That asymmetry is real ArrayV behavior, not a bug, so it's preserved via
/// the same boolean-equality structure rather than two separate strict `by:` comparators.
public struct BitonicSortRecursive: SortAlgorithm {
    public let id = AlgorithmID(rawValue: "bitonicsortrecursive")
    public let metadata = AlgorithmMetadata(
        displayName: "Bitonic Sort (Recursive)",
        category: .concurrent,
        sizeRange: 16...512,
        stable: false,
        timeComplexity: ComplexityBounds(
            best: "O(\\log^2{n})", average: "O(\\log^2{n})", worst: "O(\\log^2{n})"),
        // Unlike BitonicSortIterative's stated O(n log^2 n), this recursive formulation allocates
        // no auxiliary array at all — every comparison/swap happens directly on the live array —
        // so the only real memory cost is recursion-stack depth, which is O(log n).
        spaceComplexity: "O(\\log{n})",
        iconName: "arrow.up.and.down.righttriangle.up.righttriangle.down"
    )

    public init() {}

    public func record(into engine: inout RecordingEngine) {
        let n = engine.count
        guard n > 1 else { return }
        bitonicSort(&engine, 0, n, true)
    }

    private func greatestPowerOfTwoLessThan(_ n: Int) -> Int {
        var k = 1
        while k < n {
            k <<= 1
        }
        return k >> 1
    }

    private func compare(_ engine: inout RecordingEngine, _ i: Int, _ j: Int, _ dir: Bool) {
        let isGreater = engine.compare(i, j, by: (>))
        if dir == isGreater {
            engine.swap(i, j)
        }
    }

    private func bitonicMerge(_ engine: inout RecordingEngine, _ lo: Int, _ n: Int, _ dir: Bool) {
        guard n > 1 else { return }
        let m = greatestPowerOfTwoLessThan(n)
        for i in lo..<(lo + n - m) {
            compare(&engine, i, i + m, dir)
        }
        bitonicMerge(&engine, lo, m, dir)
        bitonicMerge(&engine, lo + m, n - m, dir)
    }

    private func bitonicSort(_ engine: inout RecordingEngine, _ lo: Int, _ n: Int, _ dir: Bool) {
        guard n > 1 else { return }
        let m = n / 2
        bitonicSort(&engine, lo, m, !dir)
        bitonicSort(&engine, lo + m, n - m, dir)
        bitonicMerge(&engine, lo, n, dir)
    }
}
