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
        BaseNMaxHeapSort(), BinaryDoubleInsertionSort(), BinaryGnomeSort(), BinaryInsertionSort(),
        BinaryMergeSort(), BingoSort(), BitonicSortIterative(), BitonicSortRecursive(), BogoSort(),
        BoseNelsonSortIterative(), BottomUpMergeSort(), BozoSort(), BubbleSort(), BurntPancakeSort(),
        CircleSortIterative(), CircleSortRecursive(), CocktailBogoSort(), CocktailMergeSort(),
        CocktailShakerSort(), CombSort(), CountingSort(), CycleSort(), DiamondSortRecursive(),
        DoubleInsertionSort(), DoubleSelectionSort(), DualPivotQuickSort(), ExchangeBogoSort(),
        FlashSort(), GnomeSort(), GravitySort(), HybridCombSort(), InPlaceMergeSort(),
        InsertionSort(), IntroCircleSortIterative(), IntroSort(), LessBogoSort(), LLQuickSort(),
        LSDRadixSort(), MaxHeapSort(), MergeExchangeSortIterative(), MergeSort(), MinHeapSort(),
        MSDRadixSort(), OddEvenMergeSortIterative(), OddEvenMergeSortRecursive(), OddEvenSort(),
        OptimizedBubbleSort(), OptimizedCocktailShakerSort(), OptimizedGnomeSort(), PancakeSort(),
        PigeonholeSort(), QuickSort(), RecursiveShellSort(), RotateMergeSort(), SelectionSort(),
        ShellSort(), SimplifiedLibrarySort(), SlopeSort(), SlowSort(), SnuffleSort(),
        StableCycleSort(), StableSelectionSort(), StaticSort(), StoogeSort(), StrandSort(),
        SwaplessBubbleSort(), TernaryLLQuickSort(), TernaryLRQuickSort(), UnoptimizedBubbleSort(),
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
}
