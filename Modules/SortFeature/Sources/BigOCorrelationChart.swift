import AlgorithmKit
import Charts
import PersistenceKit
import SwiftUI

/// `AnalyticsService`-backed data charted against that same algorithm's own best/average/worst-case
/// curves (`BigOCorrelation.bigOChartPoints`) — the real, observed operation-count growth over
/// recorded runs.
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
            "Complete a \(algorithm.metadata.displayName) sort at a couple of different array sizes "
              + "to chart it here."
          )
        )
        .frame(maxWidth: .infinity, minHeight: 120)
      } else {
        // Every algorithm needs at least 2 distinct recorded sizes to reach this branch
        // (`bigOChartPoints` returns `[]` otherwise), so `observedSizes` is never empty.
        // Derived from `.observedTrend` specifically — exactly one per distinct recorded
        // size, unlike the raw scatter which can have several points at the same size.
        let observedSizes = points.filter { $0.kind == .observedTrend }.map(\.size).sorted()
        Chart(points) { point in
          switch point.kind {
          case .observedRun:
            PointMark(
              x: .value("Array Size", point.size),
              y: .value("Normalized Work", point.normalizedValue)
            )
            .foregroundStyle(by: .value("Series", point.series))
          case .observedTrend:
            LineMark(
              x: .value("Array Size", point.size),
              y: .value("Normalized Work", point.normalizedValue)
            )
            .foregroundStyle(by: .value("Series", point.series))
            .lineStyle(StrokeStyle())
          case .reference:
            LineMark(
              x: .value("Array Size", point.size),
              y: .value("Normalized Work", point.normalizedValue)
            )
            .foregroundStyle(by: .value("Series", point.series))
            .lineStyle(StrokeStyle(dash: [4, 4]))
          }
        }
        .chartXScale(domain: observedSizes[0]...observedSizes[observedSizes.count - 1])
        .chartXAxis {
          AxisMarks(values: observedSizes)
        }
        .chartXAxisLabel("Array Size")
        .chartYAxisLabel("Normalized Work")
        .frame(maxWidth: .infinity, minHeight: 200)
        .accessibilityIdentifier("bigOCorrelationChart")
      }
    }
    .task(id: algorithm.id) {
      await load()
    }
  }

  private func load() async {
    isLoading = true
    let summaries =
      (try? await AnalyticsService.shared.fetchSummaries(algorithmID: algorithm.id)) ?? []
    points = bigOChartPoints(for: summaries, timeComplexity: algorithm.metadata.timeComplexity)
    isLoading = false
  }
}
