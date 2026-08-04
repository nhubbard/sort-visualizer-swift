import AlgorithmKit
import Charts
import PersistenceKit
import SwiftUI

/// `AnalyticsService`-backed data charted against that same algorithm's own best/average/worst-case
/// curves (`BigOCorrelation.bigOChartPoints`) — the real, observed operation-count growth over
/// recorded runs.
///
/// Deliberately compact: `.chartXAxis` caps its tick count regardless of how many distinct sizes
/// have been recorded (unlike `BigOCorrelationDetailView`, which shows every one) — this view sits
/// in a 200pt-tall column, and unbounded ticks become unreadable as an algorithm accumulates
/// recorded runs at more sizes. `BigOCorrelationDetailView` is the full-screen escape hatch.
struct BigOCorrelationChart: View {
  let algorithm: any SortAlgorithm

  @State private var points: [BigOChartPoint] = []
  @State private var isLoading = true
  @State private var isShowingDetail = false

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
        Chart {
          bigOChartMarks(for: cappedForRendering(points))
        }
        .chartXScale(domain: observedSizes[0]...observedSizes[observedSizes.count - 1])
        .chartXAxis {
          AxisMarks(values: .automatic(desiredCount: 5))
        }
        .chartXAxisLabel("Array Size")
        .chartYAxisLabel("Normalized Work")
        .frame(maxWidth: .infinity, minHeight: 200)
        .accessibilityIdentifier("bigOCorrelationChart")
        .overlay(alignment: .topTrailing) {
          Button {
            isShowingDetail = true
          } label: {
            Image(systemName: "arrow.up.left.and.arrow.down.right")
              .padding(8)
              .glassOrMaterialBackground()
          }
          .buttonStyle(.plain)
          .offset(x: 8, y: -8)
          .accessibilityLabel("Expand Chart")
        }
        .sheet(isPresented: $isShowingDetail) {
          BigOCorrelationDetailView(algorithm: algorithm, points: points)
        }
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

/// Shared between the compact chart above and `BigOCorrelationDetailView` so both render
/// identical marks — only axis/interactivity/legend differ between the two.
@ChartContentBuilder
func bigOChartMarks(for points: [BigOChartPoint]) -> some ChartContent {
  ForEach(points) { point in
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
}

/// `AnalyticsService.fetchSummaries` never caps or ages out recorded runs, and `bigOChartPoints`
/// emits one `.observedRun` scatter point per run — an algorithm that's been through a few
/// automation sweeps can easily reach 1000+ of them. Swift Charts re-lays-out every mark in a
/// `Chart` on every frame (not just the ones inside the visible domain), so that's the dominant
/// cost for `BigOCorrelationDetailView`'s `.chartScrollableAxes` drag gesture — this caps scatter
/// density per distinct size before rendering. `.observedTrend`/`.reference` are untouched: there's
/// already at most one trend point per size and a fixed 40-sample reference curve.
func cappedForRendering(_ points: [BigOChartPoint], maxScatterPerSize: Int = 15) -> [BigOChartPoint]
{
  var seenPerSize: [Int: Int] = [:]
  return points.filter { point in
    guard point.kind == .observedRun else { return true }
    seenPerSize[point.size, default: 0] += 1
    return seenPerSize[point.size]! <= maxScatterPerSize
  }
}

extension View {
  /// Same Liquid Glass convention as `AlgorithmDetailSection.glassOrMaterialBackground()` — each
  /// site keeps its own `fileprivate` copy rather than sharing one, since a module-wide version
  /// collides with `RunControlBar`'s differently-styled one of the same name.
  @ViewBuilder
  fileprivate func glassOrMaterialBackground() -> some View {
    if #available(iOS 26.0, *) {
      glassEffect(.regular.interactive(), in: .circle)
    } else {
      background(.thinMaterial, in: Circle())
    }
  }
}
