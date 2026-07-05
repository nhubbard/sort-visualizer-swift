import SortEngineKit
import SwiftUI

/// Docked below `VisualizationCanvas` via `.safeAreaInset(edge: .bottom)` — reserves real layout
/// space rather than floating on top of the visualization (v1's `TouchBarSlider`/`GroupBox`
/// overlay obscured bars it sat over and didn't reserve any space at all). Modeled on a standard
/// media-player transport: a thin scrub bar, a live stats caption, then a row of transport
/// buttons. Speed lives behind a compact popover rather than an always-visible inline slider, so
/// the always-visible row stays a row of icon-sized buttons instead of competing for width.
struct RunControlBar: View {
    @Bindable var session: SortSession
    @Bindable var replay: ReplayEngine

    @State private var isShowingSpeedPopover = false

    var body: some View {
        VStack(spacing: 8) {
            scrubSlider
            statsCaption
            transportRow
        }
        .padding(12)
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 20))
        .padding([.horizontal, .bottom])
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
                replay.pause()
                replay.stepBackward()
            } label: {
                Image(systemName: "backward.frame.fill")
            }
            .accessibilityIdentifier("runControlStepBackButton")
            .disabled(replay.stepIndex <= 0)

            Button {
                session.togglePlayback()
            } label: {
                Image(systemName: replay.isPlaying ? "pause.fill" : "play.fill")
                    .font(.title2)
            }
            .accessibilityIdentifier("runControlPlayPauseButton")
            .disabled(isFinished)

            Button {
                replay.pause()
                replay.stepForward()
            } label: {
                Image(systemName: "forward.frame.fill")
            }
            .accessibilityIdentifier("runControlStepForwardButton")
            .disabled(isFinished)

            Spacer()

            Button {
                session.soundEnabled.toggle()
            } label: {
                Image(systemName: session.soundEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
            }
            .accessibilityIdentifier("runControlSoundToggle")

            Button {
                isShowingSpeedPopover = true
            } label: {
                Text("\(Int(replay.speed))/s")
                    .font(.footnote.monospacedDigit())
            }
            .accessibilityIdentifier("runControlSpeedButton")
            .popover(isPresented: $isShowingSpeedPopover) {
                speedPopoverContent
            }
        }
        .buttonStyle(.borderless)
        .controlSize(.large)
    }

    private var isFinished: Bool {
        replay.stepIndex >= replay.totalOperationCount
    }

    private var speedPopoverContent: some View {
        VStack(spacing: 8) {
            Text("Playback Speed")
                .font(.headline)
            Slider(value: $replay.speed, in: 1...200, step: 1) {
                Text("Speed")
            } minimumValueLabel: {
                Text("Slow")
            } maximumValueLabel: {
                Text("Fast")
            }
            .accessibilityIdentifier("runControlSpeedSlider")
            .frame(minWidth: 240)
            Text("\(Int(replay.speed)) operations/second")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}
