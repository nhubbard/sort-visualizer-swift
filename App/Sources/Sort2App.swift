import AlgorithmKit
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
        VisualizerRegistry.shared.builtIns = [BarGraphVisualizer(), RainbowVisualizer(), ScatterPlotVisualizer()]
        VisualizerRegistry.shared.discover()

        // Algorithms and shuffles are both scripted from day one (§2.6/§2A.4) — no native
        // BuiltInAlgorithms/BuiltInShuffles equivalents exist, so builtIns stays empty on each and
        // everything comes from the bundled Algorithms/Shuffles directories.
        AlgorithmRegistry.shared.scriptLoader = {
            ScriptAlgorithmLoader.loadScripts(from: Bundle.main.url(forResource: "Algorithms", withExtension: nil)!)
        }
        AlgorithmRegistry.shared.discover()

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
