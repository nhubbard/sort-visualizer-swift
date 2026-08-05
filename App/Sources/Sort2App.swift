import AlgorithmKit
import BuiltInAlgorithms
import BuiltInVisualizers
import Foundation
import SettingsKit
import SortFeature
import SwiftUI
import VisualizationKit

@main
@MainActor
struct Sort2App: App {
  init() {
    // Composition root (§4.1): AppSettings.shared and registries are wired once, here, rather
    // than re-declared per view. Full data-driven navigation off AlgorithmRegistry is Phase 9
    // — this phase's debug entry point just looks algorithms/shuffles up by id.
    VisualizerRegistry.shared.builtIns = [
      BarGraphVisualizer(), RainbowVisualizer(), ScatterPlotVisualizer(),
      SineWaveVisualizer(), ColorCircleVisualizer(), SpiralVisualizer(), SpiralDotsVisualizer(),
      WaveDotsVisualizer(), PixelMeshVisualizer(), HoopStackVisualizer(),
      DisparityBarGraphVisualizer(), DisparityCircleVisualizer(), DisparityChordsVisualizer(),
      DisparityDotsVisualizer(), HanoiTowersVisualizer(),
    ]
    VisualizerRegistry.shared.discover()

    // Native Swift is the target for every algorithm and shuffle now — the JavaScriptCore
    // scripting backend (ScriptingKit) was removed entirely after it turned out to reference a
    // private API (`JSContextGroupSetExecutionTimeLimit`), which blocked App Store submission.
    AlgorithmRegistry.shared.builtIns = [
      AATreeSort(), AVLTreeSort(),
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
      ClassicGravitySort(), ClassicThreeSmoothCombSort(), ClassicTournamentSort(), ClassicTreeSort(),
      CocktailBogoSort(),
      CocktailMergeSort(), CocktailShakerSort(), CombSort(), CompleteGraphSort(), CountingSort(),
      CreaseSort(),
      CycleSort(),
      DeterministicBogoSort(), DiamondSortIterative(), DiamondSortRecursive(),
      DoubleInsertionSort(), DoubleSelectionSort(),
      DualPivotQuickSort(), ExchangeBogoSort(), FlashSort(), FlippedMinHeapSort(), FoldSort(),
      ForcedStableQuickSort(), FunSort(), GnomeSort(),
      GrailSort(), GravitySort(),
      GuessSort(), HanoiSort(), HybridCombSort(), ImprovedInPlaceMergeSort(), IndexSort(),
      InPlaceLSDRadixSort(), InPlaceMergeSort(),
      InsertionSort(),
      IntroCircleSortIterative(),
      IntroSort(), LazyHeapSort(), LazyStableSort(), LessBogoSort(), LibrarySort(), LLQuickSort(),
      LRQuickSort(),
      LSDRadixSort(),
      MatrixSort(), MaxHeapSort(),
      MedianQuickBogoSort(), MergeBogoSort(), MergeExchangeSortIterative(), MergeSort(),
      MinHeapSort(), MinMaxHeapSort(), MSDRadixSort(),
      OddEvenMergeSortIterative(), OddEvenMergeSortRecursive(), OddEvenSort(),
      OptimizedBubbleSort(), OptimizedCocktailShakerSort(), OptimizedGnomeSort(),
      OptimizedGuessSort(), OptimizedLazyStableSort(), OptimizedStoogeSort(),
      OptimizedStoogeSortStudio(), OutOfPlaceHeapSort(),
      PairwiseMergeSortIterative(), PairwiseMergeSortRecursive(),
      PairwiseSortIterative(), PairwiseSortRecursive(), PancakeSort(), PatienceSort(),
      PDQBranchedSort(),
      PDQBranchlessSort(),
      PigeonholeSort(), PoplarHeapSort(), QuadStoogeSort(),
      QuickBogoSort(), QuickSort(),
      RandomGuessSort(), RecursiveShellSort(), RedBlackTreeSort(), RotateMergeSort(),
      SelectionBogoSort(),
      SelectionSort(), ShatterSort(), ShellSort(), ShoveSort(), SillySort(),
      SimpleShatterSort(), SimplifiedLibrarySort(), SimplisticGravitySort(), SlopeSort(),
      SlowSort(), SmartBogoBogoSort(),
      SmartGuessSort(), SmoothSort(),
      SnuffleSort(), SplaySort(), StableCycleSort(),
      StablePermutationSort(), StableQuickSort(), StableSelectionSort(), StaticSort(), StoogeSort(),
      StrandSort(),
      SwaplessBubbleSort(),
      TableSort(), TernaryHeapSort(), TernaryLLQuickSort(), TernaryLRQuickSort(),
      ThreeSmoothCombSortIterative(),
      ThreeSmoothCombSortRecursive(), TournamentSort(), TreeSort(), TriangularHeapSort(),
      TwinSort(),
      UnoptimizedBubbleSort(),
      UnoptimizedCocktailShakerSort(), UnstableGrailSort(), WeakHeapSort(), WeavedMergeSort(),
      WeaveMergeSort(), WeaveSortIterative(), WeaveSortRecursive(),
    ]
    AlgorithmRegistry.shared.discover()

    ShuffleRegistry.shared.builtIns = [
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
    ShuffleRegistry.shared.discover()

    // The two automations formerly hardcoded as `SortSession.toggleAutomation()`/
    // `toggleMaxSizeAutomation()` — the shortcut each one triggers is declared right here,
    // next to what it runs, instead of separately in `ScrollingSortView`'s shortcut buttons.
    AutomationRegistry.shared.builtIns = [
      Automation(
        id: .sizeSweep, displayName: "Size Sweep", iconName: "arrow.up.right",
        key: "a", modifiers: [.command, .shift], runsPerSize: 3,
        sizes: { metadata in
          // `Automation.sizes` is `@Sendable` (no static isolation), but every current caller
          // (`SortSession`, `@MainActor`) only ever invokes it from the main actor.
          let range = MainActor.assumeIsolated {
            metadata.effectiveSizeRange(operationCap: AppSettings.shared.recordingOperationCap)
          }
          return range.steppedValues(by: range.steppedSizeStep)
        }
      ),
      Automation(
        id: .maxSizeOnly, displayName: "Max Size Only", iconName: "arrow.up.to.line",
        key: "a", modifiers: [.command, .option, .shift], runsPerSize: 3,
        sizes: { metadata in
          MainActor.assumeIsolated {
            [metadata.effectiveSizeRange(operationCap: AppSettings.shared.recordingOperationCap).upperBound]
          }
        }
      ),
    ]
    AutomationRegistry.shared.discover()

    // UI-test-only override (never set by a real launch): AppSettings.defaultArraySize's real
    // default (256) is deliberately large, and a quadratic/factorial algorithm at that size can
    // take minutes to visually finish — correct, pedagogically-honest behavior in the running
    // app, but impractical for a UI test's timeout. Tests set this via `launchEnvironment`.
    if let overrideValue = ProcessInfo.processInfo.environment["UI_TEST_ARRAY_SIZE"],
      let overrideSize = Int(overrideValue)
    {
      AppSettings.shared.defaultArraySize = overrideSize
    }

    // Same rationale, for `playbackSpeed`: a UI test asserting an exact seeded speed value
    // needs to SET that value exactly, not approximate it via `XCUIElement.adjust(
    // toNormalizedSliderPosition:)`'s coordinate-based drag gesture, which lands at a
    // different actual value nearly every run (a real, observed source of test flakiness —
    // not a hypothetical one). This mutates the same `UserDefaults.standard`-backed setting a
    // real Settings-screen drag would, just precisely and deterministically.
    if let overrideValue = ProcessInfo.processInfo.environment["UI_TEST_PLAYBACK_SPEED"],
      let overrideSpeed = Double(overrideValue)
    {
      AppSettings.shared.playbackSpeed = overrideSpeed
    }

    // Kicks off AlgorithmDetails.algz's decode as early as possible so it's likely already warm
    // by the time the user reaches an AlgorithmDetailSection.
    prewarmAlgorithmDetails()
  }

  var body: some Scene {
    WindowGroup {
      ContentView()
        .environment(AppSettings.shared)
    }
    .commands {
      SortCommands()
    }
  }
}
