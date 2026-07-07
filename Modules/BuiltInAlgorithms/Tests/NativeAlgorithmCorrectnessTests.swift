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
        BinaryDoubleInsertionSort(), BinaryGnomeSort(), BinaryInsertionSort(), BinaryMergeSort(),
        BingoSort(), BitonicSortIterative(), BitonicSortRecursive(), BogoSort(),
        BoseNelsonSortIterative(), BottomUpMergeSort(), BozoSort(), BubbleSort(), BurntPancakeSort(),
        CircleSortIterative(), CircleSortRecursive(), CocktailMergeSort(), CocktailShakerSort(),
        CombSort(), CountingSort(), CycleSort(), DoubleInsertionSort(), DoubleSelectionSort(),
        DualPivotQuickSort(), FlashSort(), GnomeSort(), GravitySort(), HybridCombSort(),
        InPlaceMergeSort(), InsertionSort(), IntroSort(), LLQuickSort(), LSDRadixSort(),
        MaxHeapSort(), MergeExchangeSortIterative(), MergeSort(), MinHeapSort(), MSDRadixSort(),
        OddEvenMergeSortIterative(), OddEvenMergeSortRecursive(), OddEvenSort(), PancakeSort(),
        PigeonholeSort(), QuickSort(), RecursiveShellSort(), RotateMergeSort(), SelectionSort(),
        ShellSort(), SimplifiedLibrarySort(), SlowSort(), StableCycleSort(), StableSelectionSort(),
        StaticSort(), StoogeSort(), StrandSort(), SwaplessBubbleSort(), TernaryLLQuickSort(),
        TernaryLRQuickSort(), UnoptimizedBubbleSort(), WeavedMergeSort(),
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
                    "\(algorithm.id.rawValue) failed to sort random attempt \(attempt) of size \(size): \(input) -> \(engine.values)"
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
                "\(algorithm.id.rawValue) failed on heavily-duplicated input of size \(size): \(input) -> \(engine.values)"
            )
        }
    }
}
