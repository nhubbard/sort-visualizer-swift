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
        // Raw per-run scatter (`.observedRun`) is dropped entirely here, not just capped — this
        // compact chart has no toggle UI to bring it back (that's what the expand button's detail
        // view is for), so always rendering it was the actual source of the clutter this chart's
        // rainbow stat points now replace. Those stat points are further restricted to power-of-
        // two sizes, unlike the detail view's every-recorded-size view, to stay cheap and legible
        // as an algorithm accumulates recorded runs at more sizes.
        let renderedPoints = powerOfTwoSizesOnly(
          cappedForRendering(points).filter { $0.kind != .observedRun })
        let sizeDomain = Double(observedSizes[0])...Double(observedSizes[observedSizes.count - 1])
        VStack(alignment: .leading, spacing: 4) {
          Chart {
            bigOChartMarks(for: renderedPoints)
          }
          .chartXScale(domain: sizeDomain, type: .log)
          .chartXAxis {
            AxisMarks(values: powerOfTwoAxisValues(in: sizeDomain))
          }
          .chartXAxisLabel("Array Size")
          .chartYAxisLabel("Normalized Work")
          .frame(maxWidth: .infinity, minHeight: 200)
          .accessibilityIdentifier("bigOCorrelationChart")
          RainbowStatLegend()
        }
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
      // Fixed blue, not `by: .value("Series", ...)` like `.reference` below -- this is the one
      // color in `RainbowStatLegend`'s manual caption, not part of the reference curves' own
      // auto-generated best/average/worst-case legend. `.symbol(.circle)` doubles this line's own
      // vertices as the "mean" rainbow point, rather than emitting a separate, redundant mean
      // point mark at the exact same coordinates.
      LineMark(
        x: .value("Array Size", point.size),
        y: .value("Normalized Work", point.normalizedValue)
      )
      .foregroundStyle(.blue)
      .lineStyle(StrokeStyle())
      .symbol(.circle)
    case .reference:
      LineMark(
        x: .value("Array Size", point.size),
        y: .value("Normalized Work", point.normalizedValue)
      )
      .foregroundStyle(by: .value("Series", point.series))
      .lineStyle(StrokeStyle(dash: [4, 4]))
    case .statMin:
      PointMark(
        x: .value("Array Size", point.size),
        y: .value("Normalized Work", point.normalizedValue)
      )
      .foregroundStyle(.green)
    case .statMax:
      PointMark(
        x: .value("Array Size", point.size),
        y: .value("Normalized Work", point.normalizedValue)
      )
      .foregroundStyle(.red)
    case .statMedian:
      PointMark(
        x: .value("Array Size", point.size),
        y: .value("Normalized Work", point.normalizedValue)
      )
      .foregroundStyle(.orange)
    case .statStdDevBand:
      PointMark(
        x: .value("Array Size", point.size),
        y: .value("Normalized Work", point.normalizedValue)
      )
      .symbolSize(30)
      .foregroundStyle(.purple)
    }
  }
}

/// Powers of two spanning `range` (the nearest one at or below the lower bound through the
/// nearest one at or above the upper bound) — every array-size chart in this module (this one,
/// `BigOCorrelationDetailView`, and `GrowthModelComparisonSection`) uses these as its
/// `AxisMarks(values:)`, on top of a `.log`-typed `chartXScale`, so ticks land at a genuine
/// log-base-2 spacing instead of Swift Charts' automatic (linear, arbitrary-round-number) ticks —
/// array sizes commonly span orders of magnitude in one chart, where linear ticks either clump
/// everything near the small end or land on numbers with no relationship to how these algorithms'
/// complexity actually scales.
func powerOfTwoAxisValues(in range: ClosedRange<Double>) -> [Int] {
  guard range.upperBound >= 1 else { return [] }
  let lowerExponent = max(0, Int(log2(max(range.lowerBound, 1)).rounded(.down)))
  let upperExponent = Int(log2(range.upperBound).rounded(.up))
  guard lowerExponent <= upperExponent else { return [] }
  return (lowerExponent...upperExponent).map { 1 << $0 }
}

/// Restricts the rainbow stat points (but not the trend line or reference curves) to sizes that
/// are exact powers of two — the compact chart's own decluttering measure, on top of what
/// `bigOChartPoints` already computes for every recorded size. `BigOCorrelationDetailView` shows
/// every size instead, since it's the deliberate full-detail escape hatch.
func powerOfTwoSizesOnly(_ points: [BigOChartPoint]) -> [BigOChartPoint] {
  points.filter { point in
    switch point.kind {
    case .statMin, .statMax, .statMedian, .statStdDevBand:
      return point.size > 0 && (point.size & (point.size - 1)) == 0
    case .observedRun, .observedTrend, .reference:
      return true
    }
  }
}

/// Manual color key for the rainbow stat points — `bigOChartMarks` gives these fixed colors
/// rather than `foregroundStyle(by:)`, so they don't participate in `Chart`'s own automatic
/// series-based legend the way the reference curves do, and need this instead.
struct RainbowStatLegend: View {
  private static let entries: [(label: String, color: Color)] = [
    ("Max", .red), ("Median", .orange), ("Mean", .blue), ("Min", .green), ("±1σ", .purple)
  ]

  var body: some View {
    HStack(spacing: 12) {
      ForEach(Self.entries, id: \.label) { entry in
        HStack(spacing: 4) {
          Circle().fill(entry.color).frame(width: 8, height: 8)
          Text(entry.label).font(.caption2).foregroundStyle(.secondary)
        }
      }
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
func cappedForRendering(_ points: [BigOChartPoint], maxScatterPerSize: Int = 15) -> [BigOChartPoint] {
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
