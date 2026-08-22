import AlgorithmKit
import Charts
import PersistenceKit
import SwiftUI

/// Full-screen escape hatch for `BigOCorrelationChart`'s deliberately-compact embedded chart —
/// opened via its "Expand Chart" overlay button. Takes `points` already loaded by the caller
/// rather than re-fetching, so it's guaranteed to show exactly what the compact chart showed.
struct BigOCorrelationDetailView: View {
  let algorithm: any SortAlgorithm
  let points: [BigOChartPoint]

  @Environment(\.dismiss) private var dismiss
  @State private var selectedSize: Int?
  @State private var hiddenSeries: Set<String> = []
  /// Off by default: `.observedTrend` is already the per-size average of the raw `.observedRun`
  /// scatter, so the scatter is redundant data that's also the dominant mark count (one point per
  /// recorded run, uncapped at the source — see `cappedForRendering`'s doc comment). Swift Charts
  /// re-lays-out every mark on every `.chartScrollableAxes` scroll frame regardless of what's
  /// visible, so leaving this off is what actually keeps scrolling smooth; it's an opt-in for
  /// seeing per-run variance/outliers, not the default view.
  @State private var showsIndividualRuns = false

  /// Distinct series names in first-appearance order (`"Observed"` before the reference-curve
  /// labels, since `bigOChartPoints` emits `runPoints`/`trendPoints` before `referencePoints`).
  private var allSeries: [String] {
    var seen: Set<String> = []
    return points.map(\.series).filter { seen.insert($0).inserted }
  }

  private var visiblePoints: [BigOChartPoint] {
    let filtered = points.filter { !hiddenSeries.contains($0.series) }
    let scatterFiltered = showsIndividualRuns ? filtered : filtered.filter { $0.kind != .observedRun }
    return cappedForRendering(scatterFiltered)
  }

  /// Exactly one per distinct recorded size, same derivation as the compact chart's — used for
  /// axis ticks and domain, independent of `hiddenSeries` so toggling a series never moves them.
  private var observedSizes: [Int] {
    points.filter { $0.kind == .observedTrend }.map(\.size).sorted()
  }

  private var shouldScroll: Bool {
    observedSizes.count > 8
  }

