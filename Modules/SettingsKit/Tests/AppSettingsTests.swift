import AlgorithmKit
import Foundation
import Testing
import VisualizationKit
@testable import SettingsKit

@MainActor
@Suite
struct AppSettingsTests {
    private func makeIsolatedStore() -> UserDefaults {
        let suiteName = "AppSettingsTests.\(UUID().uuidString)"
        let store = UserDefaults(suiteName: suiteName)!
        store.removePersistentDomain(forName: suiteName)
        return store
    }

    @Test
    func defaultsMatchExpectedValuesOnFirstLaunch() {
        let settings = AppSettings(store: makeIsolatedStore())
        #expect(settings.selectedVisualizerID == VisualizerID(rawValue: "bargraph"))
        #expect(settings.playbackSpeed == 30.0)
        #expect(settings.soundEnabled == false)
        #expect(settings.synthNoteRange == 36...72)
        #expect(settings.defaultArraySize == 256)
        #expect(settings.codeTheme == CodeThemeID(rawValue: "monokai"))
        #expect(settings.defaultShuffleID == ShuffleID(rawValue: "random"))
    }

    @Test
    func mutationsPersistAcrossInstancesSharingTheSameStore() {
        let store = makeIsolatedStore()
        let first = AppSettings(store: store)
        first.selectedVisualizerID = VisualizerID(rawValue: "rainbow")
        first.playbackSpeed = 75.0
        first.soundEnabled = false
        first.synthNoteRange = 24...96
        first.defaultArraySize = 128
        first.codeTheme = CodeThemeID(rawValue: "dracula")
        first.defaultShuffleID = ShuffleID(rawValue: "shuffledcubic")

        let second = AppSettings(store: store)
        #expect(second.selectedVisualizerID == VisualizerID(rawValue: "rainbow"))
        #expect(second.playbackSpeed == 75.0)
        #expect(second.soundEnabled == false)
        #expect(second.synthNoteRange == 24...96)
        #expect(second.defaultArraySize == 128)
        #expect(second.codeTheme == CodeThemeID(rawValue: "dracula"))
        #expect(second.defaultShuffleID == ShuffleID(rawValue: "shuffledcubic"))
    }

    /// Fully synchronous (no `await` between setup and assertions) so this critical section over
    /// the process-wide `VisualizerRegistry.shared` singleton can't interleave with another
    /// `@MainActor`-isolated test's own mutation of it — see `cycleVisualizer()`'s own doc comment
    /// for why it reads that registry directly rather than taking a list as a parameter.
    @Test
    func cycleVisualizerWrapsAroundLikeARingBuffer() {
        let registry = VisualizerRegistry.shared
        let restoreBuiltIns = registry.builtIns
        defer {
            registry.builtIns = restoreBuiltIns
            registry.discover()
        }
        registry.builtIns = ["a", "b", "c"].map(MockVisualizer.init)
        registry.discover()

        let settings = AppSettings(store: makeIsolatedStore())
        settings.selectedVisualizerID = VisualizerID(rawValue: "a")

        settings.cycleVisualizer()
        #expect(settings.selectedVisualizerID == VisualizerID(rawValue: "b"))
        settings.cycleVisualizer()
        #expect(settings.selectedVisualizerID == VisualizerID(rawValue: "c"))
        settings.cycleVisualizer()
        #expect(settings.selectedVisualizerID == VisualizerID(rawValue: "a"), "should wrap back to the first entry")
    }

    @Test
    func cycleVisualizerFallsBackToFirstEntryWhenCurrentIDIsUnknown() {
        let registry = VisualizerRegistry.shared
        let restoreBuiltIns = registry.builtIns
        defer {
            registry.builtIns = restoreBuiltIns
            registry.discover()
        }
        registry.builtIns = ["a", "b"].map(MockVisualizer.init)
        registry.discover()

        let settings = AppSettings(store: makeIsolatedStore())
        settings.selectedVisualizerID = VisualizerID(rawValue: "not-in-the-registry")

        settings.cycleVisualizer()
        #expect(settings.selectedVisualizerID == VisualizerID(rawValue: "a"))
    }
}

private struct MockVisualizer: Visualizer {
    let id: VisualizerID
    let metadata = VisualizerMetadata(displayName: "Mock", supportsAuxArrays: false, iconName: "circle")

    init(_ rawID: String) {
        id = VisualizerID(rawValue: rawID)
    }

    func draw(_ context: VisualizationContext) -> [DrawCommand] { [] }
}
