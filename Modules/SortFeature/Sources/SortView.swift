import SettingsKit
import SortEngineKit
import SwiftUI

public struct SortView: View {
  @Bindable var session: SortSession
  /// Non-`nil` only when this session is one step of Showcase mode — see
  /// `ScrollingSortView.showcaseStop`'s doc comment for why `automationBanner`'s Stop button
  /// needs a different action in that case instead of `session.stopAutomation()`.
  let showcaseStop: (() -> Void)?
  @Environment(AppSettings.self) private var settings

  // Owned here, not by `RunControlBar` itself: `start(size:)` (the size stepper's own action)
  // routes `session.phase` through `.recording`/`.ready` before landing back on `.replaying`,
  // and `content` below renders a bare `ProgressView()` for those in-between phases — tearing
  // down `RunControlBar` and rebuilding a fresh instance once phase settles. `@State` living on
  // that instance would reset every time, collapsing the row the very stepper tap just opened.
  // `SortView` sits outside the phase `switch`, so it keeps its identity (and this state) across
  // the whole churn.
  @State private var isSpeedExpanded = false
  @State private var isSizeExpanded = false
  @State private var isVisualizerExpanded = false

  public init(session: SortSession, showcaseStop: (() -> Void)? = nil) {
    self.session = session
    self.showcaseStop = showcaseStop
  }

  public var body: some View {
    VStack(spacing: 12) {
      if session.isAutomating {
        automationBanner
      } else {
        statusLabel
      }
      content
    }
  }

  /// Shown instead of the normal status label while a registered `Automation` is driving this
  /// session — same "machine-readable via accessibilityIdentifier" shape as `statusLabel`, plus
  /// a way to stop the loop without needing to remember the keyboard shortcut that started it.
  /// `session.isAutomating` is also `true` during a Showcase pass (both go through
  /// `SortSession.runAutomation(sizes:runsPerSize:)`), so this same banner appears either way —
  /// but stopping them means two different things, hence `showcaseStop` taking priority when set.
  private var automationBanner: some View {
    HStack(spacing: 8) {
      ProgressView()
        .controlSize(.small)
      Text(automationProgressText)
        .font(.caption)
        .accessibilityIdentifier("automationProgressLabel")
      Button("Stop") {
        if let showcaseStop {
          showcaseStop()
        } else {
          session.stopAutomation()
        }
      }
      .font(.caption)
      .accessibilityIdentifier("automationStopButton")
    }
  }

  private var automationProgressText: String {
    guard let progress = session.automationProgress else { return "Automating…" }
    // swiftlint:disable:next line_length
    return
      "Automating: size \(session.arraySize) (\(progress.sizeIndex + 1)/\(progress.sizeCount)) · run \(progress.runIndex + 1)/\(progress.runCount)"
  }

  /// `.idle`/`.recording`/`.ready` used to unconditionally show a bare `ProgressView()` here —
  /// correct for the very first run (there's nothing else to show yet), but for every run after
  /// that, `start(size:)` passes through this same gap on every single call, unmounting the
  /// canvas for a spinner and remounting a freshly-built one moments later. Reported as a visible
  /// flash between runs during Size Sweep automation, most noticeable at small array sizes
  /// (where a run finishes fast enough that this fixed-cost gap is a large fraction of what's on
  /// screen). Falling back to `session.lastReplay` — the previous run's now-frozen final frame —
  /// instead keeps the canvas mounted and showing *something real* through the gap; `ProgressView`
  /// only ever appears once, before the first run has produced a replay at all. `RunControlBar` is
  /// kept mounted here too (it already goes `.disabled(session.isAutomating)` on its own) — an
  /// earlier version dropped it in this branch, which meant `.safeAreaInset(edge: .bottom)`
  /// itself came and went every automation iteration; the `MTKView` growing into that space for
  /// the gap's duration, faster than its renderer's on-demand redraw could catch up, produced a
  /// one-frame mis-scaled/letterboxed flash on top of the bar-shaped one this comment used to
  /// describe.
  @ViewBuilder
  private var content: some View {
    switch session.phase {
    case .idle, .recording, .ready:
      if let lastReplay = session.lastReplay {
        canvasWithControls(for: lastReplay)
      } else {
        ProgressView()
      }
    case .replaying(let replay), .complete(let replay):
      canvasWithControls(for: replay)
    case .failed(let error):
      ContentUnavailableView(
        "Sort Skipped", systemImage: "clock.badge.exclamationmark",
        description: Text(error.localizedDescription)
      )
    }
  }

  private func canvasWithControls(for replay: ReplayEngine) -> some View {
    canvas(for: replay)
      .safeAreaInset(edge: .bottom) {
        RunControlBar(
          session: session,
          replay: replay,
          algorithm: session.algorithm,
          isSpeedExpanded: $isSpeedExpanded,
          isSizeExpanded: $isSizeExpanded,
          isVisualizerExpanded: $isVisualizerExpanded
        )
      }
  }

  /// `.id(ObjectIdentifier(replay))` forces SwiftUI to treat each new run as a genuinely new
  /// view — see `MetalRendererView`'s own doc comment for why its `Coordinator` tracking needs
  /// that reset rather than carrying over stale bookkeeping from whatever ran before.
  ///
  /// Metal is the only renderer — every built-in `Visualizer` has a working
  /// `MetalRendererFactory` path as of the wedge/chord batch (`MetalTriangleRenderer`/
  /// `MetalDisparityChordsRenderer`), so there's no fallback branch left to take.
  private func canvas(for replay: ReplayEngine) -> some View {
    MetalRendererView(replay: replay, visualizerID: settings.selectedVisualizerID)
      .id(ObjectIdentifier(replay))
      .accessibilityIdentifier("sortVisualizationCanvas")
  }

  /// Machine-readable phase/correctness signal for UI tests — a `Canvas` has no discrete
  /// accessible bars to inspect, so this is the hook that proves record → replay → draw actually
  /// produced a correctly sorted result, not just "some completion event fired."
  private var statusLabel: some View {
    Text(statusText)
      .font(.caption)
      .accessibilityIdentifier("sortStatusLabel")
      .accessibilityValue(statusAccessibilityValue)
  }

  private var statusText: String {
    switch session.phase {
    case .idle: "Idle"
    case .recording: "Recording…"
    case .ready: "Ready"
    case .replaying: "Sorting…"
    case .complete: isReplayCorrectlySorted ? "Sorted ✓" : "Sort verification failed"
    case .failed: "Failed"
    }
  }

  private var statusAccessibilityValue: String {
    switch session.phase {
    case .idle: "idle"
    case .recording: "recording"
    case .ready: "ready"
    case .replaying: "sorting"
    case .complete: isReplayCorrectlySorted ? "sorted" : "sort-failed"
    case .failed: "failed"
    }
  }

  private var isReplayCorrectlySorted: Bool {
    guard case .complete(let replay) = session.phase else { return false }
    let values = replay.frame.map(\.value)
    return values == values.sorted()
  }
}
