import AlgorithmKit
import SortEngineKit

/// The non-recursive twin of `MergeSort`: instead of recursing top-down, it iterates over
/// doubling merge-run widths (`mergeSize` = 2, 4, 8, ...) and merges every adjacent pair of runs
/// of that width across the whole array in one pass, writing the pass's results into a
/// full-length scratch buffer before copying them back and doubling the width again.
///
/// Ported faithfully from ArrayV's `io.github.arrayv.sorts.merge.BottomUpMergeSort`, including its
/// `copyLength` trick for the final partial run: `merge(index, mergeSize)` reads `left`/`mid`/
/// `right`/`end` exactly as ArrayV does, and when the "right" half is empty (the tail chunk is
/// shorter than half a run — only possible on the last chunk of a pass, since every earlier chunk
/// is a full `mergeSize`), it performs no writes and reports `index` as the point past which the
/// pass's scratch contents shouldn't be copied back (the untouched tail is already correctly
/// ordered from the previous pass, so leaving it alone is safe). ArrayV also runs one extra fixup
/// merge after the main loop whenever `currentLength` isn't a power of two, folding the final
/// undersized run into the rest of the array; that fixup is reproduced here via the same `merge`
/// helper called once more at `index = 0`.
public struct BottomUpMergeSort: SortAlgorithm {
    public let id = AlgorithmID(rawValue: "bottomupmergesort")
    public let metadata = AlgorithmMetadata(
        displayName: "Bottom-up Merge Sort",
        category: .merge,
        sizeRange: 16...512,
        stable: true,
        timeComplexity: ComplexityBounds(
            best: "O(n log n)", average: "O(n log n)", worst: "O(n log n)"),
        spaceComplexity: "O(n)",
        iconName: "rectangle.stack"
    )
    public init() {}

    public func record(into engine: inout RecordingEngine) {
        let n = engine.count
        guard n >= 2 else { return }
        let tempHandle = engine.createAuxArray(length: n)
        // The real backing store for the scratch buffer — `writeAux` only feeds the tape/visualizer,
        // it can't be read back, so the merge's actual working data lives here (mirroring how
        // MergeSort.swift keeps its own `merged` array alongside the aux writes).
        var scratch = engine.values

        // Merges the two runs of length `mergeSize / 2` starting at `index` (clamped to the array's
        // end for the last, possibly-partial, pair of runs) into `scratch`. Returns a non-nil
        // "copy up to here" override only when the right run turned out to be empty — ArrayV's
        // `copyLength = left` branch — otherwise returns nil, meaning the caller should copy the
        // whole scratch buffer back once the pass finishes.
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

        var mergeSize = 2
        while mergeSize <= n {
            var copyLength = n
            var i = 0
            while i < n {
                if let override = merge(i, mergeSize) {
                    copyLength = override
                }
                i += mergeSize
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
