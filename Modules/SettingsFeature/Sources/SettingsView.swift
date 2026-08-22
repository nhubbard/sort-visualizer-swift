import AlgorithmKit
import AudioEngineKit
import SettingsKit
import SwiftUI
import VisualizationKit

public struct SettingsView: View {
  @Environment(AppSettings.self) private var settings
  @State private var isShowingResetConfirmation = false
  private var audioService: AudioService { .shared }

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
        Picker("Pacing Mode", selection: $settings.useFixedDurationPacing) {
          Text("Fixed Rate").tag(false)
          Text("Fixed Duration").tag(true)
        }
        .pickerStyle(.segmented)
        .accessibilityIdentifier("pacingModePicker")

        if settings.useFixedDurationPacing {
          Slider(value: $settings.targetPlaybackDuration, in: 1...120, step: 1) {
            Text("Duration")
          } minimumValueLabel: {
            Text("1s")
          } maximumValueLabel: {
            Text("120s")
          }
          .accessibilityIdentifier("targetPlaybackDurationSlider")
          Text("\(Int(settings.targetPlaybackDuration))s per run")
            .font(.caption)
            .foregroundStyle(.secondary)

          Toggle("Compact for Fast Playback", isOn: $settings.compactPlaybackForFixedDuration)
            .accessibilityIdentifier("compactPlaybackToggle")
        } else {
          Slider(value: $settings.playbackSpeed, in: 1...1000, step: 1) {
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
        }
      } header: {
        Text("Default Playback Speed")
      } footer: {
        // Seeds every new sort screen's starting pacing (SortSession.startReplay) — the
        // run-control bar's own speed/duration control still governs an already-running sort
        // live, matching every other per-run-vs-global split on this screen (visualizer/shuffle
        // choice are global too, but sound and start/stop are per-run).
        Text(
          settings.useFixedDurationPacing
            ? "Every run is paced to finish in about this many seconds, regardless of tape "
              + "size — this replaces the manual ops/sec speed while active. Compaction "
              + "optionally drops cosmetic highlight flicker to help hit the target more "
              + "cleanly; operation-count stats are always exact either way. Applies to sorts "
              + "you open after changing this."
            : "Applies to sorts you open after changing this. "
              + "Adjust an already-running sort from its own speed control."
        )
      }
      Section {
        Toggle("Sound Effects", isOn: $settings.soundEnabled)
          .accessibilityIdentifier("soundEnabledToggle")

        if audioService.bridgeStatus != .unsupportedPlatform {
          Toggle("Audio Unit Bridge", isOn: $settings.audioUnitBridgeEnabled)
            .accessibilityIdentifier("audioUnitBridgeEnabledToggle")
            .onChange(of: settings.audioUnitBridgeEnabled) { _, newValue in
              audioService.setAudioUnitBridgeEnabled(newValue)
            }

          LabeledContent("Status", value: audioService.bridgeStatus.displayText)
            .accessibilityIdentifier("audioUnitBridgeStatusRow")
        }
      } header: {
        Text("Sound")
      } footer: {
        // Front-runs the system's own unavoidably vague "access data from other apps" prompt
        // (Documentation/docs/architecture/audio.md's "Known gotchas") — shown only while the toggle is on, so someone
        // who's never touched this setting doesn't see irrelevant DAW-routing explanation.
        if settings.audioUnitBridgeEnabled {
          Text(
            "Lets a DAW's Audio Unit (e.g. Logic Pro) connect to Sort Symphony and receive its live "
              + "audio instead of playing through your speakers. The first time this connects, macOS "
              + "will show a prompt asking to let \"Sort Symphony\" access data from other apps — "
              + "that's expected and required for the connection to work."
          )
        }
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
      Section {
        Stepper(
          "Max Operations: \(settings.recordingOperationCap)",
          value: $settings.recordingOperationCap,
          in: 50_000...5_000_000,
          step: 50_000
        )
        .accessibilityIdentifier("recordingOperationCapStepper")
        Text(
          recordingCapEstimateText(
            useFixedDurationPacing: settings.useFixedDurationPacing,
            targetPlaybackDuration: settings.targetPlaybackDuration,
            recordingOperationCap: settings.recordingOperationCap,
            playbackSpeed: settings.playbackSpeed)
        )
          .font(.caption)
          .foregroundStyle(.secondary)
      } header: {
        Text("Recording Limit")
      } footer: {
        // Mirrors AlgorithmMetadata.sizeRange's own "clamp, don't confirm" precedent
        // (Documentation/docs/architecture/overview.md) — a sort whose recording crosses this many operations
        // is skipped automatically instead of asking the user each time.
        Text(
          "A sort that would need more operations than this to finish is skipped "
            + "automatically instead of running for an unreasonably long time."
        )
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
        Button("Reset to Defaults", role: .destructive) {
          isShowingResetConfirmation = true
        }
        .accessibilityIdentifier("resetSettingsButton")
      }
    }
    .navigationTitle("Settings")
    .confirmationDialog(
      "Reset all settings to their defaults?", isPresented: $isShowingResetConfirmation,
      titleVisibility: .visible
    ) {
      Button("Reset to Defaults", role: .destructive) {
        settings.resetToDefaults()
      }
      .accessibilityIdentifier("resetSettingsConfirmButton")
    }
  }
}

// The ops/sec-based minutes estimate doesn't apply in fixed-duration mode, where every run is
// already paced to land at `targetPlaybackDuration` regardless of tape size — show that target
// directly instead of a stale rate-based projection.
func recordingCapEstimateText(
  useFixedDurationPacing: Bool, targetPlaybackDuration: Double, recordingOperationCap: Int,
  playbackSpeed: Double
) -> String {
  if useFixedDurationPacing {
    return "≈ \(Int(targetPlaybackDuration))s per run at the fixed-duration target"
  }
  let minutes = Double(recordingOperationCap) / playbackSpeed / 60
  return "≈ " + minutes.formatted(.number.precision(.fractionLength(1)))
    + " min at the current playback speed"
}
