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
        // than re-declared per view. Full AlgorithmRegistry wiring + data-driven navigation off it
        // is Phase 9 — this phase's debug entry point constructs QuickSort() directly.
        VisualizerRegistry.shared.builtIns = [BarGraphVisualizer(), RainbowVisualizer(), ScatterPlotVisualizer()]
        VisualizerRegistry.shared.discover()

        // Shuffles are scripted from day one (§2.6/§2A.4) — no native BuiltInShuffles equivalent
        // exists yet, so builtIns stays empty and every shuffle comes from the bundled Shuffles/
        // directory.
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
