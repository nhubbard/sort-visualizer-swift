import AlgorithmKit
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
    let algorithm: any SortAlgorithm

    @State private var isSpeedExpanded = false
    @State private var isSizeExpanded = false

    var body: some View {
        VStack(spacing: 8) {
            scrubSlider
            statsCaption
            transportRow
            if isSpeedExpanded {
                speedRow
            }
            if isSizeExpanded {
                sizeRow
            }
        }
        .padding(12)
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 20))
        .padding([.horizontal, .bottom])
        .animation(.easeInOut(duration: 0.2), value: isSpeedExpanded)
        .animation(.easeInOut(duration: 0.2), value: isSizeExpanded)
        // Manual scrubbing/resizing would otherwise collide with the automation loop's own
        // repeated `start(size:)` calls — this bar goes fully inert while it's running.
        .disabled(session.isAutomating)
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

    /// Fixed-minimum-width digit slots, not one formatted `Text` — a single `Text` reflows (and
    /// nudges every sibling in `transportRow` below it) every time a value's digit count changes,
    /// which at real playback speeds is constantly. Reserving width up front means the row's total
    /// width stays put; a value only grows into its own slot's padding.
    private var statsCaption: some View {
        HStack(spacing: 4) {
            statSlot(replay.compareCount, digits: 6)
            Text("compares")
            dot
            statSlot(replay.swapCount, digits: 6)
            Text("swaps")
            dot
            // Matches ArrayV's own on-screen order (Comparisons, Swaps, Reversals, Writes to Main
            // Array, Writes to Auxiliary Array(s), Items in External Arrays) — always shown, even
            // at zero, same as ArrayV itself never conditionally hides a stat an algorithm doesn't
            // happen to use. Conditionally showing/hiding would also reflow the row exactly when
            // the fixed-width slots above exist to prevent.
            statSlot(replay.reversalCount, digits: 4)
            Text("reversals")
            dot
            statSlot(replay.mainWriteCount, digits: 6)
            Text("writes")
            dot
            statSlot(replay.auxWriteCount, digits: 6)
            Text("aux writes")
            dot
            statSlot(replay.externalArrayItemCount, digits: 5)
            Text("in external arrays")
            dot
            statSlot(String(format: "%.1fs", replay.elapsedPlaybackDuration), digits: 6)
            dot
            statSlot(String(format: "%.0f ops/sec", opsPerSecond), digits: 4)
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("runControlStatsCaption")
    }

    // `stepIndex`, not `compareCount + swapCount` — merge-family algorithms record most of their
    // tape as `.setValue`/`.auxWrite` (writing merged runs back), not `.compare`/`.swap`, so a
    // compare+swap-only numerator badly undercounts real throughput for them while still looking
    // correct for compare/swap-heavy algorithms like quicksort. `stepIndex` is the actual count of
    // tape operations `ReplayEngine` has applied, regardless of type.
    private var opsPerSecond: Double {
        let elapsed = replay.elapsedPlaybackDuration
        return elapsed > 0 ? Double(replay.stepIndex) / elapsed : 0
    }

    private func statSlot(_ value: Int, digits: Int) -> some View {
        Text("\(value)")
            .monospacedDigit()
            .frame(minWidth: CGFloat(digits) * 7.5, alignment: .trailing)
    }

    private func statSlot(_ text: String, digits: Int) -> some View {
        Text(text)
            .monospacedDigit()
            .frame(minWidth: CGFloat(digits) * 7.5, alignment: .trailing)
    }

    private var dot: some View {
        Text("·")
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
                Task { await session.start(size: session.arraySize) }
            } label: {
                Image(systemName: "arrow.counterclockwise")
            }
            .accessibilityIdentifier("runControlResetButton")
            .accessibilityLabel("Reset and Reshuffle")
            .help("Stop the current sort, shuffle a fresh array at this size, and sort it again")

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

            Button {
                isSizeExpanded.toggle()
            } label: {
                Text("n=\(session.arraySize)")
                    .font(.footnote.monospacedDigit())
            }
            .accessibilityIdentifier("runControlSizeButton")
            .accessibilityLabel("Array Size")
            .help("Show or hide the array size stepper")
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

    /// Bound through a custom `Binding`, same idiom as `scrubSlider` above — every tap doesn't
    /// just change a number, it immediately stops the current sort and re-records+replays a fresh
    /// one at the new size (`SortSession.start(size:)` already pauses any in-flight playback).
    private var sizeRow: some View {
        HStack(spacing: 8) {
            Text("Size")
                .font(.caption)
                .foregroundStyle(.secondary)
            Stepper(
                value: Binding(
                    get: { session.arraySize },
                    set: { newValue in Task { await session.start(size: newValue) } }
                ),
                in: algorithm.metadata.sizeRange,
                step: algorithm.metadata.sizeStep
            ) {
                Text("\(session.arraySize) elements")
                    .font(.caption.monospacedDigit())
                    .frame(minWidth: 90, alignment: .trailing)
            }
            .accessibilityIdentifier("runControlSizeStepper")
        }
    }
}
