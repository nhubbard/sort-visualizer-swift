import AlgorithmKit
import SortEngineKit
import Testing
@testable import BuiltInAlgorithms

/// The native-Swift counterpart to `ScriptingKitTests`' `BundledContentCorrectnessTests` — same
/// "record against real input, assert the result is sorted" shape, now covering every algorithm
/// that used to be a `.js`/`.manifest.json` pair before all 20 were ported to native Swift.
@Suite
struct NativeAlgorithmCorrectnessTests {
    private static let algorithms: [any SortAlgorithm] = [
        BadSort(), BaseNMaxHeapSort(), BinaryDoubleInsertionSort(), BinaryGnomeSort(),
        BinaryInsertionSort(), BinaryMergeSort(), BingoSort(), BitonicSortIterative(),
        BitonicSortRecursive(), BlockSwapMergeSort(), BogoSort(), BoseNelsonSortIterative(),
        BottomUpMergeSort(), BozoSort(), BubbleSort(), BurntPancakeSort(),
        CircleSortIterative(), CircleSortRecursive(), ClassicTreeSort(), CocktailBogoSort(),
        CocktailMergeSort(), CocktailShakerSort(), CombSort(), CountingSort(), CycleSort(),
        DiamondSortRecursive(), DoubleInsertionSort(), DoubleSelectionSort(),
        DualPivotQuickSort(), ExchangeBogoSort(), FlashSort(), GnomeSort(), GravitySort(),
        HybridCombSort(), InPlaceMergeSort(), InsertionSort(), IntroCircleSortIterative(),
        IntroSort(), LessBogoSort(), LLQuickSort(), LSDRadixSort(), MaxHeapSort(),
        MergeExchangeSortIterative(), MergeSort(), MinHeapSort(), MSDRadixSort(),
        OddEvenMergeSortIterative(), OddEvenMergeSortRecursive(), OddEvenSort(),
        OptimizedBubbleSort(), OptimizedCocktailShakerSort(), OptimizedGnomeSort(),
        PairwiseSortIterative(), PancakeSort(), PigeonholeSort(), QuickSort(),
        RecursiveShellSort(), RotateMergeSort(), SelectionSort(), ShellSort(),
        SimplifiedLibrarySort(), SlopeSort(), SlowSort(), SnuffleSort(), StableCycleSort(),
        StableSelectionSort(), StaticSort(), StoogeSort(), StrandSort(), SwaplessBubbleSort(),
        TernaryLLQuickSort(), TernaryLRQuickSort(), TriangularHeapSort(), UnoptimizedBubbleSort(),
        WeavedMergeSort(), WeaveMergeSort()
    ]

    @Test
    func everyAlgorithmHasAUniqueID() {
        let ids = Self.algorithms.map(\.id)
        #expect(Set(ids).count == ids.count, "duplicate AlgorithmID across native algorithms")
    }

