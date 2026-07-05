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
        #expect(settings.soundEnabled == true)
        #expect(settings.synthNoteRange == 36...72)
        #expect(settings.defaultArraySize == 256)
        #expect(settings.codeTheme == CodeThemeID(rawValue: "monokai"))
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

        let second = AppSettings(store: store)
        #expect(second.selectedVisualizerID == VisualizerID(rawValue: "rainbow"))
        #expect(second.playbackSpeed == 75.0)
        #expect(second.soundEnabled == false)
        #expect(second.synthNoteRange == 24...96)
        #expect(second.defaultArraySize == 128)
        #expect(second.codeTheme == CodeThemeID(rawValue: "dracula"))
    }
}
