import SettingsKit
import SortEngineKit
import SwiftUI
import VisualizationKit

public struct SortView: View {
    @Bindable var session: SortSession
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

    public init(session: SortSession) {
        self.session = session
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

    /// Shown instead of the normal status label while the `⌘⇧A` loop is driving this session —
    /// same "machine-readable via accessibilityIdentifier" shape as `statusLabel`, plus a way to
    /// stop the loop without needing to remember the keyboard shortcut that started it.
    private var automationBanner: some View {
        HStack(spacing: 8) {
            ProgressView()
                .controlSize(.small)
            Text(automationProgressText)
                .font(.caption)
                .accessibilityIdentifier("automationProgressLabel")
            Button("Stop") { session.toggleAutomation() }
                .font(.caption)
                .accessibilityIdentifier("automationStopButton")
        }
    }

    private var automationProgressText: String {
        guard let progress = session.automationProgress else { return "Automating…" }
        // swiftlint:disable:next line_length
        return "Automating: size \(session.arraySize) (\(progress.sizeIndex + 1)/\(progress.sizeCount)) · run \(progress.runIndex + 1)/\(progress.runCount)"
    }

    @ViewBuilder
    private var content: some View {
        switch session.phase {
        case .idle, .recording, .ready:
            ProgressView()
        case let .replaying(replay), let .complete(replay):
            canvas(for: replay)
                .safeAreaInset(edge: .bottom) {
                    RunControlBar(
                        session: session,
                        replay: replay,
                        algorithm: session.algorithm,
                        isSpeedExpanded: $isSpeedExpanded,
                        isSizeExpanded: $isSizeExpanded
                    )
                }
        case .failed:
            ContentUnavailableView("Sort Failed", systemImage: "exclamationmark.triangle")
        }
    }

    @ViewBuilder
    private func canvas(for replay: ReplayEngine) -> some View {
        if let visualizer = VisualizerRegistry.shared.visualizer(id: settings.selectedVisualizerID) {
            VisualizationCanvas(replay: replay, visualizer: visualizer)
                .accessibilityIdentifier("sortVisualizationCanvas")
        } else {
            ProgressView()
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
        guard case let .complete(replay) = session.phase else { return false }
        let values = replay.frame.map(\.value)
        return values == values.sorted()
    }
}
