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
/// `.popover` — kept that way even now that portrait/multitasking are supported (nothing forces a
/// change here), not because it's the only option any more: inline expand/collapse just never
/// touches `UIPopoverPresentationController` at all, which is one less orientation-related surface
/// to think about as the app's supported width keeps changing.
///
/// `transportRow`/`statsCaption` each offer a second, stacked-into-two-rows `ViewThatFits`
/// candidate — both rows are built entirely from fixed-intrinsic-width buttons/stat cells (no
/// flexible `.frame(maxWidth: .infinity)` content), so `ViewThatFits` can genuinely detect an
/// overflow and fall back, unlike `AlgorithmDetailSection`'s two-column layout.
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

    /// Each stat is its own tight `[number][label]` cell (`statCell`), sitting in an `HStack` with
    /// generous inter-cell spacing standing in for the `·` separator this used to have — a
    /// fixed-width slot only stabilizes the *digits* within one cell; the separator glyph never did
    /// anything for stability, it was just visual noise between cells that whitespace alone reads
    /// just as clearly. Not `LazyHStack`: laziness only pays off for children a scrolling ancestor
    /// can defer rendering along this same (horizontal) axis — this row never scrolls.
    ///
    /// `ViewThatFits` between that one full-width row and two half-width rows — both built from
    /// the same `statCell`s below, so whichever arrangement fits, every cell (and its
    /// accessibility subtree) is still there for `runControlStatsCaption` to combine.
    private var statsCaption: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 12) { statCells }
            VStack(spacing: 4) {
                HStack(spacing: 12) { firstHalfStatCells }
                HStack(spacing: 12) { secondHalfStatCells }
            }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("runControlStatsCaption")
    }

    // Matches ArrayV's own on-screen order (Comparisons, Swaps, Reversals, Writes to Main Array,
    // Writes to Auxiliary Array(s), Items in External Arrays) — always shown, even at zero, same
    // as ArrayV itself never conditionally hides a stat an algorithm doesn't happen to use.
    // Conditionally showing/hiding would also reflow the row exactly when the fixed-width slots
    // in `statSlot` exist to prevent. Split into two `@ViewBuilder` halves (rather than one flat
    // group) purely so the stacked `ViewThatFits` candidate above can lay them out as two rows of
    // four instead of eight in a row.
    @ViewBuilder
    private var firstHalfStatCells: some View {
        statCell(replay.compareCount, digits: 6, label: "compares")
        statCell(replay.swapCount, digits: 6, label: "swaps")
        statCell(replay.reversalCount, digits: 4, label: "reversals")
        statCell(replay.mainWriteCount, digits: 6, label: "writes")
    }

    @ViewBuilder
    private var secondHalfStatCells: some View {
        statCell(replay.auxWriteCount, digits: 6, label: "aux writes")
        statCell(replay.externalArrayItemCount, digits: 5, label: "in external arrays")
        statSlot(String(format: "%.1fs", replay.elapsedPlaybackDuration), digits: 6)
        // Number and unit are two separate `Text`s within the cell, not one formatted string —
        // `statSlot`'s fixed-width reservation only holds the digits steady; folding " ops/sec"
        // into the same string as the number let the *whole* string's natural width (and thus
        // this row's total width) shift every time the number crossed a digit boundary (3
        // digits -> 4 once throughput approached 1000), which SwiftUI visibly resized/glitched
        // several times a second during fast playback.
        statCell(Int(opsPerSecond), digits: 4, label: "ops/sec")
    }

    @ViewBuilder
    private var statCells: some View {
        firstHalfStatCells
        secondHalfStatCells
    }

    /// One stat's fixed-width number plus its label, kept tight (`spacing: 4`) so the pair reads as
    /// a single unit — the looser `spacing: 12` between cells in `statsCaption` above is what
    /// visually separates one stat from the next now that there's no `·` glyph doing that job.
    private func statCell(_ value: Int, digits: Int, label: String) -> some View {
        HStack(spacing: 4) {
            statSlot(value, digits: digits)
            Text(label)
        }
    }

    // `significantOperationCount`, not `stepIndex` and not `compareCount + swapCount`.
    // `compareCount + swapCount` alone badly undercounts merge-family algorithms, which record
    // most of their tape as `.setValue`/`.auxWrite` (writing merged runs back) — but plain
    // `stepIndex` overcounts *everything*, since it also counts the mark/unmark bookkeeping
    // `RecordingEngine.markPrimarySecondary` emits around every `.compare`/`.swap`, which
    // `ReplayEngine.play()`'s pacing no longer charges against `speed` at all (see
    // `SortOperation.isSignificantForPacing`). `significantOperationCount` is exactly what the
    // pacing loop paces against, so this stat can never appear to exceed the configured `speed`.
    private var opsPerSecond: Double {
        let elapsed = replay.elapsedPlaybackDuration
        return elapsed > 0 ? Double(replay.significantOperationCount) / elapsed : 0
    }

    private func statSlot(_ value: Int, digits: Int) -> some View {
        Text("\(value)")
            .monospacedDigit()
            .contentTransition(.numericText(value: Double(value)))
            .animation(.snappy(duration: 0.15), value: value)
            .frame(minWidth: CGFloat(digits) * 7.5, alignment: .trailing)
    }

    private func statSlot(_ text: String, digits: Int) -> some View {
        Text(text)
            .monospacedDigit()
            .contentTransition(.numericText())
            .animation(.snappy(duration: 0.15), value: text)
            .frame(minWidth: CGFloat(digits) * 7.5, alignment: .trailing)
    }

    /// `ViewThatFits` between one full-width row and two rows (playback transport, then
    /// utilities) — both built from the same buttons below, so whichever arrangement fits, every
    /// button (and its accessibility identifier) is still there for UI tests to find.
    private var transportRow: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 20) {
                playbackTransportButtons
                Spacer()
                utilityButtons
            }
            VStack(spacing: 8) {
                HStack(spacing: 20) { playbackTransportButtons }
                HStack(spacing: 20) { utilityButtons }
            }
        }
        .buttonStyle(.borderless)
        .controlSize(.large)
    }

    @ViewBuilder
    private var playbackTransportButtons: some View {
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
            SortHaptics.playPauseToggled()
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
    }

    @ViewBuilder
    private var utilityButtons: some View {
        Button {
            Task { await session.start(size: session.arraySize) }
            SortHaptics.reset()
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

        AutomatorMenuButton(session: session)

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


    private var isFinished: Bool {
        replay.stepIndex >= replay.totalOperationCount
    }

    private var speedRow: some View {
        HStack(spacing: 8) {
            Text("Slow")
                .font(.caption)
                .foregroundStyle(.secondary)
            Slider(value: $replay.speed, in: 1...1000, step: 1)
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

}

/// Robot icon — lists every registered `Automation` (see `AutomationRegistry`), the same two
/// entries `⌘⇧A`/`⌘⌥⇧A` already trigger, so the shortcut and the tappable UI are two views onto
/// one source of truth rather than two independently-maintained ones.
///
/// A genuine `View` type, not a computed property on `RunControlBar` (which is what this used to
/// be) — `@Environment(\.isEnabled)` only reflects ancestors of wherever it's actually read, and
/// `RunControlBar.body` applies `.disabled(session.isAutomating)` to the `VStack` it returns,
/// which is a *descendant* of `RunControlBar` itself from the environment's point of view, not an
/// ancestor of anything `RunControlBar`'s own properties can see. A `@Environment` property
/// declared directly on `RunControlBar` would read whatever *its* parent set, never this bar's own
/// `.disabled()` call. Pulling the button out into its own `View`, placed as an actual child inside
/// that disabled `VStack`, gives it a real position in the tree to read that state from.
///
/// Every other button in `transportRow` dims automatically when `session.isAutomating` disables
/// the bar, for free, because they have no explicit color of their own — `.buttonStyle(.borderless)`
/// (set once on the whole row) applies the system's standard enabled/disabled look to plain
/// `Image(systemName:)` content. This button opts out of both halves of that: `.buttonStyle(.plain)`
/// (asked for explicitly, overriding the row's `.borderless`) and a hardcoded accent tint (so it
/// visually reads as "the automation control," not just another transport button) — so it needs to
/// re-derive the dimmed look itself instead of inheriting it.
private struct AutomatorMenuButton: View {
    let session: SortSession
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
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
                // `isEnabled`, not `session.isAutomating` directly — tracks *whatever* disabled
                // this control (today that's only ever automation, but this stays correct even if
                // a future reason joins it) while still pinning an explicit color in both states,
                // which a bare `Image(systemName:)` needs to avoid getting stuck at whatever color
                // it last rendered through a tap/menu-open interaction.
                .foregroundStyle(isEnabled ? Color.accentColor : Color.secondary)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("runControlAutomatorButton")
        .accessibilityLabel("Automations")
        .help("Run a size-sweep or max-size automation")
    }
}
