import AlgorithmKit
import SortEngineKit

public struct OddEvenMergeSortRecursive: SortAlgorithm {
    public let id = AlgorithmID(rawValue: "oddevenmergesortrecursive")
    public let metadata = AlgorithmMetadata(
        displayName: "Odd-Even Merge Sort (Recursive)",
        category: .concurrent,
        sizeRange: 16...256,
        stable: false,
        timeComplexity: ComplexityBounds(
            best: "O(log^2 n)", average: "O(log^2 n)", worst: "O(log^2 n)"),
        // Unlike `OddEvenMergeSortIterative`, this formulation never materializes an aux array —
        // it's pure recursive index/size arithmetic over the live array, so the honest bound here
        // is recursion stack depth (same reasoning as the Bitonic Recursive sibling), not the
        // iterative sibling's O(n log^2 n).
        spaceComplexity: "O(log n)",
        iconName: "network"
    )

    public init() {}

    public func record(into engine: inout RecordingEngine) {
        let n = engine.count
        guard n > 1 else { return }

        // ArrayV's `oddEvenMergeCompare`: the only place values are ever read — everything else in
        // this algorithm is pure recursive index/size arithmetic.
        func oddEvenMergeCompare(_ i: Int, _ j: Int) {
            if engine.compare(i, j, by: (>)) {
                engine.swap(i, j)
            }
        }

        // ArrayV's `oddEvenMerge`, credited to a rewrite by Piotr Grochowski (building on H.W.
        // Lang's original power-of-two-only network) that generalizes Batcher's odd-even merge to
        // work directly on array lengths that aren't a power of two. `lo` is the start of the piece
        // being merged, `m2` is the halfway point (threaded through independently of `lo`/`n`, not
        // recomputed from them), `n` is the length of the piece (which can grow by `r` in the
        // odd-`(n/r)` branch below), and `r` is the comparison distance, doubling each level via
        // `m = r * 2`. Every parity-dependent branch below is preserved exactly as ArrayV has it —
        // simplifying any of them would silently break correctness for most non-power-of-two
        // lengths while still passing on power-of-two test arrays.
        func oddEvenMerge(_ lo: Int, _ m2: Int, _ n: Int, _ r: Int) {
            let m = r * 2
            if m < n {
                if (n / r) % 2 != 0 {
                    oddEvenMerge(lo, (m2 + 1) / 2, n + r, m) // even subsequence
                    oddEvenMerge(lo + r, m2 / 2, n - r, m) // odd subsequence
                } else {
                    oddEvenMerge(lo, (m2 + 1) / 2, n, m) // even subsequence
                    oddEvenMerge(lo + r, m2 / 2, n, m) // odd subsequence
                }

                if m2 % 2 != 0 {
                    var i = lo
                    while i + r < lo + n {
                        oddEvenMergeCompare(i, i + r)
                        i += m
                    }
                } else {
                    var i = lo + r
                    while i + r < lo + n {
                        oddEvenMergeCompare(i, i + r)
                        i += m
                    }
                }
            } else {
                if n > r {
                    oddEvenMergeCompare(lo, lo + r)
                }
            }
        }

        // ArrayV's `oddEvenMergeSort`: split in half, sort each half recursively, then merge the
        // two sorted halves via `oddEvenMerge` starting at comparison distance `r = 1`.
        func oddEvenMergeSort(_ lo: Int, _ n: Int) {
            if n > 1 {
                let m = n / 2
                oddEvenMergeSort(lo, m)
                oddEvenMergeSort(lo + m, n - m)
                oddEvenMerge(lo, m, n, 1)
            }
        }

        oddEvenMergeSort(0, n)
    }
}
