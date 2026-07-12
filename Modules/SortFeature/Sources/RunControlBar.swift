import AlgorithmKit
import SettingsKit
import SortEngineKit
import SwiftUI
import VisualizationKit

/// Docked below the sort visualization via `.safeAreaInset(edge: .bottom)` — reserves real layout
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
    @Environment(AppSettings.self) private var settings

    // Bindings, not local `@State` — owned by `SortView`, which survives the phase churn
    // `session.start(size:)` (the size stepper's own action) drives this view through. See
    // `SortView`'s doc comment on its own copies of these for why.
    @Binding var isSpeedExpanded: Bool
    @Binding var isSizeExpanded: Bool
    @Binding var isVisualizerExpanded: Bool

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
            if isVisualizerExpanded {
                visualizerRow
            }
        }
        .padding(12)
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 20))
        .padding([.horizontal, .bottom])
        .animation(.easeInOut(duration: 0.2), value: isSpeedExpanded)
        .animation(.easeInOut(duration: 0.2), value: isSizeExpanded)
        .animation(.easeInOut(duration: 0.2), value: isVisualizerExpanded)
        // Manual scrubbing/resizing would otherwise collide with the automation loop's own
        // repeated `start(size:)` calls — this bar goes fully inert while it's running.
        .disabled(session.isAutomating)
        .background {
            transportShortcuts
        }
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
            .help("Jump to the very beginning of the recording, before shuffling (⌘⌥←)")
            .disabled(replay.stepIndex <= 0)

            Button {
                replay.pause()
                replay.stepBackward()
            } label: {
                Image(systemName: "backward.frame.fill")
            }
            .accessibilityIdentifier("runControlStepBackButton")
            .accessibilityLabel("Step Back")
            .help("Step back one operation (⌥←)")
            .disabled(replay.stepIndex <= 0)

            Button {
                session.togglePlayback()
            } label: {
                Image(systemName: replay.isPlaying ? "pause.fill" : "play.fill")
                    .font(.title2)
            }
            .accessibilityIdentifier("runControlPlayPauseButton")
            .accessibilityLabel(replay.isPlaying ? "Pause" : "Play")
            .help(replay.isPlaying ? "Pause playback (Space)" : "Resume playback (Space)")
            .disabled(isFinished)

            Button {
                replay.pause()
                replay.stepForward()
            } label: {
                Image(systemName: "forward.frame.fill")
            }
            .accessibilityIdentifier("runControlStepForwardButton")
            .accessibilityLabel("Step Forward")
            .help("Step forward one operation (⌥→)")
            .disabled(isFinished)

            Button {
                replay.seek(to: replay.totalOperationCount)
            } label: {
                Image(systemName: "forward.end.fill")
            }
            .accessibilityIdentifier("runControlJumpToEndButton")
            .accessibilityLabel("Jump to End")
            .help("Jump to the fully sorted end of the recording (⌘⌥→)")
            .disabled(isFinished)

            Spacer()

            Button {
                Task { await session.start(size: session.arraySize) }
            } label: {
                Image(systemName: "arrow.counterclockwise")
            }
            .accessibilityIdentifier("runControlResetButton")
            .accessibilityLabel("Reset and Reshuffle")
            .help("Stop the current sort, shuffle a fresh array at this size, and sort it again (⌘R)")

            Button {
                session.soundEnabled.toggle()
            } label: {
                Image(systemName: session.soundEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
            }
            .accessibilityIdentifier("runControlSoundToggle")
            .accessibilityLabel(session.soundEnabled ? "Mute" : "Unmute")
            .help(session.soundEnabled ? "Turn off sort sound effects (⌘A)" : "Turn on sort sound effects (⌘A)")

            automatorMenu

            Button {
                isSpeedExpanded.toggle()
            } label: {
                Text("\(Int(replay.speed))/s")
                    .font(.footnote.monospacedDigit())
            }
            .accessibilityIdentifier("runControlSpeedButton")
            .accessibilityLabel("Playback Speed")
            .help("Show or hide the playback speed slider (⌘⇧+/− by 1, ⌘⌥+/− by 10)")

            Button {
                isSizeExpanded.toggle()
            } label: {
                Text("n=\(session.arraySize)")
                    .font(.footnote.monospacedDigit())
            }
            .accessibilityIdentifier("runControlSizeButton")
            .accessibilityLabel("Array Size")
            .help("Show or hide the array size stepper (⌘S cycles to the next size)")

            Button {
                isVisualizerExpanded.toggle()
            } label: {
                Image(systemName: "eye.fill")
            }
            .accessibilityIdentifier("runControlVisualizerButton")
            .accessibilityLabel("Visualizer")
            .help("Show or hide the visualizer picker (⌘⇧V cycles to the next visualizer)")
        }
        .buttonStyle(.borderless)
        .controlSize(.large)
    }

    /// Robot icon — lists every registered `Automation` (see `AutomationRegistry`), the same two
    /// entries `⌘⇧A`/`⌘⌥⇧A` already trigger, so the shortcut and the tappable UI are two views onto
    /// one source of truth rather than two independently-maintained ones.
    private var automatorMenu: some View {
        Menu {
            ForEach(AutomationRegistry.shared.automations) { automation in
                Button {
                    session.runAutomation(automation)
                } label: {
                    if session.runningAutomationID == automation.id {
                        Label("\(automation.displayName) (\(automation.shortcutDisplayString)) — Running", systemImage: "checkmark")
                    } else {
                        Label("\(automation.displayName) (\(automation.shortcutDisplayString))", systemImage: automation.iconName)
                    }
                }
                .accessibilityIdentifier("automatorMenuItem.\(automation.id.rawValue)")
            }
        } label: {
            Image(systemName: "gearshape.2.fill")
              .foregroundStyle(Color.accentColor)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("runControlAutomatorButton")
        .accessibilityLabel("Automations")
        .help("Run a size-sweep or max-size automation")
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
            Text("target: \(Int(replay.speed)) ops/sec")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(minWidth: 120, alignment: .trailing)
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

    /// Same disclosure-row shape as `sizeRow` above, but for picking a visualizer instead of a
    /// size — `settings.selectedVisualizerID` is the exact binding `SettingsFeature`'s own
    /// visualizer picker uses, so this is just an iPadOS-reachable surface for the same live field
    /// `⌘⇧V`/`AppSettings.cycleVisualizer()` already changes, not a second mechanism.
    private var visualizerRow: some View {
        @Bindable var settings = settings
        return HStack(spacing: 8) {
            Text("Visualizer")
                .font(.caption)
                .foregroundStyle(.secondary)
            Picker("Visualizer", selection: $settings.selectedVisualizerID) {
                ForEach(VisualizerRegistry.shared.visualizers, id: \.id) { visualizer in
                    Text(visualizer.metadata.displayName).tag(visualizer.id)
                }
            }
            .pickerStyle(.menu)
            .labelsHidden()
            .accessibilityIdentifier("runControlVisualizerPicker")
        }
    }

    /// Zero-size, fully transparent invisible buttons — same pattern as `ScrollingSortView`'s own
    /// ⌘⇧A/⌘⌥⇧A/⌘⇧V shortcuts, just scoped here instead, since `replay` (`ReplayEngine`) only
    /// exists at this level, not up at `ScrollingSortView`. Reset/toggle-audio/cycle-size only
    /// need `session`, but live here too rather than splitting shortcuts across two views.
    private var transportShortcuts: some View {
        Group {
            hiddenButton { replay.seek(to: 0) }
                .keyboardShortcut(.leftArrow, modifiers: [.command, .option])
            hiddenButton { replay.pause(); replay.stepBackward() }
                .keyboardShortcut(.leftArrow, modifiers: [.option])
            hiddenButton { session.togglePlayback() }
                .keyboardShortcut(.space, modifiers: [])
            hiddenButton { replay.pause(); replay.stepForward() }
                .keyboardShortcut(.rightArrow, modifiers: [.option])
            hiddenButton { replay.seek(to: replay.totalOperationCount) }
                .keyboardShortcut(.rightArrow, modifiers: [.command, .option])
            hiddenButton { Task { await session.start(size: session.arraySize) } }
                .keyboardShortcut("r", modifiers: [.command])
            hiddenButton { session.soundEnabled.toggle() }
                .keyboardShortcut("a", modifiers: [.command])
            hiddenButton { replay.speed = min(200, replay.speed + 1) }
                .keyboardShortcut("+", modifiers: [.command, .shift])
            hiddenButton { replay.speed = max(1, replay.speed - 1) }
                .keyboardShortcut("-", modifiers: [.command, .shift])
            hiddenButton { replay.speed = min(200, replay.speed + 10) }
                .keyboardShortcut("+", modifiers: [.command, .option])
            hiddenButton { replay.speed = max(1, replay.speed - 10) }
                .keyboardShortcut("-", modifiers: [.command, .option])
            hiddenButton { Task { await session.cycleArraySize() } }
                .keyboardShortcut("s", modifiers: [.command])
        }
    }

    /// Zero-size, fully transparent — the modifiers are applied per-button (not once to a
    /// containing `Group`, whose modifier-distribution semantics across multiple children aren't
    /// guaranteed), matching `ScrollingSortView`'s own shortcut buttons exactly.
    private func hiddenButton(action: @escaping () -> Void) -> some View {
        Button("", action: action)
            .opacity(0)
            .frame(width: 0, height: 0)
            .accessibilityHidden(true)
    }
}
