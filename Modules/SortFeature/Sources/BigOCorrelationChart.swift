import AlgorithmKit
import Charts
import PersistenceKit
import SwiftUI

/// Same `AnalyticsService`-backed data `BenchmarkFeature`'s `BigOCorrelationChart` charts — the
/// real, observed operation-count growth against the classic Big-O reference family
/// (`BigOCorrelation.bigOChartPoints`). Lives in `SortFeature` too rather than reusing
/// `BenchmarkFeature`'s view directly: `SortFeature` doesn't depend on `BenchmarkFeature`, so
/// duplicating this ~60-line view is cheaper than adding a cross-module dependency for it.
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
