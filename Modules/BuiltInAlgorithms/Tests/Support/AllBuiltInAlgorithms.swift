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
    AATreeSort(), AVLTreeSort(), AmericanFlagSort(), AndreySort(),
    AsynchronousSort(), BadSort(), BaseNMaxHeapSort(), BinaryDoubleInsertionSort(),
    BinaryGnomeSort(),
    BinaryInsertionSort(), BinaryMergeSort(), BinaryQuickSortIterative(),
    BinaryQuickSortRecursive(), BingoSort(), BinomialHeapSort(),
    BinomialSmoothSort(),
    BitonicSortIterative(),
    BitonicSortRecursive(), BlockInsertionSort(), BlockSwapMergeSort(), BogoBogoSort(),
    BogoSort(),
    BoseNelsonSortIterative(), BoseNelsonSortRecursive(),
    BottomUpHeapSort(), BottomUpMergeSort(), BozoSort(), BubbleBogoSort(), BubbleSort(),
    BufferedStoogeSort(),
    BurntPancakeSort(),
    CircleSortIterative(), CircleSortRecursive(), CircloidSort(),
    ClassicGravitySort(), ClassicThreeSmoothCombSort(), ClassicTournamentSort(), ClassicTreeSort(),
    CocktailBogoSort(),
    CocktailMergeSort(), CocktailShakerSort(), CombSort(), CompleteGraphSort(), CountingSort(),
    CreaseSort(),
    CycleSort(),
    DeterministicBogoSort(), DiamondSortIterative(), DiamondSortRecursive(),
    DoubleInsertionSort(), DoubleSelectionSort(),
    DualPivotQuickSort(), ExchangeBogoSort(), FlashSort(), FlippedMinHeapSort(), FoldSort(),
    ForcedStableQuickSort(), FunSort(), GnomeSort(), GrailSort(),
    GravitySort(),
    GuessSort(), HanoiSort(), HybridCombSort(), ImprovedInPlaceMergeSort(), IndexSort(),
    InPlaceLSDRadixSort(), InPlaceMergeSort(),
    InsertionSort(),
    IntroCircleSortIterative(),
    IntroSort(), IterativeTopDownMergeSort(),
    LazyHeapSort(), LazyStableSort(), LessBogoSort(), LibrarySort(), LLQuickSort(),
    LRQuickSort(),
    LSDRadixSort(),
    MatrixSort(), MaxHeapSort(),
    MedianQuickBogoSort(), MergeBogoSort(), MergeExchangeSortIterative(), MergeSort(),
    MinHeapSort(), MinMaxHeapSort(), MSDRadixSort(), NewShuffleMergeSort(),
    OddEvenMergeSortIterative(), OddEvenMergeSortRecursive(), OddEvenSort(),
    OptimizedBubbleSort(), OptimizedCocktailShakerSort(), OptimizedGnomeSort(),
    OptimizedGuessSort(), OptimizedLazyStableSort(), OptimizedStoogeSort(),
    OptimizedStoogeSortStudio(), OutOfPlaceHeapSort(),
    PairwiseMergeSortIterative(), PairwiseMergeSortRecursive(),
    PairwiseSortIterative(), PairwiseSortRecursive(), PancakeSort(), PatienceSort(), PDMergeSort(),
    PDQBranchedSort(),
    PDQBranchlessSort(),
    PigeonholeSort(), PoplarHeapSort(), QuadStoogeSort(),
    QuickBogoSort(), QuickSort(),
    RandomGuessSort(), RecursiveShellSort(), RedBlackTreeSort(), RotateLSDRadixSort(),
    RotateMergeSort(), RotateMSDRadixSort(),
    SelectionBogoSort(),
    SelectionSort(), ShatterSort(), ShellSort(), ShoveSort(), SillySort(),
    SimpleShatterSort(), SimplifiedLibrarySort(), SimplisticGravitySort(), SlopeSort(),
    SlowSort(), SmartBogoBogoSort(),
    SmartGuessSort(), SmoothSort(),
    SnuffleSort(), SplaySort(), StableCycleSort(),
    StablePermutationSort(), StableQuickSort(), StableSelectionSort(),
    StacklessAmericanFlagSort(), StacklessBinaryQuickSort(), StacklessRotateMergeSort(),
    StaticSort(), StoogeSort(),
    StrandSort(),
    SwaplessBubbleSort(),
    TableSort(), TernaryHeapSort(), TernaryLLQuickSort(), TernaryLRQuickSort(),
    ThreeSmoothCombSortIterative(),
    ThreeSmoothCombSortRecursive(), TimeSort(), TournamentSort(), TreeSort(), TriangularHeapSort(),
    TwinSort(),
    UnoptimizedBubbleSort(),
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
