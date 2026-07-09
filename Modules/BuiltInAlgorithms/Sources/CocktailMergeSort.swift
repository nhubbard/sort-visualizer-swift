import AlgorithmKit
import SortEngineKit

/// A hybrid, "just for fun" sort (per ArrayV's own source comment, inspired by the YouTube video
/// "Obscure Sorting Algorithms" by Sorting Stuff) that splices Cocktail Shaker Sort into TimSort's
/// run-building step: instead of using (Binary) Insertion Sort to build TimSort's initial minimum-
/// length runs, it uses Cocktail Shaker Sort on each fixed-size chunk, then merges the resulting
/// runs together the way TimSort does.
///
/// **Simplification from ArrayV's real algorithm**: ArrayV's `TimSorting` helper is a ~950-line
/// port of full TimSort machinery — a run-length stack, galloping-mode merges that adaptively skip
/// large already-ordered stretches, and related constant-factor optimizations. None of that
/// machinery changes *what* the sort produces, only *how fast* it produces it: TimSort's merge
/// step is still, at its core, "repeatedly merge the two smallest adjacent pending runs into one
/// larger sorted run until only one run remains," and galloping is purely a way to do that merge
/// with fewer comparisons when one run is consuming much faster than the other. This port
/// therefore replaces the galloping run-stack merge with a plain, standard bottom-up pairwise
/// merge — the same doubling-width technique as this codebase's own `BottomUpMergeSort`, just
/// starting from an initial run width of `minRunLen` (produced by Cocktail Shaker) instead of a
/// width of 1 (the trivially-sorted single-element "runs" `BottomUpMergeSort` starts from). Because
/// both strategies merge the exact same fully-sorted runs using the exact same stable
/// take-the-left-run-on-ties comparison, the final sorted order — and the algorithm's stability —
/// is identical either way; only the number of comparisons spent getting there differs.
///
/// Big-O-wise, this is still a hybrid worth calling out: building runs costs Cocktail Shaker's
/// O(minRunLen^2) per chunk across O(n / minRunLen) chunks, i.e. O(n * minRunLen) — and since
/// `minRunLen` is capped at 64 regardless of `n` (TimSort's classic minrun invariant), that term is
/// just O(n) with a chunky constant factor, not O(n^2) overall. The merge phase is a standard
/// O(n log(n / minRunLen)) bottom-up merge, i.e. O(n log n). So the whole sort is O(n log n) on
/// average and in the best case. The worst case is quoted as O(n^2) here because Cocktail Shaker's
/// own worst case is quadratic *in its chunk size*, and although that chunk size is bounded by a
/// constant (~64) for large `n`, for the small arrays this visualizer actually runs (`sizeRange`
/// below), `n` and `minRunLen` frequently coincide (`n < 64` always triggers the "just run Cocktail
/// Shaker over the whole array" branch below) — so at the sizes this app visualizes, worst-case
/// behavior is realistically Cocktail Shaker Sort's own O(n^2), and it would be misleading to quote
/// a clean O(n log n) worst case here.
public struct CocktailMergeSort: SortAlgorithm {
    public let id = AlgorithmID(rawValue: "cocktailmergesort")
    public let metadata = AlgorithmMetadata(
        displayName: "Cocktail Merge Sort",
        category: .hybrid,
        sizeRange: 16...512,
        stable: true,
        timeComplexity: ComplexityBounds(
            best: "O(n log n)", average: "O(n log n)", worst: "O(n^2)"),
        spaceComplexity: "O(n)",
        iconName: "arrow.triangle.merge"
    )
    public init() {}

    /// TimSort's standard "minimum run length" calculation: repeatedly right-shift `n` until it's
    /// under 64, tracking whether any 1-bit was shifted out along the way, then fold that bit back
    /// in. This keeps run counts balanced (a power of two, or close to it) and avoids leaving one
    /// drastically-shorter run at the end. Note that for any `n < 64` this simply returns `n`
    /// itself (the loop never runs), which is why `record(into:)` below always takes the "just
    /// Cocktail-Shaker the whole array" branch at the small sizes this app visualizes.
    static func minRunLength(_ n: Int) -> Int {
        var n = n
        var r = 0
        while n >= 64 {
            r |= n & 1
            n >>= 1
        }
        return n + r
    }

