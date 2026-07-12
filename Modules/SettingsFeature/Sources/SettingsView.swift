import AlgorithmKit
import SettingsKit
import SwiftUI
import VisualizationKit

public struct SettingsView: View {
    @Environment(AppSettings.self) private var settings

    public init() {}

    public var body: some View {
        @Bindable var settings = settings
        Form {
            Section("Sorting") {
                Picker("Visualizer", selection: $settings.selectedVisualizerID) {
                    ForEach(VisualizerRegistry.shared.visualizers, id: \.id) { visualizer in
                        Text(visualizer.metadata.displayName).tag(visualizer.id)
                    }
                }
                .pickerStyle(.menu)
                .accessibilityIdentifier("visualizerPicker")

                Picker("Shuffle Method", selection: $settings.defaultShuffleID) {
                    ForEach(ShuffleRegistry.shared.shuffles, id: \.id) { shuffle in
                        Text(shuffle.metadata.displayName).tag(shuffle.id)
                    }
                }
                .pickerStyle(.menu)
                .accessibilityIdentifier("shufflePicker")
            }
            Section {
                Slider(value: $settings.playbackSpeed, in: 1...200, step: 1) {
                    Text("Speed")
                } minimumValueLabel: {
                    Text("Slow")
                } maximumValueLabel: {
                    Text("Fast")
                }
                .accessibilityIdentifier("playbackSpeedSlider")
                Text("\(Int(settings.playbackSpeed)) operations/second")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Default Playback Speed")
            } footer: {
                // Seeds every new sort screen's starting speed (SortSession.startReplay) — the
                // run-control bar's own speed slider still governs an already-running sort live,
                // matching every other per-run-vs-global split on this screen (visualizer/shuffle
                // choice are global too, but sound and start/stop are per-run).
                Text(
                    "Applies to sorts you open after changing this. "
                        + "Adjust an already-running sort from its own speed control."
                )
            }
            Section("Sound") {
                Toggle("Sound Effects", isOn: $settings.soundEnabled)
                    .accessibilityIdentifier("soundEnabledToggle")
            }
            Section("Array Size") {
                Stepper(
                    "Default Size: \(settings.defaultArraySize)",
                    value: $settings.defaultArraySize,
                    in: 16...256,
                    step: 16
                )
                .accessibilityIdentifier("defaultArraySizeStepper")
            }
            Section("Code") {
                Picker("Code Sample Theme", selection: $settings.codeTheme) {
                    ForEach(CodeThemeID.knownIDs, id: \.self) { theme in
                        Text(theme.displayName).tag(theme)
                    }
                }
                .pickerStyle(.menu)
                .accessibilityIdentifier("codeThemePicker")
            }
            Section {
                Toggle("Reduce Flashing", isOn: $settings.reduceFlashingEnabled)
                    .accessibilityIdentifier("reduceFlashingToggle")
            } header: {
                Text("Accessibility")
            } footer: {
                Text(
                    "Smooths rapid highlight-color changes on sorts with few, large elements "
                        + "(e.g. Bogo Sort), instead of snapping instantly. Also turns on "
                        + "automatically when Reduce Motion is enabled in Accessibility settings."
                )
            }
        }
        .navigationTitle("Settings")
    }
}
