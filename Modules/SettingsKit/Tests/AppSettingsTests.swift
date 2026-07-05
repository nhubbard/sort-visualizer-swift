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
    }

    @Test
    func mutationsPersistAcrossInstancesSharingTheSameStore() {
        let store = makeIsolatedStore()
        let first = AppSettings(store: store)
        first.selectedVisualizerID = VisualizerID(rawValue: "rainbow")
        first.playbackSpeed = 75.0

        let second = AppSettings(store: store)
        #expect(second.selectedVisualizerID == VisualizerID(rawValue: "rainbow"))
        #expect(second.playbackSpeed == 75.0)
    }
}