    public func record(into engine: inout RecordingEngine) {
        let n = engine.count
        guard n > 1 else { return }

        let minRunLen = Self.minRunLength(n)

        // Cocktail Shaker Sort, restricted to the half-open range [start, end) — CocktailShakerSort.swift's
        // logic with every index shifted to be `start`-relative and bounded by the chunk's own
        // length instead of the whole array's.
        func cocktailShaker(_ start: Int, _ end: Int) {
            let length = end - start
            guard length > 1 else { return }

            var i = 0
            while i < length / 2 {
                var sorted = true

                // Strict `>` (not the default `>=`) — matches ArrayV's real `Reads.compareValues`
                // condition, which never swaps on a tie; see `CocktailShakerSort.swift`.
                var j = i
                while j < length - i - 1 {
                    if engine.compare(start + j, start + j + 1, by: (>)) {
                        engine.swap(start + j, start + j + 1)
                        sorted = false
                    }
                    j += 1
                }

                j = length - i - 1
                while j > i {
                    if engine.compare(start + j - 1, start + j, by: (>)) {
                        engine.swap(start + j - 1, start + j)
                        sorted = false
                    }
                    j -= 1
                }

                if sorted { break }
                i += 1
            }
        }

        // ArrayV special-cases sortLength == minRunLen: there'd only be a single run, so building
        // it and then "merging" it alone would be a no-op wrapped around plain Cocktail Shaker Sort.
        guard n != minRunLen else {
            cocktailShaker(0, n)
            return
        }

        // Build fixed-length (minRunLen) runs, Cocktail-Shaker-sorting each in place. The final
        // chunk is shorter than minRunLen whenever minRunLen doesn't evenly divide n.
        var i = 0
        while i <= n - minRunLen {
            cocktailShaker(i, i + minRunLen)
            i += minRunLen
        }
        if i < n {
            cocktailShaker(i, n)
        }

        // Simplified TimSort merge phase: a standard bottom-up pairwise merge (see the type's doc
        // comment above for why this is a correctness-preserving stand-in for ArrayV's galloping
        // TimSort merge), structured exactly like `BottomUpMergeSort.swift`'s own `merge` helper,
        // except the initial atomic run width is `minRunLen` (from Cocktail Shaker, above) instead
        // of 1, so the doubling sequence of merge widths starts at `2 * minRunLen` instead of `2`.
        let tempHandle = engine.createAuxArray(length: n)
        var scratch = engine.values

        @discardableResult
        func merge(_ index: Int, _ mergeSize: Int) -> Int? {
            let mid = index + mergeSize / 2
            let end = min(n, index + mergeSize)

            guard mid < end else {
                return index
            }

            var left = index
            var right = mid
            var scratchIndex = index

            while left < mid && right < end {
                if engine.compare(right, left) {
                    scratch[scratchIndex] = engine.values[left]
                    engine.writeAux(tempHandle, at: scratchIndex, value: engine.values[left])
                    left += 1
                } else {
                    scratch[scratchIndex] = engine.values[right]
                    engine.writeAux(tempHandle, at: scratchIndex, value: engine.values[right])
                    right += 1
                }
                scratchIndex += 1
            }
            while left < mid {
                scratch[scratchIndex] = engine.values[left]
                engine.writeAux(tempHandle, at: scratchIndex, value: engine.values[left])
                left += 1
                scratchIndex += 1
            }
            while right < end {
                scratch[scratchIndex] = engine.values[right]
                engine.writeAux(tempHandle, at: scratchIndex, value: engine.values[right])
                right += 1
                scratchIndex += 1
            }
            return nil
        }

        var mergeSize = minRunLen * 2
        while mergeSize <= n {
            var copyLength = n
            var idx = 0
            while idx < n {
                if let override = merge(idx, mergeSize) {
                    copyLength = override
                }
                idx += mergeSize
            }
            for j in 0..<copyLength {
                engine.setValue(j, scratch[j])
            }
            mergeSize *= 2
        }
        if mergeSize / 2 != n {
            var copyLength = n
            if let override = merge(0, mergeSize) {
                copyLength = override
            }
            for j in 0..<copyLength {
                engine.setValue(j, scratch[j])
            }
        }

        engine.deleteAuxArray(tempHandle)
    }
}
