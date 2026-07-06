import AlgorithmKit
import Charts
import PersistenceKit
import SwiftUI

/// Queries `AnalyticsService`'s CloudKit-synced `RunSummary` rows for one algorithm, grouped by
/// device — the "how does the same algorithm run on different Apple devices" view that was the
/// original reason for keeping CloudKit at all (§9 of ARCHITECTURE_V2.md). Every real sort
/// completion writes a row here (`SortSession` → `AnalyticsService.record`), so this fills in
/// naturally from ordinary use across devices signed into the same iCloud account — nothing here
/// triggers a recording itself, unlike `ComplexityChart`.
struct DeviceComparisonView: View {
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
                    systemImage: "chart.bar.xaxis",
                    description: Text("Complete a \(algorithm.metadata.displayName) sort to record a run here.")
                )
                .frame(minHeight: 120)
            } else {
                Chart(latestPerDevice) { summary in
                    BarMark(
                        x: .value("Device", summary.deviceModel),
                        y: .value("Milliseconds", summary.recordingDuration * 1000)
                    )
                }
                .frame(height: 160)
                .accessibilityIdentifier("deviceComparisonChart")

                ForEach(latestPerDevice) { summary in
                    LabeledContent(summary.deviceModel) {
                        Text("\(summary.arraySize) elements · \(String(format: "%.1f", summary.recordingDuration * 1000)) ms")
                    }
                    .font(.caption)
                }
            }
        }
        .task(id: algorithm.id) {
            await load()
        }
    }

    /// One bar per device — the device's single most recent run, not every historical run, so a
    /// device that's been used many times doesn't visually dominate the chart over one used once.
    private var latestPerDevice: [RunSummarySnapshot] {
        var seen = Set<String>()
        return summaries.filter { seen.insert($0.deviceModel).inserted }
    }

    private func load() async {
        isLoading = true
        summaries = (try? await AnalyticsService.shared.fetchSummaries(algorithmID: algorithm.id)) ?? []
        isLoading = false
    }
}
