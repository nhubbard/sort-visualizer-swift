import AlgorithmKit
import Charts
import PersistenceKit
import SwiftUI

/// Queries `AnalyticsService`'s CloudKit-synced `BigORecord` rows for one algorithm and plots the
/// real, observed operation-count growth against the classic Big-O reference family
/// (`BigOCorrelation.bigOChartPoints`) — replaces the old device/speed comparison, which stopped
/// meaning anything once the replay engine was reworked (playback duration no longer reflects
/// device performance). Every real sort completion writes a row here (`SortSession` →
/// `AnalyticsService.record`), so this fills in naturally from ordinary use across every device
/// signed into the same iCloud account — nothing here triggers a recording itself, unlike
/// `ComplexityChart`.
struct BigOCorrelationChart: View {
    let algorithm: any SortAlgorithm

    @State private var points: [BigOChartPoint] = []
    @State private var isLoading = true

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 120)
            } else if points.isEmpty {
                ContentUnavailableView(
                    "Not Enough Recorded Runs Yet",
                    systemImage: "chart.xyaxis.line",
                    description: Text(
                        "Complete a \(algorithm.metadata.displayName) sort at a couple of different array sizes to chart it here."
                    )
                )
                .frame(minHeight: 120)
            } else {
                Chart(points) { point in
                    LineMark(
                        x: .value("Array Size", point.size),
                        y: .value("Normalized Work", point.normalizedValue)
                    )
                    .foregroundStyle(by: .value("Series", point.series))
                    .lineStyle(point.isObserved ? StrokeStyle() : StrokeStyle(dash: [4, 4]))

                    if point.isObserved {
                        PointMark(
                            x: .value("Array Size", point.size),
                            y: .value("Normalized Work", point.normalizedValue)
                        )
                        .foregroundStyle(by: .value("Series", point.series))
                    }
                }
                .chartXAxisLabel("Array Size")
                .chartYAxisLabel("Normalized Work")
                .frame(height: 200)
                .accessibilityIdentifier("bigOCorrelationChart")
            }
        }
        .task(id: algorithm.id) {
            await load()
        }
    }

    private func load() async {
        isLoading = true
        let summaries = (try? await AnalyticsService.shared.fetchSummaries(algorithmID: algorithm.id)) ?? []
        points = bigOChartPoints(for: summaries)
        isLoading = false
    }
}
