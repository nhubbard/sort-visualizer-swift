import AlgorithmKit
import Charts
import PersistenceKit
import SwiftUI

/// The whole point of this view: recording (`RecordingEngine`, just counting compares/swaps into
/// a tape) and visualizing (`ReplayEngine`, paced against real wall-clock at whatever `speed` the
/// user dialed in) are two completely different costs, and an algorithm can be fast at one while
/// being slow at the other — the "some sorts take an unreasonably long time to visualize despite
/// the underlying recording process being quite short" phenomenon this view exists to show off.
/// `BigOCorrelationChart` already answers "does op count grow the way the declared complexity
/// says it should"; this answers a different question entirely — "how long did a person actually
/// have to sit and watch this," which no op count alone can tell you, since it depends on `speed`
/// and on whatever real per-tick/per-operation overhead `ReplayEngine`/`AudioService` have.
///
/// Sourced from the same `AnalyticsService.fetchSummaries(algorithmID:)` history
/// `BigOCorrelationChart` reads — real completed runs, not a synthetic on-demand benchmark
/// (unlike `BenchmarkFeature`'s `ComplexityChart`, which never touches `ReplayEngine` at all and
/// so has no playback duration to show). `playbackDuration`/`playbackSpeed` are `nil` on any row
/// recorded before those fields existed, or on a run that never reached genuine completion — this
/// view simply excludes such rows from the playback side rather than treating `nil` as zero.
struct PlaybackOverheadChart: View {
    let algorithm: any SortAlgorithm

    private struct DurationPoint: Identifiable {
        let size: Int
        let averageRecordingDurationMs: Double
        let averagePlaybackDuration: Double?
        var id: Int { size }
    }

    @State private var points: [DurationPoint] = []
    @State private var isLoading = true

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 120)
            } else if points.isEmpty {
                ContentUnavailableView(
                    "Not Enough Recorded Runs Yet",
                    systemImage: "clock.arrow.trianglehead.2.counterclockwise.rotate.90",
                    description: Text(
                        "Complete a \(algorithm.metadata.displayName) sort to start collecting "
                            + "recording and visualization timing here."
                    )
                )
                .frame(maxWidth: .infinity, minHeight: 120)
            } else {
                if let callout = overheadCallout {
                    Text(callout)
                        .font(.callout.bold())
                        .accessibilityIdentifier("playbackOverheadCallout")
                }

                let sizes = points.map(\.size)
                Text("Recording Time vs. Array Size").font(.subheadline.bold())
                Chart(points) { point in
                    LineMark(
                        x: .value("Array Size", point.size),
                        y: .value("Milliseconds", point.averageRecordingDurationMs)
                    )
                    PointMark(
                        x: .value("Array Size", point.size),
                        y: .value("Milliseconds", point.averageRecordingDurationMs)
                    )
                }
                .chartXAxis { AxisMarks(values: sizes) }
                .frame(height: 140)

                let playbackPoints = points.filter { $0.averagePlaybackDuration != nil }
                if !playbackPoints.isEmpty {
                    Text("Visualization Time vs. Array Size").font(.subheadline.bold()).padding(.top, 8)
                    Chart(playbackPoints) { point in
                        LineMark(
                            x: .value("Array Size", point.size),
                            y: .value("Seconds", point.averagePlaybackDuration ?? 0)
                        )
                        PointMark(
                            x: .value("Array Size", point.size),
                            y: .value("Seconds", point.averagePlaybackDuration ?? 0)
                        )
                    }
                    .chartXAxis { AxisMarks(values: playbackPoints.map(\.size)) }
                    .frame(height: 140)
                    .accessibilityIdentifier("playbackOverheadChart")
                }
            }
        }
        .task(id: algorithm.id) {
            await load()
        }
    }

    /// "At the largest size we've actually watched finish, recording took (this fast) but
    /// visualizing it took (this long)" — the one-line, shareable version of the whole chart.
    /// Picks the largest size with playback data specifically (not just the largest recorded
    /// size overall), since a size recorded via `RecordingEngine.record` alone — no playback,
    /// no `AnalyticsService` playback fields — has nothing to compare against.
    private var overheadCallout: String? {
        guard let point = points.last(where: { $0.averagePlaybackDuration != nil }),
              let playback = point.averagePlaybackDuration, playback > 0 else { return nil }
        let ratio = playback * 1000 / max(point.averageRecordingDurationMs, 0.001)
        return String(
            format: "At size %d: recording took %.1f ms, but visualizing it took %.1f s — %.0f× longer.",
            point.size, point.averageRecordingDurationMs, playback, ratio
        )
    }

    private func load() async {
        isLoading = true
        let summaries = (try? await AnalyticsService.shared.fetchSummaries(algorithmID: algorithm.id)) ?? []
        points = Self.durationPoints(from: summaries)
        isLoading = false
    }

    /// Groups by `arraySize` and averages each metric independently — `recordingDuration` is
    /// present on every summary, `playbackDuration` only on those that reached genuine completion
    /// while this feature existed, so the two averages can legitimately be over different-sized
    /// subsets of the same size's runs.
    private static func durationPoints(from summaries: [BigORecordSnapshot]) -> [DurationPoint] {
        let bySize = Dictionary(grouping: summaries, by: \.arraySize)
        return bySize.keys.sorted().map { size in
            let runs = bySize[size] ?? []
            let recordingMs = runs.map { $0.recordingDuration * 1000 }
            let playbackSeconds = runs.compactMap(\.playbackDuration)
            return DurationPoint(
                size: size,
                averageRecordingDurationMs: recordingMs.reduce(0, +) / Double(max(recordingMs.count, 1)),
                averagePlaybackDuration: playbackSeconds.isEmpty
                    ? nil : playbackSeconds.reduce(0, +) / Double(playbackSeconds.count)
            )
        }
    }
}
