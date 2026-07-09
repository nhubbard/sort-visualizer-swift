import AlgorithmKit
import SortEngineKit

/// Most-Significant-Digit Radix Sort — ported from ArrayV's
/// `io.github.arrayv.sorts.distribute.MSDRadixSort` (`radixMSD`). Unlike `LSDRadixSort` (a single
/// iterative counting-sort pass per digit place, least-significant first), MSD recurses: at each
/// call it buckets the current `[min, max)` slice by one digit (starting from the *most*
/// significant), writes the buckets back in order, then recurses into each bucket's sub-range with
/// the next-less-significant digit. A bucket of size 0 or 1, or a range that has run out of digits
/// (`power < 0`), is already in its final position and the recursion bottoms out.
///
/// ArrayV builds one `ArrayList<Integer>[]` ("registers") per recursion frame, appends into it in
/// original left-to-right order (a stable distribution), transcribes it back into `array` starting
/// at `min`, recurses per bucket, then deletes the whole registers array. This mirrors that exactly
/// with one `createAuxArray`/`deleteAuxArray` pair per recursion frame standing in for `registers`.
public struct MSDRadixSort: SortAlgorithm {
    public let id = AlgorithmID(rawValue: "msdradixsort")
    public let metadata = AlgorithmMetadata(
        displayName: "MSD Radix Sort",
        category: .distribution,
        sizeRange: 16...512,
        stable: true,
        timeComplexity: ComplexityBounds(best: "O(d \\times n)", average: "O(d \\times n)", worst: "O(d \\times n)"),
        spaceComplexity: "O(n+b)",
        iconName: "square.stack.3d.forward.dottedline"
    )

    public init() {}

    public func record(into engine: inout RecordingEngine) {
        let n = engine.count
        guard n > 1 else { return }
        let radix = 4

        func intPow(_ base: Int, _ exponent: Int) -> Int {
            var result = 1
            for _ in 0..<exponent { result *= base }
            return result
        }

        func getDigit(_ value: Int, _ power: Int) -> Int {
            (value / intPow(radix, power)) % radix
        }

        // ArrayV's `Reads.analyzeMaxLog`: the most significant digit place that can distinguish
        // any value in the array, found without floating-point log (which can round a value that
        // sits exactly on a power of `radix` down by one and silently drop a whole digit place).
        var maxValue = 0
        for i in 0..<n {
            maxValue = max(maxValue, engine.values[i])
        }
        var highestPower = 0
        var probe = radix
        while probe <= maxValue {
            highestPower += 1
            probe *= radix
        }

        func radixMSD(_ min: Int, _ max: Int, _ power: Int) {
            guard min < max, power >= 0 else { return }

            // One fresh "registers" bucket array per recursion frame, exactly like ArrayV.
            var buckets = [[Int]](repeating: [], count: radix)
            for i in min..<max {
                buckets[getDigit(engine.values[i], power)].append(engine.values[i])
            }

            let handle = engine.createAuxArray(length: max - min)
            var writeIndex = min
            var auxIndex = 0
            for bucket in buckets {
                for value in bucket {
                    engine.writeAux(handle, at: auxIndex, value: value)
                    engine.setValue(writeIndex, value)
                    writeIndex += 1
                    auxIndex += 1
                }
            }

            // Recurse into each bucket's now-contiguous sub-range before releasing this frame's
            // aux array, matching ArrayV's transcribe-then-recurse-then-delete order.
            var start = min
            for bucket in buckets {
                radixMSD(start, start + bucket.count, power - 1)
                start += bucket.count
            }

            engine.deleteAuxArray(handle)
        }

        radixMSD(0, n, highestPower)
    }
}
