import SortEngineKit
import SwiftUI

/// Docked below `VisualizationCanvas` via `.safeAreaInset(edge: .bottom)` — reserves real layout
/// space rather than floating on top of the visualization (v1's `TouchBarSlider`/`GroupBox`
/// overlay obscured bars it sat over and didn't reserve any space at all). Modeled on a standard
/// media-player transport: a thin scrub bar, a live stats caption, then a row of transport
/// buttons. Speed expands inline below the transport row on tap, rather than living behind a
/// `.popover` — a `.popover`'s `UIPopoverPresentationController` unconditionally wants to support
/// every interface orientation, which has no overlap with this app's deliberately
/// landscape-only `UISupportedInterfaceOrientations` (bar visualizations read better wide),
/// producing "Supported orientations has no common orientation with the application" and
/// unreliable popover behavior. An inline expand/collapse never touches that presentation-
/// controller machinery at all.
struct RunControlBar: View {
    @Bindable var session: SortSession
    @Bindable var replay: ReplayEngine

    @State private var isSpeedExpanded = false

    var body: some View {
        VStack(spacing: 8) {
            scrubSlider
            statsCaption
            transportRow
            if isSpeedExpanded {
                speedRow
            }
        }
        .padding(12)
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 20))
        .padding([.horizontal, .bottom])
        .animation(.easeInOut(duration: 0.2), value: isSpeedExpanded)
    }

    private var scrubSlider: some View {
        Slider(
            value: Binding(
                get: { Double(replay.stepIndex) },
                set: { replay.seek(to: Int($0.rounded())) }
            ),
            in: 0...Double(max(replay.totalOperationCount, 1))
        )
        .accessibilityIdentifier("runControlScrubSlider")
    }

    private var statsCaption: some View {
        Text(statsText)
            .font(.caption)
            .foregroundStyle(.secondary)
            .accessibilityIdentifier("runControlStatsCaption")
    }

    private var statsText: String {
        let elapsed = replay.elapsedPlaybackDuration
        let totalOps = replay.compareCount + replay.swapCount
        let opsPerSecond = elapsed > 0 ? Double(totalOps) / elapsed : 0
        return String(
            format: "%d compares · %d swaps · %.1fs · %.0f ops/sec",
            replay.compareCount, replay.swapCount, elapsed, opsPerSecond
        )
    }

    private var transportRow: some View {
        HStack(spacing: 20) {
            Button {
                replay.seek(to: 0)
            } label: {
                Image(systemName: "backward.end.fill")
            }
            .accessibilityIdentifier("runControlJumpToStartButton")
            .accessibilityLabel("Jump to Start")
            .help("Jump to the very beginning of the recording, before shuffling")
            .disabled(replay.stepIndex <= 0)

            Button {
                replay.pause()
                replay.stepBackward()
            } label: {
                Image(systemName: "backward.frame.fill")
            }
            .accessibilityIdentifier("runControlStepBackButton")
            .accessibilityLabel("Step Back")
            .help("Step back one operation")
            .disabled(replay.stepIndex <= 0)

            Button {
                session.togglePlayback()
            } label: {
                Image(systemName: replay.isPlaying ? "pause.fill" : "play.fill")
                    .font(.title2)
            }
            .accessibilityIdentifier("runControlPlayPauseButton")
            .accessibilityLabel(replay.isPlaying ? "Pause" : "Play")
            .help(replay.isPlaying ? "Pause playback" : "Resume playback")
            .disabled(isFinished)

            Button {
                replay.pause()
                replay.stepForward()
            } label: {
                Image(systemName: "forward.frame.fill")
            }
            .accessibilityIdentifier("runControlStepForwardButton")
            .accessibilityLabel("Step Forward")
            .help("Step forward one operation")
            .disabled(isFinished)

            Button {
                replay.seek(to: replay.totalOperationCount)
            } label: {
                Image(systemName: "forward.end.fill")
            }
            .accessibilityIdentifier("runControlJumpToEndButton")
            .accessibilityLabel("Jump to End")
            .help("Jump to the fully sorted end of the recording")
            .disabled(isFinished)

            Spacer()

            Button {
                replay.seek(to: replay.header.sortStartIndex)
            } label: {
                Image(systemName: "arrow.counterclockwise")
            }
            .accessibilityIdentifier("runControlResetButton")
            .accessibilityLabel("Reset to Shuffled Input")
            .help("Replay the sort from the shuffled input, skipping the shuffle")
            .disabled(replay.stepIndex == replay.header.sortStartIndex)

            Button {
                session.soundEnabled.toggle()
            } label: {
                Image(systemName: session.soundEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
            }
            .accessibilityIdentifier("runControlSoundToggle")
            .accessibilityLabel(session.soundEnabled ? "Mute" : "Unmute")
            .help(session.soundEnabled ? "Turn off sort sound effects" : "Turn on sort sound effects")

            Button {
                isSpeedExpanded.toggle()
            } label: {
                Text("\(Int(replay.speed))/s")
                    .font(.footnote.monospacedDigit())
            }
            .accessibilityIdentifier("runControlSpeedButton")
            .accessibilityLabel("Playback Speed")
            .help("Show or hide the playback speed slider")
        }
        .buttonStyle(.borderless)
        .controlSize(.large)
    }

    private var isFinished: Bool {
        replay.stepIndex >= replay.totalOperationCount
    }

    private var speedRow: some View {
        HStack(spacing: 8) {
            Text("Slow")
                .font(.caption)
                .foregroundStyle(.secondary)
            Slider(value: $replay.speed, in: 1...200, step: 1)
                .accessibilityIdentifier("runControlSpeedSlider")
            Text("Fast")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("\(Int(replay.speed)) ops/sec")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(minWidth: 80, alignment: .trailing)
                .accessibilityIdentifier("runControlSpeedValueLabel")
        }
    }
}