    @Test
    func everyAlgorithmSortsRandomInputsCorrectly() {
        for algorithm in Self.algorithms {
            // Each algorithm's own sizeRange lower bound — always in its comfortable range, and
            // small enough that even BogoSort-like algorithms stay fast.
            let size = algorithm.metadata.sizeRange.lowerBound

            for attempt in 0..<3 {
                let input = (0..<size).map { _ in Int.random(in: 0...1000) }
                var engine = RecordingEngine(values: input)
                algorithm.record(into: &engine)

                #expect(
                    engine.values == input.sorted(),
                    """
                    \(algorithm.id.rawValue) failed to sort random attempt \(attempt) of size \(size): \
                    \(input) -> \(engine.values)
                    """
                )
            }
        }
    }

    @Test
    func everyAlgorithmSortsAlreadySortedInput() {
        for algorithm in Self.algorithms {
            let size = algorithm.metadata.sizeRange.lowerBound
            let input = Array(0..<size)
            var engine = RecordingEngine(values: input)
            algorithm.record(into: &engine)

            #expect(
                engine.values == input,
                "\(algorithm.id.rawValue) failed on already-sorted input of size \(size): -> \(engine.values)"
            )
        }
    }

    @Test
    func everyAlgorithmSortsReverseSortedInput() {
        for algorithm in Self.algorithms {
            let size = algorithm.metadata.sizeRange.lowerBound
            let input = Array((0..<size).reversed())
            var engine = RecordingEngine(values: input)
            algorithm.record(into: &engine)

            #expect(
                engine.values == input.sorted(),
                "\(algorithm.id.rawValue) failed on reverse-sorted input of size \(size): \(input) -> \(engine.values)"
            )
        }
    }

    @Test
    func everyAlgorithmSortsInputWithDuplicateValues() {
        for algorithm in Self.algorithms {
            let size = algorithm.metadata.sizeRange.lowerBound
            let input = (0..<size).map { _ in Int.random(in: 0...3) }
            var engine = RecordingEngine(values: input)
            algorithm.record(into: &engine)

            #expect(
                engine.values == input.sorted(),
                """
                \(algorithm.id.rawValue) failed on heavily-duplicated input of size \(size): \
                \(input) -> \(engine.values)
                """
            )
        }
    }

    /// No existing test in this suite exercises stability, so this one verifies
    /// `IntroCircleSortIterative`'s `stable: false` conclusion (see its doc comment) empirically,
    /// with tagged-duplicate input: each element's *original* index is tracked independently of
    /// its (heavily duplicated) compared value by replaying the recorded tape's `.swap` operations
    /// onto a parallel identity array — `originalIndex[k]` ends up holding whichever starting index
    /// the element now sitting at final position `k` came from. A stable sort would leave every
    /// group of equal final values with strictly increasing original indices (since equal values
    /// are scanned left-to-right into the input in increasing-index order); finding any group where
    /// a later position's original index is smaller than an earlier one directly witnesses two
    /// equal elements crossing each other's original relative order.
    @Test
    func introCircleSortIterativeIsNotStable() {
        let algorithm = IntroCircleSortIterative()
        let size = algorithm.metadata.sizeRange.lowerBound

        var foundReordering = false
        for _ in 0..<25 {
            let input = (0..<size).map { _ in Int.random(in: 0...3) }
            var engine = RecordingEngine(values: input)
            algorithm.record(into: &engine)
            let summary = engine.finish()

            var originalIndex = Array(0..<size)
            for operation in summary.tape {
                if case let .swap(i, j) = operation {
                    originalIndex.swapAt(i, j)
                }
            }

            var lastOriginalIndexForValue: [Int: Int] = [:]
            for position in 0..<size {
                let value = engine.values[position]
                let tag = originalIndex[position]
                if let previousTag = lastOriginalIndexForValue[value], previousTag > tag {
                    foundReordering = true
                    break
                }
                lastOriginalIndexForValue[value] = tag
            }

            if foundReordering { break }
        }

        #expect(
            foundReordering,
            "expected at least one tagged-duplicate trial to reorder equal elements, confirming introcirclesortiterative is not stable"
        )
    }

    /// `WeaveMergeSort`'s own doc comment reasons that `weaveInsert`'s non-strict (`<=`)
    /// tie-swapping shift condition should reorder equal elements, but calls that conclusion
    /// untractable to hand-prove given how it interacts with the position-blind weave step and the
    /// recursive calls beneath it — so, mirroring how `WeavedMergeSort`/`StaticSort`/`FlashSort`
    /// were each verified, this replays the recorded tape's `.swap` operations against a shadow
    /// array of original indices (rather than encoding tags into the values themselves, which
    /// would eliminate the very ties being tested) to see where every element with a given input
    /// value actually ends up, independent of what value it carries.
    @Test
    func weaveMergeSortTiedElementsCanLoseTheirOriginalRelativeOrder() {
        let algorithm = WeaveMergeSort()
        let size = 64
        var sawReordering = false

        for _ in 0..<50 {
            let input = (0..<size).map { _ in Int.random(in: 0...3) }
            var engine = RecordingEngine(values: input)
            algorithm.record(into: &engine)

            // `shadow[finalPosition]` is the ORIGINAL index of whichever element now sits at
            // `finalPosition` — start as the identity permutation and replay every recorded swap
            // onto it in lockstep with the engine's own `values` swaps (this algorithm never calls
            // `setValue`/aux writes, only `swap`, so replaying `.swap` alone fully reconstructs the
            // final permutation).
            var shadow = Array(0..<size)
            for operation in engine.finish().tape {
                if case let .swap(i, j) = operation {
                    shadow.swapAt(i, j)
                }
            }

            // For each distinct input value, the original indices of every element sharing that
            // value, read off in FINAL array order. A stable sort would leave each such list
            // already ascending (original order preserved); this checks whether any is not.
            var originalIndicesByValueInFinalOrder: [Int: [Int]] = [:]
            for finalPosition in 0..<size {
                let originalIndex = shadow[finalPosition]
                let value = input[originalIndex]
                originalIndicesByValueInFinalOrder[value, default: []].append(originalIndex)
            }

            if originalIndicesByValueInFinalOrder.values.contains(where: { $0 != $0.sorted() }) {
                sawReordering = true
                break
            }
        }

        #expect(
            sawReordering,
            """
            expected WeaveMergeSort's tie-swapping weaveInsert shift to reorder at least one run \
            of equal-valued elements relative to their original input order across randomized \
            duplicate-heavy trials, confirming it is not a stable sort
            """
        )
    }

    /// `BadSort`'s doc comment reasons that swap-based selection (unconditionally exchanging
    /// whatever sits at `i` with the leftmost suffix minimum at `shortest`) inherits ordinary
    /// selection sort's classic instability, and works out a concrete counterexample by hand
    /// (`[3a, 4, 3b, 2]` comes out with its two `3`s reversed). This confirms that conclusion
    /// empirically as well, mirroring `weaveMergeSortTiedElementsCanLoseTheirOriginalRelativeOrder`:
    /// replay the recorded tape's `.swap` operations against a shadow array of original indices
    /// (`BadSort` never calls `setValue`/aux writes, only `compare`/`swap`, so replaying `.swap`
    /// alone fully reconstructs the final permutation) across randomized heavily-duplicated trials.
    @Test
    func badSortTiedElementsCanLoseTheirOriginalRelativeOrder() {
        let algorithm = BadSort()
        let size = algorithm.metadata.sizeRange.lowerBound
        var sawReordering = false

        for _ in 0..<50 {
            let input = (0..<size).map { _ in Int.random(in: 0...3) }
            var engine = RecordingEngine(values: input)
            algorithm.record(into: &engine)

            var shadow = Array(0..<size)
            for operation in engine.finish().tape {
                if case let .swap(i, j) = operation {
                    shadow.swapAt(i, j)
                }
            }

            var originalIndicesByValueInFinalOrder: [Int: [Int]] = [:]
            for finalPosition in 0..<size {
                let originalIndex = shadow[finalPosition]
                let value = input[originalIndex]
                originalIndicesByValueInFinalOrder[value, default: []].append(originalIndex)
            }

            if originalIndicesByValueInFinalOrder.values.contains(where: { $0 != $0.sorted() }) {
                sawReordering = true
                break
            }
        }

        #expect(
            sawReordering,
            """
            expected BadSort's swap-based leftmost-suffix-minimum selection to reorder at least one \
            run of equal-valued elements relative to their original input order across randomized \
            duplicate-heavy trials, confirming it is not a stable sort
            """
        )
    }

    /// `ClassicTreeSort`'s doc comment analytically argues stability (ties always route to `upper`,
    /// traversal is left-self-right, so a later duplicate always ties into an earlier one's `upper`
    /// subtree, visited after it). Unlike `WeaveMergeSort`/`IntroCircleSortIterative`, this algorithm
    /// never calls `engine.swap` on the main array at all — its only main-array writes are the final
    /// value-copying `setValue` loop, which erases which original index produced which output value
    /// once duplicates are involved, so replaying the recorded tape can't reconstruct provenance here.
    /// Instead, this reimplements the identical routing/traversal rule directly over `(value,
    /// originalIndex)` pairs, comparing only on `value` (exactly mirroring `array[i] < array[c]`), and
    /// checks that every group of equal final values keeps strictly ascending original indices.
    @Test
    func classicTreeSortTiedElementsKeepTheirOriginalRelativeOrder() {
        struct Tagged { let value: Int; let originalIndex: Int }

        func classicTreeSortTagged(_ array: [Tagged]) -> [Tagged] {
            let n = array.count
            guard n > 1 else { return array }

            var lower = [Int](repeating: 0, count: n)
            var upper = [Int](repeating: 0, count: n)

            for i in 1..<n {
                var c = 0
                while true {
                    if array[i].value < array[c].value {
                        if lower[c] == 0 { lower[c] = i; break } else { c = lower[c] }
                    } else {
                        if upper[c] == 0 { upper[c] = i; break } else { c = upper[c] }
                    }
                }
            }

            var temp = [Tagged](repeating: array[0], count: n)
            var idx = 0
            func traverse(_ r: Int) {
                if lower[r] != 0 { traverse(lower[r]) }
                temp[idx] = array[r]
                idx += 1
                if upper[r] != 0 { traverse(upper[r]) }
            }
            traverse(0)
            return temp
        }

        let size = 64
        for _ in 0..<200 {
            let values = (0..<size).map { _ in Int.random(in: 0...3) }
            let tagged = values.enumerated().map { Tagged(value: $0.element, originalIndex: $0.offset) }
            let sorted = classicTreeSortTagged(tagged)

            #expect(sorted.map(\.value) == values.sorted())

            var byValue: [Int: [Int]] = [:]
            for t in sorted {
                byValue[t.value, default: []].append(t.originalIndex)
            }
            for (value, indices) in byValue {
                #expect(
                    indices == indices.sorted(),
                    "classictreesort reordered equal-valued elements (value \(value)): \(indices)"
                )
            }
        }
    }

    /// `TriangularHeapSort`'s doc comment reasons that, like `MaxHeapSort`, swap-based heap
    /// construction/extraction can relocate one of two equal elements past the other with no
    /// recovery mechanism, and verifies this empirically — mirroring
    /// `weaveMergeSortTiedElementsCanLoseTheirOriginalRelativeOrder`'s tape-replay approach.
    @Test
    func triangularHeapSortTiedElementsCanLoseTheirOriginalRelativeOrder() {
        let algorithm = TriangularHeapSort()
        let size = 64
        var sawReordering = false

        for _ in 0..<50 {
            let input = (0..<size).map { _ in Int.random(in: 0...3) }
            var engine = RecordingEngine(values: input)
            algorithm.record(into: &engine)

            var shadow = Array(0..<size)
            for operation in engine.finish().tape {
                if case let .swap(i, j) = operation {
                    shadow.swapAt(i, j)
                }
            }

            var originalIndicesByValueInFinalOrder: [Int: [Int]] = [:]
            for finalPosition in 0..<size {
                let originalIndex = shadow[finalPosition]
                let value = input[originalIndex]
                originalIndicesByValueInFinalOrder[value, default: []].append(originalIndex)
            }

            if originalIndicesByValueInFinalOrder.values.contains(where: { $0 != $0.sorted() }) {
                sawReordering = true
                break
            }
        }

        #expect(
            sawReordering,
            """
            expected TriangularHeapSort's swap-based heap construction/extraction to reorder at \
            least one run of equal-valued elements relative to their original input order across \
            randomized duplicate-heavy trials, confirming it is not a stable sort
            """
        )
    }

    /// `BlockSwapMergeSort`'s own doc comment reasons that `binarySearchMid`'s strict-greater-than
    /// tie-break should preserve equal elements' original relative order (unlike `WeaveMergeSort`'s
    /// tie-swapping instability) — verified here empirically, mirroring `RotateMergeSort`'s tagged-
    /// duplicate approach: tagging each element with its original index and sorting purely on the
    /// (heavily duplicated) untagged value, then replaying the recorded tape's swaps to find each
    /// tag's final resting position. A stable sort leaves every group of equal final values with
    /// strictly ascending original-index tags.
    @Test
    func blockSwapMergeSortIsStable() {
        let algorithm = BlockSwapMergeSort()
        let size = 64

        for _ in 0..<50 {
            let input = (0..<size).map { _ in Int.random(in: 0...3) }
            var engine = RecordingEngine(values: input)
            algorithm.record(into: &engine)

            var shadow = Array(0..<size)
            for operation in engine.finish().tape {
                if case let .swap(i, j) = operation {
                    shadow.swapAt(i, j)
                }
            }

            var originalIndicesByValueInFinalOrder: [Int: [Int]] = [:]
            for finalPosition in 0..<size {
                let originalIndex = shadow[finalPosition]
                let value = input[originalIndex]
                originalIndicesByValueInFinalOrder[value, default: []].append(originalIndex)
            }

            #expect(
                originalIndicesByValueInFinalOrder.values.allSatisfy { $0 == $0.sorted() },
                "expected blockswapmergesort to preserve original relative order among tied elements"
            )
        }
    }

    /// `PairwiseSortIterative`'s own doc comment reasons that indirect transpositions through the
    /// fixed comparator network (each element separately swapping against some third, unequal
    /// element) could reorder equal elements even though every direct comparison only swaps on a
    /// strict `>` — but calls that untractable to conclude by inspection alone, so, mirroring how
    /// `WeaveMergeSort`/`IntroCircleSortIterative` were each verified, this replays the recorded
    /// tape's `.swap` operations against a shadow array of original indices to see where every
    /// element with a given input value actually ends up, independent of what value it carries.
    @Test
    func pairwiseSortIterativeTiedElementsCanLoseTheirOriginalRelativeOrder() {
        let algorithm = PairwiseSortIterative()
        let size = 64
        var sawReordering = false

        for _ in 0..<50 {
            let input = (0..<size).map { _ in Int.random(in: 0...3) }
            var engine = RecordingEngine(values: input)
            algorithm.record(into: &engine)

            var shadow = Array(0..<size)
            for operation in engine.finish().tape {
                if case let .swap(i, j) = operation {
                    shadow.swapAt(i, j)
                }
            }

            var originalIndicesByValueInFinalOrder: [Int: [Int]] = [:]
            for finalPosition in 0..<size {
                let originalIndex = shadow[finalPosition]
                let value = input[originalIndex]
                originalIndicesByValueInFinalOrder[value, default: []].append(originalIndex)
            }

            if originalIndicesByValueInFinalOrder.values.contains(where: { $0 != $0.sorted() }) {
                sawReordering = true
                break
            }
        }

        #expect(
            sawReordering,
            """
            expected PairwiseSortIterative's fixed comparator network to reorder at least one run \
            of equal-valued elements relative to their original input order across randomized \
            duplicate-heavy trials, confirming it is not a stable sort
            """
        )
    }
}
