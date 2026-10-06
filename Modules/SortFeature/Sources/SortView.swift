import AlgorithmKit
import PersistenceKit
import SettingsKit
import SortEngineKit
import SwiftUI
import TipKit
import VisualizationKit

public struct SortView: View {
  @Bindable var session: SortSession
  @Environment(AppSettings.self) private var settings
  @Environment(\.dynamicTypeSize) private var dynamicTypeSize
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  private var reduceMotionActive: Bool {
    #if DEBUG
    reduceMotion || ProcessInfo.processInfo.environment["UI_TEST_REDUCE_MOTION"] == "1"
    #else
    reduceMotion
    #endif
  }

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
  @State private var isShowingHelp = false
  #if DEBUG
  @State private var capAuditProbe = "loading"
  @State private var automationAuditProbe = "loading"
  #endif
  #if DEBUG && targetEnvironment(macCatalyst) && LOCAL_INSTRUMENTS_TRACING
  @State private var traceHistory = DebugTraceHistory.shared
  @State private var isTraceHistoryPresented = false
  #endif

  public init(session: SortSession) {
    self.session = session
  }

  public var body: some View {
    VStack(spacing: 12) {
      if !session.isAutomating {
        Group {
          if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 4) {
              HStack {
                statusLabel
                Spacer(minLength: 8)
                helpButton
              }
              detailsScrollCue
            }
          } else {
            ViewThatFits(in: .horizontal) {
              HStack(alignment: .firstTextBaseline) {
                statusLabel
                Spacer(minLength: 8)
                detailsScrollCue
                helpButton
              }
              VStack(alignment: .leading, spacing: 4) {
                HStack {
                  statusLabel
                  Spacer(minLength: 8)
                  helpButton
                }
                detailsScrollCue
              }
            }
          }
        }
        .padding(.horizontal)
        if reduceMotionActive {
          Text("Reduce Motion is on. Automatic playback is limited to 15 operations per second; manual steps are unchanged. A target-duration run may take longer.")
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.horizontal)
            .accessibilityIdentifier("reducedMotionPlaybackNotice")
        }
        discoveryTip
      }
      #if DEBUG
      if ProcessInfo.processInfo.environment["UI_TEST_INT03_SWEEP"] == "1" {
        Button("Start test size sweep") {
          let automation = Automation(
            id: AutomationID(rawValue: "int03-stop-canary"), displayName: "Stop Canary",
            iconName: "stop", key: "t", modifiers: [], runsPerSize: 1,
            sizes: { _ in [32, 64] })
          session.runAutomation(automation)
        }
        .accessibilityIdentifier("startINT03SweepButton")
      }
      if ProcessInfo.processInfo.environment["UI_TEST_AUTOMATION_AUDIT"] == "1" {
        Text("Automation audit probe")
          .font(.caption2)
          .accessibilityIdentifier("automationAuditProbe")
          .accessibilityValue(automationAuditProbe)
          .task(id: session.analyticsRevision) {
            do {
              let records = try await AnalyticsService.shared.fetchSummaries(
                algorithmID: session.algorithm.id)
              automationAuditProbe = "\(records.count)|"
                + records.prefix(5).map { String($0.arraySize) }.joined(separator: ",")
            } catch {
              automationAuditProbe = "error: \(error)"
            }
          }
      }
      if ProcessInfo.processInfo.environment["UI_TEST_ACTIVE_SETTINGS_AUDIT"] == "1",
        let replay = session.lastReplay {
        Text("Active settings probe")
          .font(.caption2)
          .accessibilityIdentifier("activeSettingsProbe")
          .accessibilityValue(
            "\(session.soundEnabled)|\(session.arraySize)|\(replay.speed)|"
              + "\(replay.useFixedDurationPacing)|\(replay.targetDuration)|"
              + "\(replay.header.shuffleID ?? "")|\(settings.selectedVisualizerID.rawValue)"
          )
      }
      if ProcessInfo.processInfo.environment["UI_TEST_REDUCE_MOTION"] == "1",
        let replay = session.lastReplay {
        Text("Reduce Motion playback probe")
          .font(.caption2)
          .accessibilityIdentifier("reducedMotionPlaybackProbe")
          .accessibilityValue(
            "\(replay.automaticSpeedLimit ?? -1)|\(replay.currentPacingRate)|\(replay.stepIndex)")
      }
      if let cap = ProcessInfo.processInfo.environment["UI_TEST_CAP_LOG_PROBE"].flatMap(Int.init) {
        Text("Cap log probe")
          .font(.caption2)
          .accessibilityIdentifier("capExceededLogProbe")
          .accessibilityValue(capAuditProbe)
          .task(id: "\(session.isAutomating)-\(session.arraySize)-\(session.analyticsRevision)") {
            do {
              let audit = try await AnalyticsService.shared.capExceededAuditForUITesting(
                algorithmID: session.algorithm.id.rawValue, operationCap: cap)
              let completed = try await AnalyticsService.shared.fetchSummaries(
                algorithmID: session.algorithm.id).count
              capAuditProbe = "\(audit.count)|\(audit.latestSize ?? -1)|\(completed)|\(session.analyticsRevision)"
            } catch {
              capAuditProbe = "error: \(error)"
            }
          }
      }
      #endif
      #if DEBUG && targetEnvironment(macCatalyst) && LOCAL_INSTRUMENTS_TRACING
      if ProcessInfo.processInfo.environment["SORT_SYMPHONY_TRACE"] == "1" {
        traceControls
      }
      #endif
      content
    }
    .sheet(isPresented: $isShowingHelp) {
      NavigationStack {
        List {
          Section("Playback") {
            Text("Use Play to watch the recording. Pause and use Step Forward or Step Back to inspect one operation at a time.")
          }
          Section("Presentation") {
            Text("Array Size changes the number of items in a new run. Visualizer changes how the current run is drawn.")
          }
          Section("Visualization Markers") {
            Text("In marker-aware views, coral marks the first active array position and blue marks the second. These positions can be compared or swapped; the colors do not name the operation. Rainbow colors items by value and does not show marker highlights. Pause and step to inspect an operation.")
            Text("With Reduce Motion on, Showcase skips Hanoi Towers because its blocks travel between towers. You can still choose Hanoi Towers from the Visualizer picker.")
          }
          Section("Learn More") {
            Text("Scroll below the visualization for the algorithm explanation, growth charts, and code examples.")
          }
        }
        .navigationTitle("How to Use")
        .toolbar {
          ToolbarItem(placement: .confirmationAction) {
            Button("Done") { isShowingHelp = false }
              .accessibilityIdentifier("sortHelpDoneButton")
          }
        }
      }
    }
  }

  private var detailsScrollCue: some View {
    Text("Scroll for details")
      .font(.caption)
      .foregroundStyle(.secondary)
      .accessibilityIdentifier("sortDetailsScrollCue")
  }

  private var helpButton: some View {
    Button("How to Use") { isShowingHelp = true }
      .font(.caption)
      .accessibilityIdentifier("sortHelpButton")
  }

  @ViewBuilder
  private var discoveryTip: some View {
    if case .replaying = session.phase {
      VStack(spacing: 4) {
        TipView(PlaybackDiscoveryTip())
          .accessibilityIdentifier("sortPlaybackTip")
        TipView(PresentationDiscoveryTip())
          .accessibilityIdentifier("sortPresentationTip")
      }
      .frame(maxWidth: 480)
      .padding(.horizontal)
    }
  }

  #if DEBUG && targetEnvironment(macCatalyst) && LOCAL_INSTRUMENTS_TRACING
  private var traceControls: some View {
    VStack(alignment: .leading, spacing: 4) {
      HStack {
        Text("Instruments traces: \(traceHistory.records.count)")
          .font(.caption.monospacedDigit())
          .accessibilityIdentifier("instrumentsTraceCount")
        Spacer()
        Picker("Profile", selection: $session.debugTraceTemplate) {
          ForEach(DebugTraceTemplate.allCases) { template in
            Text(template.rawValue).tag(template)
          }
        }
        .fixedSize()
        .accessibilityIdentifier("instrumentsProfilePicker")
        Picker("Runs", selection: $session.debugTraceRepetitions) {
          ForEach([1, 10, 50, 100], id: \.self) { count in
            Text("\(count)").tag(count)
          }
        }
        .fixedSize()
        .accessibilityIdentifier("instrumentsTraceRepetitionsPicker")
        if session.debugTraceTemplate.supportsHighFrequency {
          Toggle("High Frequency", isOn: $session.debugTraceHighFrequency)
            .fixedSize()
            .accessibilityIdentifier("instrumentsHighFrequencyToggle")
        }
        Button("Record another trace") {
          Task { await session.start(size: session.arraySize) }
        }
        .disabled(session.isAutomating || traceIsRecording)
        .accessibilityIdentifier("instrumentsRecordAgainButton")
        Button("All traces") { isTraceHistoryPresented = true }
          .disabled(traceHistory.records.isEmpty)
          .accessibilityIdentifier("instrumentsAllTracesButton")
      }
      ForEach(traceHistory.records.prefix(3)) { trace in
        Link(destination: trace.url) {
          Text(
            "\(trace.algorithmName) · \(trace.profileName)"
              + (trace.highFrequency == true ? " · High Frequency" : "")
              + (trace.processID.map { " · PID \($0)" } ?? "")
              + " · \(trace.repetitions) runs"
              + " · \(trace.recordedAt.formatted(date: .omitted, time: .standard))"
          )
            .font(.caption2)
            .lineLimit(1)
        }
        .accessibilityIdentifier("instrumentsTraceLink")
      }
    }
    .padding(.horizontal)
    .sheet(isPresented: $isTraceHistoryPresented) {
      NavigationStack {
        List(traceHistory.records) { trace in
          Link(destination: trace.url) {
            VStack(alignment: .leading, spacing: 2) {
              Text("\(trace.algorithmName) · \(trace.profileName)")
              Text(
                "\(trace.recordedAt.formatted(date: .abbreviated, time: .standard))"
                  + (trace.processID.map { " · PID \($0)" } ?? "")
                  + " · \(trace.repetitions) runs"
              )
              .font(.caption)
              .foregroundStyle(.secondary)
            }
          }
        }
        .navigationTitle("Instruments traces")
        .toolbar {
          ToolbarItem(placement: .confirmationAction) {
            Button("Done") { isTraceHistoryPresented = false }
          }
        }
      }
      .frame(minWidth: 620, minHeight: 400)
    }
  }

  private var traceIsRecording: Bool {
    if case .recording = session.phase { return true }
    return false
  }
  #endif

  /// `.idle`/`.recording`/`.ready` fall back to `session.lastReplay` (the previous run's frozen
  /// final frame) instead of unconditionally showing `ProgressView()`, so the canvas stays
  /// mounted through the gap `start(size:)` passes through on every run after the first —
  /// `ProgressView()` only ever appears before the first replay exists. `RunControlBar` must stay
  /// mounted here too: if it dropped out of this branch, `.safeAreaInset(edge: .bottom)` itself
  /// would toggle on/off every run, and the `MTKView` growing into that space faster than its
  /// on-demand redraw could catch up produced a mis-scaled/letterboxed flash.
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
    AccessibleSortCanvas(
      replay: replay, visualizerID: settings.selectedVisualizerID,
      algorithmName: session.algorithm.metadata.displayName, arraySize: session.arraySize,
      status: statusText)
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