  var body: some View {
    NavigationStack {
      VStack(alignment: .leading, spacing: 16) {
        seriesToggleRow
        chart
        selectionSummary
      }
      .padding(24)
      .frame(maxHeight: .infinity, alignment: .topLeading)
      .navigationTitle(algorithm.metadata.displayName)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button {
            dismiss()
          } label: {
            Text("Done").fixedSize(horizontal: true, vertical: false)
          }
          .frame(width: 48)
          .flexibleButtonSizingIfAvailable()
        }
      }
    }
    .frame(minWidth: 900, minHeight: 700)
    // `.page` expands the sheet to fill most of the presenting window/screen — the deployment
    // target is iOS 18.0, which already has this (unlike the iOS 26-only Liquid Glass APIs
    // elsewhere in this module), so no `#available` gate is needed.
    .presentationSizing(.page)
  }

  private var chart: some View {
    let sizeDomain = observedSizes[0]...observedSizes[observedSizes.count - 1]
    let fullRange = max(observedSizes[observedSizes.count - 1] - observedSizes[0], 1)
    let visibleLength = shouldScroll ? max(fullRange / 3, 1) : fullRange

    return Chart {
      bigOChartMarks(for: visiblePoints)
      // Always present (not conditionally added/removed) — kept off-domain and invisible when
      // there's no selection, so hovering never changes the Chart's mark structure. Toggling a
      // mark in and out was itself part of the resize/flicker loop below: a structural change on
      // every hover-driven `chartXSelection` update forced a full chart relayout each time.
      RuleMark(x: .value("Selected", selectedSize ?? sizeDomain.lowerBound - 1))
        .foregroundStyle(.secondary.opacity(selectedSize == nil ? 0 : 0.5))
        .lineStyle(StrokeStyle(lineWidth: 1, dash: [2, 2]))
    }
    .chartXScale(domain: sizeDomain)
    .chartXAxis {
      AxisMarks(values: observedSizes) { value in
        AxisGridLine()
        AxisTick()
        AxisValueLabel {
          if let size = value.as(Int.self) {
            Text("\(size)")
              .rotationEffect(.degrees(shouldScroll ? -45 : 0))
          }
        }
      }
    }
    .chartXAxisLabel("Array Size")
    .chartYAxisLabel("Normalized Work")
    .chartLegend(position: .bottom, alignment: .center, spacing: 16)
    .chartScrollableAxes(shouldScroll ? .horizontal : [])
    .chartXVisibleDomain(length: visibleLength)
    .chartXSelection(value: $selectedSize)
    // `maxHeight: .infinity` lets the chart grow to fill whatever room `.presentationSizing(.page)`
    // gives the sheet — safe now that `selectionSummary` is always present at a stable size
    // (see its doc comment): the chart's size is set once by the window's fixed dimensions at
    // presentation time, not by anything that changes while hovering.
    .frame(maxWidth: .infinity, minHeight: 300, maxHeight: .infinity)
  }

  private var seriesToggleRow: some View {
    HStack(spacing: 8) {
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 8) {
          ForEach(allSeries, id: \.self) { series in
            Toggle(
              series,
              isOn: Binding(
                get: { !hiddenSeries.contains(series) },
                set: { isOn in
                  if isOn { hiddenSeries.remove(series) } else { hiddenSeries.insert(series) }
                }
              )
            )
            .toggleStyle(.button)
            .controlSize(.small)
          }
        }
      }
      Spacer(minLength: 16)
      Toggle("Show Individual Runs", isOn: $showsIndividualRuns)
        .toggleStyle(.button)
        .controlSize(.small)
    }
  }

  /// Always renders the same number of lines (one per currently-visible series) regardless of
  /// `selectedSize`, with a placeholder space standing in for the value text when there's no
  /// selection — a previous version only added this view to the layout when `selectedSize` was
  /// non-nil, which meant every hover-driven `chartXSelection` update changed the sheet's total
  /// content height. `chartXSelection` fires continuously as the pointer moves (not just on
  /// drag), so that was a resize-on-every-hover feedback loop, worst right at the chart's edges
  /// where the hit-test flips in and out most often.
  private var selectionSummary: some View {
    let visibleSeries = allSeries.filter { !hiddenSeries.contains($0) }
    return VStack(alignment: .leading, spacing: 4) {
      Text(selectedSize.map { "Array Size \($0)" } ?? "Hover the chart to see exact values")
        .font(.headline)
      ForEach(visibleSeries, id: \.self) { series in
        Text(selectionText(for: series) ?? " ")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    }
    .padding(12)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
  }

  /// The single trend/reference point nearest the selected x-position for one series —
  /// `chartXSelection`'s value is continuous, not snapped to a recorded size, and raw
  /// `.observedRun` scatter is excluded since several can share one size.
  private func selectionText(for series: String) -> String? {
    guard let selectedSize else { return nil }
    guard
      let point = points
        .filter({ $0.series == series && $0.kind != .observedRun })
        .min(by: { abs($0.size - selectedSize) < abs($1.size - selectedSize) })
    else { return nil }
    return "\(series): \(point.normalizedValue.formatted(.number.precision(.fractionLength(3))))"
  }
}

extension View {
  /// Same fix `ContentView`'s `SettingsView` sheet uses for its own `.cancellationAction` Done
  /// button — without a fixed width, Mac Catalyst collapses a plain-text toolbar button placed
  /// there into a tiny circular badge (truncating "Done" to "D…") instead of showing it as text.
  @ViewBuilder
  fileprivate func flexibleButtonSizingIfAvailable() -> some View {
    if #available(iOS 26.0, *) {
      buttonSizing(.flexible)
    } else {
      self
    }
  }
}
