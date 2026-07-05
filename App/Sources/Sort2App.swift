import AlgorithmKit
import BuiltInVisualizers
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
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(AppSettings.shared)
        }
    }
}