/// Isolates the frequently changing position value from `SortView`'s body. The Metal host and
/// accessibility value can update each replay tick without rebuilding the surrounding controls.
private struct AccessibleSortCanvas: View {
  let replay: ReplayEngine
  let visualizerID: VisualizerID
  let algorithmName: String
  let arraySize: Int
  let status: String

  var body: some View {
    MetalRendererView(replay: replay, visualizerID: visualizerID)
      .id(ObjectIdentifier(replay))
      .accessibilityIdentifier("sortVisualizationCanvas")
      .accessibilityLabel(accessibilityLabel)
      .accessibilityValue(accessibilityValue)
      .accessibilityHint("Pause playback and use the step controls to hear individual operations")
  }

  private var accessibilityLabel: String {
    guard ProcessInfo.processInfo.environment["UI_TEST_TAPE_METADATA_PROBE"] == "1" else {
      return "Sort visualization"
    }
    let header = replay.tape.header
    return "\(header.algorithmID)|\(header.shuffleID ?? "")|\(header.visualSeed)|"
      + "\(header.recordedAt.timeIntervalSince1970)|\(header.compareCount)|\(header.swapCount)|"
      + "\(header.sortStartIndex)|\(replay.tape.operations.count)|"
      + header.initialValues.map(String.init).joined(separator: ",")
  }

