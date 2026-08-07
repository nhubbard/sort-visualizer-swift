import AlgorithmKit
import SettingsKit
import SortEngineKit
import SwiftUI
import VisualizationKit

/// Docked below the sort visualization via `.safeAreaInset(edge: .bottom)`, reserving real layout
/// space rather than floating over it. Modeled on a media-player transport: scrub bar, stats
/// caption, then transport buttons. Speed/size/visualizer rows expand inline below the transport
/// row on tap instead of using a `.popover`, so no `UIPopoverPresentationController` is involved.
///
/// `transportRow`/`statsCaption` each offer a stacked-two-row `ViewThatFits` fallback — both rows
/// are built from fixed-intrinsic-width buttons/stat cells (no flexible `.frame(maxWidth:
/// .infinity)` content), so `ViewThatFits` can actually detect overflow and fall back.
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
    .glassOrMaterialBackground()
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

  /// Each stat is a `[number][label]` cell (`statCell`) in an `HStack`; spacing alone separates
  /// cells now that there's no `·` separator. Not `LazyHStack` — laziness only helps children a
  /// scrolling ancestor can defer, and this row never scrolls.
  ///
  /// `ViewThatFits` falls back between one full-width row and two half-width rows, both built
  /// from the same `statCell`s, so every cell's accessibility subtree survives either arrangement.
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

  // Matches ArrayV's on-screen order (Comparisons, Swaps, Reversals, Writes to Main Array, Writes
  // to Auxiliary Array(s), Items in External Arrays); always shown, even at zero, to avoid
  // reflowing the fixed-width slots in `statSlot`. Split into two halves so the stacked
  // `ViewThatFits` candidate above can lay them out as two rows of four.
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
    // Number and unit are separate `Text`s, not one formatted string — folding " ops/sec" into
    // the same string let the whole string's width shift whenever the number crossed a digit
    // boundary (e.g. 3->4 digits near 1000 ops/sec), causing visible reflow during fast playback.
    statCell(
      Int(
        opsPerSecond(
          significantOperationCount: replay.significantOperationCount,
          elapsedPlaybackDuration: replay.elapsedPlaybackDuration)),
      digits: 4, label: "ops/sec")
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

    if let exportDocument {
      ShareLink(item: exportDocument, preview: SharePreview(exportDocument.suggestedFileName)) {
        Image(systemName: "square.and.arrow.up")
      }
      .accessibilityIdentifier("runControlExportTapeButton")
      .accessibilityLabel("Export Tape")
      .help("Export this run's recorded tape as a .tape file")
    } else {
      Button {
      } label: {
        Image(systemName: "square.and.arrow.up")
      }
      .accessibilityIdentifier("runControlExportTapeButton")
      .accessibilityLabel("Export Tape")
      .help("This run's tape couldn't be archived")
      .disabled(true)
    }

    Button {
      session.soundEnabled.toggle()
    } label: {
      Image(systemName: session.soundEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
    }
    .accessibilityIdentifier("runControlSoundToggle")
    .accessibilityLabel(session.soundEnabled ? "Mute" : "Unmute")
    .help(
      session.soundEnabled
        ? "Turn off sort sound effects (⌥⌘A)" : "Turn on sort sound effects (⌥⌘A)")

    AutomatorMenuButton(session: session)

    Button {
      isSpeedExpanded.toggle()
    } label: {
      Text(
        replay.useFixedDurationPacing
          ? "\(Int(replay.targetDuration))s" : "\(Int(replay.speed))/s"
      )
      .font(.footnote.monospacedDigit())
    }
    .accessibilityIdentifier("runControlSpeedButton")
    .accessibilityLabel(replay.useFixedDurationPacing ? "Target Duration" : "Playback Speed")
    .help(
      replay.useFixedDurationPacing
        ? "Show or hide the target duration slider"
        : "Show or hide the playback speed slider (⌘⇧+/− by 1, ⌘⌥+/− by 10)")

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

  /// `nil` only if `Tape.archived()` itself throws — realistically only an encoder bug, since
  /// `replay.tape` is always a real, already-recorded-or-imported value by the time this bar is
  /// on screen. Computed fresh each body evaluation rather than cached: archiving a recording
  /// tape (capped at `RecordingEngine`'s operation limit) is cheap enough not to need memoizing,
  /// and re-deriving it avoids a stale copy if `replay.tape` itself ever changed underneath.
  private var exportDocument: TapeArchiveDocument? {
    guard let data = try? replay.tape.archived() else { return nil }
    return TapeArchiveDocument(
      data: data, suggestedFileName: "\(algorithm.id.rawValue)-\(session.arraySize).tape")
  }

  @ViewBuilder
  private var speedRow: some View {
    if replay.useFixedDurationPacing {
      HStack(spacing: 8) {
        Text("1s")
          .font(.caption)
          .foregroundStyle(.secondary)
        Slider(value: $replay.targetDuration, in: 1...120, step: 1)
          .accessibilityIdentifier("runControlDurationSlider")
        Text("120s")
          .font(.caption)
          .foregroundStyle(.secondary)
        Text("target: \(Int(replay.targetDuration))s")
          .font(.caption.monospacedDigit())
          .foregroundStyle(.secondary)
          .frame(minWidth: 120, alignment: .trailing)
          .accessibilityIdentifier("runControlSpeedValueLabel")
      }
    } else {
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
  }

  /// Bound through a custom `Binding`, same idiom as `scrubSlider` above — every tap doesn't
  /// just change a number, it immediately stops the current sort and re-records+replays a fresh
  /// one at the new size (`SortSession.start(size:)` already pauses any in-flight playback).
  private var sizeRow: some View {
    let effectiveSizeRange = algorithm.metadata.effectiveSizeRange(
      operationCap: settings.recordingOperationCap)
    return HStack(spacing: 8) {
      Text("Size")
        .font(.caption)
        .foregroundStyle(.secondary)
      Stepper(
        value: Binding(
          get: { session.arraySize },
          set: { newValue in Task { await session.start(size: newValue) } }
        ),
        in: effectiveSizeRange,
        step: effectiveSizeRange.steppedSizeStep
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

/// Lists every registered `Automation` (see `AutomationRegistry`) — the same entries `⌘⇧A`/`⌘⌥⇧A`
/// trigger, so the shortcut and this menu share one source of truth.
///
/// A genuine `View`, not a computed property on `RunControlBar`: `@Environment(\.isEnabled)` only
/// sees ancestors of where it's read, and `RunControlBar.body`'s `.disabled(session.isAutomating)`
/// applies to the `VStack` it returns — a descendant from `RunControlBar`'s own point of view, not
/// an ancestor. Only a child placed inside that disabled `VStack` can read the state.
///
/// Unlike the row's other buttons, this one opts out of the inherited disabled look via
/// `.buttonStyle(.plain)` (overriding the row's `.borderless`) plus a hardcoded accent tint, so it
/// must re-derive the dimmed appearance itself via `isEnabled` below.
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
            Label(
              "\(automation.displayName) (\(automation.shortcutDisplayString)) — Running",
              systemImage: "checkmark")
          } else {
            Label(
              "\(automation.displayName) (\(automation.shortcutDisplayString))",
              systemImage: automation.iconName)
          }
        }
        .accessibilityIdentifier("automatorMenuItem.\(automation.id.rawValue)")
      }
    } label: {
      Image(systemName: "gearshape.2.fill")
        // `isEnabled`, not `session.isAutomating` directly, so this tracks whatever actually
        // disabled the control. Explicit color pinned in both states because a bare
        // `Image(systemName:)` otherwise gets stuck at whatever color it last rendered during
        // a tap/menu interaction.
        .foregroundStyle(isEnabled ? Color.accentColor : Color.secondary)
    }
    .buttonStyle(.plain)
    .accessibilityIdentifier("runControlAutomatorButton")
    .accessibilityLabel("Automations")
    .help("Run a size-sweep or max-size automation")
  }
}

// `significantOperationCount`, not `stepIndex` (over-counts mark/unmark bookkeeping around every
// compare/swap, see `SortOperation.isSignificantForPacing`) and not `compareCount + swapCount`
// (under-counts merge-family algorithms, which write most of their tape via
// `.setValue`/`.auxWrite`). This is exactly what `ReplayEngine.play()`'s pacing loop paces
// against, so the stat can never exceed the configured `speed`.
func opsPerSecond(significantOperationCount: Int, elapsedPlaybackDuration: Double) -> Double {
  elapsedPlaybackDuration > 0
    ? Double(significantOperationCount) / elapsedPlaybackDuration : 0
}

extension View {
  /// The deployment target is iOS 18 (`Module.deploymentTargets`), below Liquid Glass's iOS 26
  /// minimum, even though the app builds against the iOS 26 SDK — `.regularMaterial` is the
  /// pre-Liquid-Glass frosted-background equivalent for everything older than that.
  @ViewBuilder
  fileprivate func glassOrMaterialBackground() -> some View {
    if #available(iOS 26.0, *) {
      glassEffect(.regular.interactive(), in: .rect(cornerRadius: 20))
    } else {
      background(.regularMaterial, in: .rect(cornerRadius: 20))
    }
  }
}
