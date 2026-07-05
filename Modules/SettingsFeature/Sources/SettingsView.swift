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
            Section("Sound") {
                Toggle("Sound Effects", isOn: $settings.soundEnabled)
                    .accessibilityIdentifier("soundEnabledToggle")
            }
            Section("Array Size") {
                Stepper(
                    "Default Size: \(settings.defaultArraySize)",
                    value: $settings.defaultArraySize,
                    in: 16...512,
                    step: 16
                )
                .accessibilityIdentifier("defaultArraySizeStepper")
            }
            Section("Code Sample Theme") {
                Picker("Theme", selection: $settings.codeTheme) {
                    ForEach(CodeThemeID.knownIDs, id: \.self) { theme in
                        Text(theme.displayName).tag(theme)
                    }
                }
                .pickerStyle(.inline)
                .accessibilityIdentifier("codeThemePicker")
            }
        }
        .navigationTitle("Settings")
    }
}
