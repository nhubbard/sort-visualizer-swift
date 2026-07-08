import AlgorithmKit
import Charts
import PersistenceKit
import SwiftUI

/// Same `AnalyticsService`-backed data `BenchmarkFeature`'s `DeviceComparisonView` charts, faceted
/// by the playback speed each run completed at — how the same algorithm's recorded run time
/// compares across devices at whatever speed was in effect when that run finished. Lives in
/// `SortFeature` rather than reusing `DeviceComparisonView` directly: `SortFeature` doesn't depend
/// on `BenchmarkFeature`, and the two charts facet the same rows differently enough (device+speed
/// vs. device-only) that duplicating this ~40-line view is cheaper than adding a cross-module
/// dependency for it.
struct DeviceSpeedPerformanceChart: View {
    let algorithm: any SortAlgorithm

    @State private var summaries: [RunSummarySnapshot] = []
    @State private var isLoading = true

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 120)
            } else if summaries.isEmpty {
                ContentUnavailableView(
                    "No Recorded Runs Yet",
                    systemImage: "chart.xyaxis.line",
                    description: Text("Complete a \(algorithm.metadata.displayName) sort to record a run here.")
                )
                .frame(minHeight: 120)
            } else {
                Chart(latestPerDeviceAndSpeed) { summary in
                    LineMark(
                        x: .value("Speed", summary.speed),
                        y: .value("Milliseconds", summary.recordingDuration * 1000)
                    )
                    .foregroundStyle(by: .value("Device", summary.deviceModel))
                    PointMark(
                        x: .value("Speed", summary.speed),
                        y: .value("Milliseconds", summary.recordingDuration * 1000)
                    )
                    .foregroundStyle(by: .value("Device", summary.deviceModel))
                }
                .chartXAxisLabel("Speed (ops/sec)")
                .chartYAxisLabel("Duration (ms)")
                .frame(height: 160)
                .accessibilityIdentifier("deviceSpeedPerformanceChart")
            }
        }
        .task(id: algorithm.id) {
            await load()
        }
    }

    /// One point per device+speed pair — that pair's most recent run, so repeatedly re-running the
    /// same algorithm at the same speed on the same device doesn't pile up overlapping points.
    private var latestPerDeviceAndSpeed: [RunSummarySnapshot] {
        var seen = Set<String>()
        return summaries.filter { seen.insert("\($0.deviceModel)-\($0.speed)").inserted }
    }

    private func load() async {
        isLoading = true
        summaries = (try? await AnalyticsService.shared.fetchSummaries(algorithmID: algorithm.id)) ?? []
        isLoading = false
    }
}
