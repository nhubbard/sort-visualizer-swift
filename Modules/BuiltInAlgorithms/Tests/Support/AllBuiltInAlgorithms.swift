import AlgorithmKit

@testable import BuiltInAlgorithms

/// A test-only mirror of `Sort2App.swift`'s `AlgorithmRegistry.shared.builtIns`/
/// `ShuffleRegistry.shared.builtIns` composition lists — `App` isn't something any module can
/// import (it's the top-level executable), and `AlgorithmRegistry`/`ShuffleRegistry` are empty
/// until something populates them, so a test that wants "every algorithm/shuffle this app ships"
/// (the growth-model calibration benchmark, in particular) needs its own copy of the same list
/// rather than relying on the live app's composition root. Keep in sync with `Sort2App.swift` by
/// hand when an algorithm/shuffle is added or removed — there's no single source of truth this
/// could derive from without either target depending on the other.
enum AllBuiltInAlgorithms {
  static let sorts: [any SortAlgorithm] = [
    AsynchronousSort(), BadSort(), BaseNMaxHeapSort(), BinaryDoubleInsertionSort(),
    BinaryGnomeSort(),
    BinaryInsertionSort(), BinaryMergeSort(), BinaryQuickSortIterative(),
    BinaryQuickSortRecursive(), BingoSort(), BinomialHeapSort(),
    BinomialSmoothSort(),
    BitonicSortIterative(),
    BitonicSortRecursive(), BlockInsertionSort(), BlockSwapMergeSort(), BogoSort(),
    BoseNelsonSortIterative(), BoseNelsonSortRecursive(),
    BottomUpHeapSort(), BottomUpMergeSort(), BozoSort(), BubbleBogoSort(), BubbleSort(),
    BufferedStoogeSort(),
    BurntPancakeSort(),
    CircleSortIterative(), CircleSortRecursive(), CircloidSort(),
    ClassicGravitySort(), ClassicThreeSmoothCombSort(), ClassicTreeSort(), CocktailBogoSort(),
    CocktailMergeSort(), CocktailShakerSort(), CombSort(), CompleteGraphSort(), CountingSort(),
    CreaseSort(),
    CycleSort(),
    DeterministicBogoSort(), DiamondSortIterative(), DiamondSortRecursive(),
    DoubleInsertionSort(), DoubleSelectionSort(),
    DualPivotQuickSort(), ExchangeBogoSort(), FlashSort(), FlippedMinHeapSort(), FoldSort(),
    ForcedStableQuickSort(), FunSort(), GnomeSort(), GrailSort(),
    GravitySort(),
    GuessSort(), HybridCombSort(), ImprovedInPlaceMergeSort(), IndexSort(),
    InPlaceLSDRadixSort(), InPlaceMergeSort(),
    InsertionSort(),
    IntroCircleSortIterative(),
    IntroSort(), LazyHeapSort(), LazyStableSort(), LessBogoSort(), LLQuickSort(), LRQuickSort(),
    LSDRadixSort(),
    MaxHeapSort(),
    MedianQuickBogoSort(), MergeBogoSort(), MergeExchangeSortIterative(), MergeSort(),
    MinHeapSort(), MSDRadixSort(),
    OddEvenMergeSortIterative(), OddEvenMergeSortRecursive(), OddEvenSort(),
    OptimizedBubbleSort(), OptimizedCocktailShakerSort(), OptimizedGnomeSort(),
    OptimizedGuessSort(), OptimizedLazyStableSort(), OptimizedStoogeSort(),
    OptimizedStoogeSortStudio(),
    PairwiseMergeSortIterative(), PairwiseMergeSortRecursive(),
    PairwiseSortIterative(), PairwiseSortRecursive(), PancakeSort(), PDQBranchedSort(),
    PDQBranchlessSort(),
    PigeonholeSort(), QuadStoogeSort(),
    QuickBogoSort(), QuickSort(),
    RandomGuessSort(), RecursiveShellSort(), RotateMergeSort(), SelectionBogoSort(),
    SelectionSort(), ShatterSort(), ShellSort(), ShoveSort(), SillySort(),
    SimpleShatterSort(), SimplifiedLibrarySort(), SimplisticGravitySort(), SlopeSort(),
    SlowSort(), SmartBogoBogoSort(),
    SmartGuessSort(),
    SnuffleSort(), StableCycleSort(),
    StablePermutationSort(), StableQuickSort(), StableSelectionSort(), StaticSort(), StoogeSort(),
    StrandSort(),
    SwaplessBubbleSort(),
    TableSort(), TernaryHeapSort(), TernaryLLQuickSort(), TernaryLRQuickSort(),
    ThreeSmoothCombSortIterative(),
    ThreeSmoothCombSortRecursive(), TriangularHeapSort(), TwinSort(), UnoptimizedBubbleSort(),
    UnoptimizedCocktailShakerSort(), UnstableGrailSort(), WeakHeapSort(), WeavedMergeSort(),
    WeaveMergeSort(), WeaveSortIterative(), WeaveSortRecursive(),
  ]

  static let shuffles: [any ShuffleAlgorithm] = [
    AlmostShuffle(), AscendingShuffle(), BlockRandomShuffle(), BSTTraversalShuffle(),
    CircleShuffle(),
    DescendingShuffle(), DoubleLayeredShuffle(), FinalBitonicShuffle(), FinalMergeShuffle(),
    FinalRadixShuffle(), GrayCodeShuffle(), HalfRotationShuffle(), HeapifiedShuffle(),
    InterlacedShuffle(), InvertedBSTShuffle(), LogarithmicSlopesShuffle(), MovedElementShuffle(),
    NaiveShuffle(), NoisyShuffle(), OrganShuffle(), PairwiseShuffle(), PartialReverseShuffle(),
    PartitionedShuffle(), QuicksortAdversaryShuffle(), RandomShuffle(), RealFinalMergeShuffle(),
    RealFinalRadixShuffle(), RecursiveRadixShuffle(), RecursiveReversalShuffle(),
    SawtoothShuffle(),
    ShuffledCubicShuffle(), ShuffledHalfShuffle(), ShuffledHeadShuffle(), ShuffledOddsShuffle(),
    ShuffledQuinticShuffle(), ShuffledTailShuffle(), SierpinskiShuffle(), TriangularShuffle(),
  ]
}