  private var accessibilityValue: String {
    if ProcessInfo.processInfo.environment["UI_TEST_EXPOSE_FRAME"] == "1" {
      return "\(replay.stepIndex)|\(replay.totalOperationCount)|\(arraySize)|\(Int(replay.speed))|"
        + replay.frame.map { String($0.value) }.joined(separator: ",")
    }
    let visualizer = VisualizerRegistry.shared.visualizer(id: visualizerID)?
      .metadata.displayName ?? "visualization"
    return "\(algorithmName), \(arraySize) items, \(visualizer). "
      + "Operation \(replay.stepIndex) of \(replay.totalOperationCount). \(status)"
  }
}

struct PlaybackDiscoveryTip: Tip {
  @Parameter static var hasUsedPlayback: Bool = false

  var title: Text { Text("Explore one step at a time") }
  var message: Text? {
    Text("Pause playback, then use Step Forward or Step Back to hear and inspect an operation.")
  }
  var rules: [Rule] {
    #Rule(Self.$hasUsedPlayback) { $0 == false }
  }
  var options: [any Option] { MaxDisplayCount(2) }
}

struct PresentationDiscoveryTip: Tip {
  @Parameter static var hasAdjustedPresentation: Bool = false

  var title: Text { Text("Change the view") }
  var message: Text? {
    Text("Array Size sets the next run's item count. Visualizer changes the drawing of this run.")
  }
  var rules: [Rule] {
    #Rule(PlaybackDiscoveryTip.$hasUsedPlayback) { $0 == true }
    #Rule(Self.$hasAdjustedPresentation) { $0 == false }
  }
  var options: [any Option] {
    MaxDisplayCount(2)
    IgnoresDisplayFrequency(true)
  }
}
