import SettingsKit
import SwiftUI
import VisualizationKit

public struct SettingsView: View {
    @Environment(AppSettings.self) private var settings

    public init() {}

    public var body: some View {
        @Bindable var settings = settings
        Form {
            Section("Visualization") {
                Picker("Visualizer", selection: $settings.selectedVisualizerID) {
                    ForEach(VisualizerRegistry.shared.visualizers, id: \.id) { visualizer in
                        Text(visualizer.metadata.displayName).tag(visualizer.id)
                    }
                }
                .pickerStyle(.inline)
                .accessibilityIdentifier("visualizerPicker")
            }
        }
        .navigationTitle("Settings")
    }
}
