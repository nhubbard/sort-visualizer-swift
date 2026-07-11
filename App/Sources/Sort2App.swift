import AlgorithmKit
import BuiltInAlgorithms
import BuiltInVisualizers
import Foundation
import ScriptingKit
import SettingsKit
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
            DisparityDotsVisualizer()
        ]
        VisualizerRegistry.shared.discover()

        // Native Swift is the target for every algorithm now — JavaScriptCore only gets an
        // interpreter (no JIT) in an ordinary app, which is slow enough in practice that JS is
        // reserved for prototyping a brand-new algorithm before it's ported here and its script
        // retired. `App/Resources/Algorithms/` is empty until the next one is being proven out;
        // `scriptLoader` stays wired so dropping a `.js` + manifest there still works without a
        // recompile, exactly as before. Shuffles followed the same path as of the native shuffle
        // port batch — `App/Resources/Shuffles/` is empty for the same reason.
        AlgorithmRegistry.shared.builtIns = [
            BinaryDoubleInsertionSort(), BinaryGnomeSort(), BinaryInsertionSort(), BinaryMergeSort(),
            BingoSort(), BitonicSortIterative(), BitonicSortRecursive(), BogoSort(),
            BoseNelsonSortIterative(), BottomUpMergeSort(), BozoSort(), BubbleSort(), BurntPancakeSort(),
            CircleSortIterative(), CircleSortRecursive(), CocktailMergeSort(), CocktailShakerSort(),
            CombSort(), CountingSort(), CycleSort(), DoubleInsertionSort(), DoubleSelectionSort(),
            DualPivotQuickSort(), FlashSort(), GnomeSort(), GravitySort(), HybridCombSort(),
            InPlaceMergeSort(), InsertionSort(), IntroSort(), LLQuickSort(), LSDRadixSort(),
            MaxHeapSort(), MergeExchangeSortIterative(), MergeSort(), MinHeapSort(), MSDRadixSort(),
            OddEvenMergeSortIterative(), OddEvenMergeSortRecursive(), OddEvenSort(),
            OptimizedBubbleSort(), OptimizedCocktailShakerSort(), OptimizedGnomeSort(), PancakeSort(),
            PigeonholeSort(), QuickSort(), RecursiveShellSort(), RotateMergeSort(), SelectionSort(),
            ShellSort(), SimplifiedLibrarySort(), SlowSort(), StableCycleSort(), StableSelectionSort(),
            StaticSort(), StoogeSort(), StrandSort(), SwaplessBubbleSort(), TernaryLLQuickSort(),
            TernaryLRQuickSort(), UnoptimizedBubbleSort(), WeavedMergeSort()
        ]
        AlgorithmRegistry.shared.scriptLoader = {
            ScriptAlgorithmLoader.loadScripts(from: Bundle.main.url(forResource: "Algorithms", withExtension: nil)!)
        }
        AlgorithmRegistry.shared.discover()

        ShuffleRegistry.shared.builtIns = [
            AscendingShuffle(), DescendingShuffle(), RandomShuffle(), ShuffledCubicShuffle(), ShuffledQuinticShuffle()
        ]
        ShuffleRegistry.shared.scriptLoader = {
            ScriptShuffleLoader.loadScripts(from: Bundle.main.url(forResource: "Shuffles", withExtension: nil)!)
        }
        ShuffleRegistry.shared.discover()

        // UI-test-only override (never set by a real launch): AppSettings.defaultArraySize's real
        // default (256) is deliberately large, and a quadratic/factorial algorithm at that size can
        // take minutes to visually finish — correct, pedagogically-honest behavior in the running
        // app, but impractical for a UI test's timeout. Tests set this via `launchEnvironment`.
        if let overrideValue = ProcessInfo.processInfo.environment["UI_TEST_ARRAY_SIZE"],
           let overrideSize = Int(overrideValue) {
            AppSettings.shared.defaultArraySize = overrideSize
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(AppSettings.shared)
        }
    }
}
