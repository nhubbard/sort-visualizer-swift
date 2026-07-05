import SettingsKit
import SortEngineKit
import SwiftUI
import VisualizationKit

public struct SortView: View {
    @Bindable var session: SortSession
    @Environment(AppSettings.self) private var settings

    public init(session: SortSession) {
        self.session = session
    }

    public var body: some View {
        VStack(spacing: 12) {
            statusLabel
            content
        }
    }

    @ViewBuilder
    private var content: some View {
        switch session.phase {
        case .idle, .recording, .ready:
            ProgressView()
        case let .replaying(replay), let .complete(replay):
            canvas(for: replay)
                .safeAreaInset(edge: .bottom) {
                    RunControlBar(session: session, replay: replay)
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
