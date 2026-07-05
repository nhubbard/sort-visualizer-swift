import BuiltInVisualizers
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
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(AppSettings.shared)
        }
    }
}
