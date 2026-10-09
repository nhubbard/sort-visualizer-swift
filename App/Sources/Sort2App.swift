import AlgorithmKit
import AudioEngineKit
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
    #if DEBUG
      let environment = ProcessInfo.processInfo.environment
      let preferences = UserDefaults.standard
      if environment["UI_TEST_FRESH_SETTINGS"] == "1",
        let domain = Bundle.main.bundleIdentifier {
        preferences.removePersistentDomain(forName: domain)
      }
      if environment["UI_TEST_CORRUPT_SETTINGS"] == "1" {
        preferences.set("missing-visualizer", forKey: "selectedVisualizerID")
        preferences.set(Double.nan, forKey: "playbackSpeed")
        preferences.set(false, forKey: "useFixedDurationPacing")
        preferences.set(-4.0, forKey: "targetPlaybackDuration")
        preferences.set(false, forKey: "compactPlaybackForFixedDuration")
        preferences.set(false, forKey: "soundEnabled")
        preferences.set(false, forKey: "audioUnitBridgeEnabled")
        preferences.set(96, forKey: "synthLowNote")
        preferences.set(24, forKey: "synthHighNote")
        preferences.set(-1, forKey: "defaultArraySize")
        preferences.set(0, forKey: "recordingOperationCap")
        preferences.set("missing-theme", forKey: "codeTheme")
        preferences.set("missing-shuffle", forKey: "defaultShuffleID")
      }
    #endif
    // Composition root (§4.1): AppSettings.shared and registries are wired once, here, rather
    // than re-declared per view. Full data-driven navigation off AlgorithmRegistry is Phase 9
    // — this phase's debug entry point just looks algorithms/shuffles up by id.
    VisualizerRegistry.shared.builtIns = [
      BarGraphVisualizer(), RainbowVisualizer(), ScatterPlotVisualizer(), SineWaveVisualizer(), ColorCircleVisualizer(),
      SpiralVisualizer(), SpiralDotsVisualizer(), WaveDotsVisualizer(), PixelMeshVisualizer(), HoopStackVisualizer(),
      DisparityBarGraphVisualizer(), DisparityCircleVisualizer(), DisparityChordsVisualizer(),
      DisparityDotsVisualizer(), HanoiTowersVisualizer()
    ]
    #if DEBUG
      if let raw = ProcessInfo.processInfo.environment["UI_TEST_AUTOMATION_VISUALIZERS"] {
        let ids = Set(raw.split(separator: ",").map(String.init))
        VisualizerRegistry.shared.builtIns.removeAll { !ids.contains($0.id.rawValue) }
      }
    #endif
    VisualizerRegistry.shared.discover()

    // Native Swift is the target for every algorithm and shuffle now — the JavaScriptCore
    // scripting backend (ScriptingKit) was removed entirely after it turned out to reference a
    // private API (`JSContextGroupSetExecutionTimeLimit`), which blocked App Store submission.
    AlgorithmRegistry.shared.builtIns = [
      AATreeSort(), AdaptiveGrailSort(), AVLTreeSort(), AmericanFlagSort(), AndreySort(), AsynchronousSort(), BadSort(), BaseNMaxHeapSort(),
      BinaryDoubleInsertionSort(), BinaryGnomeSort(), BinaryInsertionSort(), BinaryMergeSort(),
      BinaryQuickSortIterative(), BinaryQuickSortRecursive(), BingoSort(), BinomialHeapSort(), BinomialSmoothSort(),
      BitonicSortIterative(), BitonicSortRecursive(), BlockInsertionSort(), BlockSwapMergeSort(), BogoBogoSort(),
      BogoSort(), BoseNelsonSortIterative(), BoseNelsonSortRecursive(), BottomUpHeapSort(), BottomUpMergeSort(),
      BozoSort(), BubbleBogoSort(), BubbleSort(), BufferedStoogeSort(), BufferPartitionMergeSort(), BurntPancakeSort(), ChaliceSort(), CircleSortIterative(),
      CircleSortRecursive(), CircloidSort(), CircularGrailSort(), ClassicGravitySort(), ClassicThreeSmoothCombSort(),
      ClassicTournamentSort(), ClassicTreeSort(), CocktailBogoSort(), CocktailMergeSort(), CocktailShakerSort(),
      CombSort(), CompleteGraphSort(), CountingSort(), CreaseSort(), CycleSort(), DeterministicBogoSort(),
      DiamondSortIterative(), DiamondSortRecursive(), DoubleInsertionSort(), DoubleSelectionSort(),
      DropMergeSort(), DualPivotQuickSort(), EctaSort(), ExchangeBogoSort(), FifthMergeSort(), FlashSort(), FlippedMinHeapSort(), FlanSort(), FluxSort(),
      FoldSort(),
      ForcedStableQuickSort(), FunSort(), GnomeSort(), GrailSort(), GravitySort(), GuessSort(), HanoiSort(),
      HybridCombSort(), ImprovedBlockSelectionSort(), ImprovedInPlaceMergeSort(), IndexSort(),
      InPlaceLSDRadixSort(), InPlaceMergeSort(),
      InsertionSort(), IntroCircleSortIterative(), IntroCircleSortRecursive(), IntroSort(), IterativeTopDownMergeSort(),
      KotaSort(), LaziestSort(), LazierestSort(), LazyHeapSort(), LazyStableSort(), LessBogoSort(), LibrarySort(), LLQuickSort(),
      LRQuickSort(), LSDRadixSort(),
      MatrixSort(), MaxHeapSort(), MedianMergeSort(), MedianQuickBogoSort(), MergeBogoSort(), MergeExchangeSortIterative(),
      MergeInsertionSort(), MergeSort(), MinHeapSort(), MinMaxHeapSort(), MSDRadixSort(), NewShuffleMergeSort(),
      OddEvenMergeSortIterative(), OddEvenMergeSortRecursive(), OddEvenSort(),
      OptimizedBottomUpMergeSort(), OptimizedBubbleSort(),
      OptimizedCocktailShakerSort(), OptimizedDualPivotQuickSort(), OptimizedGnomeSort(), OptimizedGuessSort(),
      OptimizedLazyStableSort(), OptimizedRotateMergeSort(), OptimizedStoogeSort(), OptimizedStoogeSortStudio(),
      OptimizedWeaveMergeSort(), OutOfPlaceHeapSort(),
      PairwiseMergeSortIterative(), PairwiseMergeSortRecursive(), PairwiseSortIterative(), PairwiseSortRecursive(),
      PancakeInsertionSort(), PancakeSort(), PatienceSort(), PDMergeSort(), PDQBranchedSort(), PDQBranchlessSort(),
      PigeonholeSort(), PoplarHeapSort(), QuadSort(), QuadStoogeSort(), QuickBogoSort(), QuickSort(), RandomGuessSort(), RemiSort(),
      RecursiveShellSort(), RedBlackTreeSort(), RotateLSDRadixSort(), RotateMergeSort(), RotateMSDRadixSort(),
      SelectionBogoSort(), SelectionSort(), ShatterSort(), ShellSort(), ShoveSort(), SillySort(), SimpleShatterSort(),
      SimplifiedLibrarySort(), SimplisticGravitySort(), SlopeSort(), SlowSort(), SmartBogoBogoSort(), SmartGuessSort(),
      SmoothSort(), SnuffleSort(), SplaySort(), SqrtSort(), StableCycleSort(), StablePermutationSort(), StableQuickSort(),
      StableSelectionSort(), StacklessAmericanFlagSort(), StacklessBinaryQuickSort(),
      StacklessDualPivotQuickSort(), StacklessHybridQuickSort(), StacklessRotateMergeSort(),
      StaticSort(), StoogeSort(), StrandSort(), SwaplessBubbleSort(), SynchronousSqrtSort(), TableSort(), TernaryHeapSort(),
      TernaryLLQuickSort(), TernaryLRQuickSort(), ThreeSmoothCombSortIterative(), ThreeSmoothCombSortRecursive(),
      TimeSort(), TimSort(), TournamentSort(), TreeSort(), TriangularHeapSort(), TwinSort(), UnoptimizedBubbleSort(),
      UnoptimizedCocktailShakerSort(), UnstableGrailSort(), WeakHeapSort(), WeavedMergeSort(), WeaveMergeSort(),
      WeaveSortIterative(), WeaveSortRecursive(), WikiSort(), YujisBufferedMergeSort2()
    ]
    // Exercise catalog removal through the real sidebar in UI tests. Production launches do
    // not set this variable; filtering happens before discovery and view construction.
    if let removedID = ProcessInfo.processInfo.environment["UI_TEST_REMOVED_ALGORITHM_ID"] {
      AlgorithmRegistry.shared.builtIns.removeAll { $0.id.rawValue == removedID }
    }
    #if DEBUG
      if let raw = ProcessInfo.processInfo.environment["UI_TEST_AUTOMATION_ALGORITHMS"] {
        let ids = Set(raw.split(separator: ",").map(String.init))
        AlgorithmRegistry.shared.builtIns.removeAll { !ids.contains($0.id.rawValue) }
      }
    #endif
    AlgorithmRegistry.shared.discover()

    ShuffleRegistry.shared.builtIns = [
      AlmostShuffle(), AscendingShuffle(), BitReversalShuffle(), BlockRandomShuffle(), BlockReverseShuffle(),
      BSTTraversalShuffle(), CircleShuffle(), DescendingShuffle(), DoubleLayeredShuffle(), FinalBitonicShuffle(),
      FinalMergeShuffle(), FinalRadixShuffle(), GrailsortAdversaryShuffle(), GrayCodeShuffle(), HalfRotationShuffle(),
      HeapifiedShuffle(), InterlacedShuffle(), InvertedBSTShuffle(), LogarithmicSlopesShuffle(), MovedElementShuffle(),
      NoisyShuffle(), OrganShuffle(), PairwiseShuffle(), PartialReverseShuffle(), PartitionedShuffle(),
      PDQAdversaryShuffle(), QuicksortAdversaryShuffle(), RandomShuffle(),
      RealFinalMergeShuffle(), RealFinalRadixShuffle(), RecursiveRadixShuffle(), RecursiveReversalShuffle(),
      SawtoothShuffle(), ShuffleMergeAdversaryShuffle(), ShuffledCubicShuffle(), ShuffledHalfShuffle(),
      ShuffledHeadShuffle(), ShuffledOddsShuffle(), ShuffledQuinticShuffle(), ShuffledTailShuffle(),
      SierpinskiShuffle(), TriangularHeapifiedShuffle(), TriangularShuffle()
    ]
    #if DEBUG
      if let raw = ProcessInfo.processInfo.environment["UI_TEST_AUTOMATION_SHUFFLES"] {
        let ids = Set(raw.split(separator: ",").map(String.init))
        ShuffleRegistry.shared.builtIns.removeAll { !ids.contains($0.id.rawValue) }
      }
    #endif
    ShuffleRegistry.shared.discover()
    if ProcessInfo.processInfo.environment["UI_TEST_DETERMINISTIC_REPLAY"] == "1" {
      AppSettings.shared.defaultShuffleID = ShuffleID(rawValue: "random")
      AppSettings.shared.useFixedDurationPacing = false
    }

    // The two automations formerly hardcoded as `SortSession.toggleAutomation()`/
    // `toggleMaxSizeAutomation()` — the shortcut each one triggers is declared right here,
    // next to what it runs, instead of separately in `ScrollingSortView`'s shortcut buttons.
    let isCapSweepUITest = ProcessInfo.processInfo.environment["UI_TEST_CAP_SWEEP"] == "1"
    let isShortSweepUITest = ProcessInfo.processInfo.environment["UI_TEST_SHORT_SIZE_SWEEP"] == "1"
    AutomationRegistry.shared.builtIns = [
      Automation(
        id: .sizeSweep, displayName: "Size Sweep", iconName: "arrow.up.right",
        key: "a", modifiers: [.command, .shift], runsPerSize: isCapSweepUITest || isShortSweepUITest ? 1 : 3,
        sizes: { metadata in
          if ProcessInfo.processInfo.environment["UI_TEST_SHORT_SIZE_SWEEP"] == "1" {
            return [32, 64]
          }
          if ProcessInfo.processInfo.environment["UI_TEST_CAP_SWEEP"] == "1" {
            return [16, 256, 16]
          }
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
      )
    ]
    AutomationRegistry.shared.discover()

    #if DEBUG
      if ProcessInfo.processInfo.environment["UI_TEST_SET02_PRESET"] == "1" {
        let settings = AppSettings.shared
        settings.selectedVisualizerID = VisualizerID(rawValue: "rainbow")
        settings.playbackSpeed = 195
        settings.useFixedDurationPacing = true
        settings.targetPlaybackDuration = 1
        settings.soundEnabled = true
        settings.defaultArraySize = 32
        settings.defaultShuffleID = ShuffleID(rawValue: "descending")
        settings.codeTheme = CodeThemeID(rawValue: "dracula")
      }
    #endif

    // UI-test-only override (never set by a real launch): AppSettings.defaultArraySize's real
    // default (256) is deliberately large, and a quadratic/factorial algorithm at that size can
    // take minutes to visually finish — correct, pedagogically-honest behavior in the running
    // app, but impractical for a UI test's timeout. Tests set this via `launchEnvironment`.
    if let overrideValue = ProcessInfo.processInfo.environment["UI_TEST_ARRAY_SIZE"],
      let overrideSize = Int(overrideValue) {
      AppSettings.shared.defaultArraySize = overrideSize
    }

    // Same rationale, for `playbackSpeed`: a UI test asserting an exact seeded speed value
    // needs to SET that value exactly, not approximate it via `XCUIElement.adjust(
    // toNormalizedSliderPosition:)`'s coordinate-based drag gesture, which lands at a
    // different actual value nearly every run (a real, observed source of test flakiness —
    // not a hypothetical one). This mutates the same `UserDefaults.standard`-backed setting a
    // real Settings-screen drag would, just precisely and deterministically.
    if let overrideValue = ProcessInfo.processInfo.environment["UI_TEST_PLAYBACK_SPEED"],
      let overrideSpeed = Double(overrideValue) {
      AppSettings.shared.playbackSpeed = overrideSpeed
    }

    // Kicks off AlgorithmDetails.algz's decode as early as possible so it's likely already warm
    // by the time the user reaches an AlgorithmDetailSection.
    prewarmAlgorithmDetails()

    // The AU-hosted remote's transport buttons (Documentation/docs/architecture/audio.md) arrive here as
    // RemoteControlCommands over the companion-mode bridge — set once, at launch, so
    // AudioEngineKit (which can't import SortFeature; that dependency runs the other way) never
    // needs to know SortSession/SortCoordinator exist. Mirrors SortCommands.swift's menu-command
    // dispatch exactly, just triggered from the bridge instead of a keyboard shortcut. A no-op
    // (via `?.`) whenever nothing's actively sorting, same as every other reach-in through
    // `SortCoordinator.shared.activeSortSession`.
    // The detail-only UI audit never starts a sort or offers audio controls. Avoid initializing
    // AVAudioEngine for it: a transiently unavailable Catalyst output device can raise an
    // Objective-C exception during graph construction before a test reaches the detail page.
    if ProcessInfo.processInfo.environment["UI_TEST_DETAIL_AUDIT"] != "1" {
      AudioService.shared.remoteControlHandler = { command in
        Task { @MainActor in
          guard let session = SortCoordinator.shared.activeSortSession else { return }
          switch command {
          case .togglePlayback:
            session.togglePlayback()
          case .restart:
            session.lastReplay?.seek(to: 0)
          case .regenerate:
            Task { await session.start(size: session.arraySize) }
          case .stepForward:
            session.lastReplay?.pause()
            session.lastReplay?.stepForward()
          case .stepBackward:
            session.lastReplay?.pause()
            session.lastReplay?.stepBackward()
          case .toggleSound:
            session.soundEnabled.toggle()
          }
        }
      }
    }
  }

  var body: some Scene {
    WindowGroup {
      #if DEBUG
      if ProcessInfo.processInfo.environment["UI_TEST_DETAIL_AUDIT"] == "1" {
        AlgorithmDetailAuditView()
          .environment(AppSettings.shared)
      } else {
        ContentView()
          .environment(AppSettings.shared)
      }
      #else
      ContentView()
        .environment(AppSettings.shared)
      #endif
    }
    .commands {
      SortCommands()
    }
  }
}
