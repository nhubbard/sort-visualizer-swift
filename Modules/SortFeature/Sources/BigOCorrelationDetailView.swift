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
  /// re-lays out every mark as the surrounding scroll view moves, so leaving this off keeps
  /// scrolling smooth; it's an opt-in for
  /// seeing per-run variance/outliers, not the default view.
  @State private var showsIndividualRuns = false
  #if DEBUG
  private let auditContentWidth = ProcessInfo.processInfo.environment["UI_TEST_EXPANDED_WIDTH"]
    .flatMap(Double.init).map { CGFloat($0) - 48 }
  #endif

  /// Distinct series names in first-appearance order (`"Observed"` before the reference-curve
  /// labels, since `bigOChartPoints` emits `runPoints`/`trendPoints` before `referencePoints`).
  private var allSeries: [String] {
    var seen: Set<String> = []
    return points.filter { $0.kind != .observedRun }.map(\.series)
      .filter { seen.insert($0).inserted }
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

  var body: some View {
    NavigationStack {
      VStack(alignment: .leading, spacing: 16) {
        seriesToggleRow
        chart
        referenceLegend
        RainbowStatLegend()
        selectionSummary
      }
      #if DEBUG
      .frame(maxWidth: auditContentWidth ?? .infinity, alignment: .leading)
      #endif
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
    // Let the host choose a size that fits portrait and split-window layouts. A fixed 900-point
    // minimum clipped the controls and chart on narrower iPads.
    .presentationSizing(.page)
  }

  private var chart: some View {
    let sizeDomain = observedSizes[0]...observedSizes[observedSizes.count - 1]
    let logDomain = Double(sizeDomain.lowerBound)...Double(sizeDomain.upperBound)
    return chartContent(sizeDomain: sizeDomain, logDomain: logDomain)
      .frame(maxWidth: .infinity, minHeight: 300, maxHeight: 500)
      .accessibilityElement(children: .ignore)
      .accessibilityLabel("Recorded runs chart")
      .accessibilityValue(recordedRunSummary(points)
        + " Use Previous Recorded Size and Next Recorded Size below the chart for exact values.")
      .accessibilityIdentifier("bigOCorrelationExpandedChart")
  }

  private func chartContent(
    sizeDomain: ClosedRange<Int>, logDomain: ClosedRange<Double>
  ) -> some View {
    Chart {
      bigOChartMarks(for: visiblePoints)
      // Always present (not conditionally added/removed) — kept off-domain and invisible when
      // there's no selection, so selecting never changes the Chart's mark structure. Toggling a
      // mark in and out was itself part of the resize/flicker loop below: a structural change on
      // every selection update forced a full chart relayout each time.
      // `max(..., 1)`, not just `sizeDomain.lowerBound - 1` -- a `.log`-scaled axis can't position
      // a value <= 0 at all, and this needs to stay a valid (if invisible) point even in the
      // pathological case of a size-1 lower bound.
      RuleMark(x: .value("Selected", max(selectedSize ?? sizeDomain.lowerBound - 1, 1)))
        .foregroundStyle(.secondary.opacity(selectedSize == nil ? 0 : 0.5))
        .lineStyle(StrokeStyle(lineWidth: 1, dash: [2, 2]))
    }
    .chartXScale(domain: sizeDomain, type: .log)
    .chartXAxis {
      // Keep labels readable in the current sheet width, including a narrow split view.
      AxisMarks(values: powerOfTwoAxisValues(in: logDomain, maximumCount: 5))
    }
    .chartXAxisLabel("Array Size")
    .chartYAxis { AxisMarks(position: .leading) }
    .chartYAxisLabel("Normalized Work")
    .chartForegroundStyleScale([
      "Best Case": Color.blue,
      "Average Case": Color.green,
      "Worst Case": Color.orange,
      "Individual Runs": Color.gray,
    ])
    // The plot is wider than its viewport when many sizes are recorded. Keep its legend outside
    // that horizontal scroll view so the rightmost label is never clipped on opening the sheet.
    .chartLegend(.hidden)
    .chartOverlay { proxy in
      GeometryReader { geometry in
        Rectangle()
          .fill(.clear)
          .contentShape(Rectangle())
          .onTapGesture { location in
            guard let plotFrame = proxy.plotFrame else { return }
            let plotX = location.x - geometry[plotFrame].origin.x
            selectedSize = proxy.value(atX: plotX, as: Int.self)
          }
      }
    }
  }

  private var referenceLegend: some View {
    HStack(spacing: 16) {
      ForEach(["Best Case", "Average Case", "Worst Case"], id: \.self) { series in
        HStack(spacing: 4) {
          Capsule()
            .fill(referenceColor(for: series))
            .frame(width: 16, height: 2)
          Text(series)
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
      }
    }
    .accessibilityIdentifier("bigOReferenceLegend")
  }

  private func referenceColor(for series: String) -> Color {
    switch series {
    case "Best Case": .blue
    case "Average Case": .green
    default: .orange
    }
  }

  private var seriesToggleRow: some View {
    VStack(alignment: .leading, spacing: 8) {
      LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 8)], alignment: .leading, spacing: 8) {
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
          .accessibilityIdentifier("bigOSeriesToggle.\(series)")
        }
      }
      Toggle("Show Individual Runs", isOn: $showsIndividualRuns)
        .toggleStyle(.button)
        .controlSize(.small)
        .frame(maxWidth: .infinity, alignment: .trailing)
    }
  }

  /// Tap selection changes at most once per gesture, so the empty state can stay compact instead
  /// of reserving a tall blank panel for values that have not been requested yet.
  private var selectionSummary: some View {
    let visibleSeries = allSeries.filter { !hiddenSeries.contains($0) }
    return VStack(alignment: .leading, spacing: 4) {
      HStack {
        Text(selectedSize.map { "Array Size \($0)" } ?? "Select a size on the chart to see exact values")
          .font(.headline)
          .accessibilityIdentifier("bigOSelectedSize")
        Spacer()
        Button {
          selectRecordedSize(offset: -1)
        } label: {
          Image(systemName: "chevron.left")
        }
        .accessibilityLabel("Previous Recorded Size")
        .accessibilityIdentifier("bigOPreviousRecordedSize")
        .disabled(selectedSize == observedSizes.first)
        Button {
          selectRecordedSize(offset: 1)
        } label: {
          Image(systemName: "chevron.right")
        }
        .accessibilityLabel("Next Recorded Size")
        .accessibilityIdentifier("bigONextRecordedSize")
        .disabled(selectedSize == observedSizes.last)
      }
      if selectedSize != nil {
        ForEach(visibleSeries, id: \.self) { series in
          Text(selectionText(for: series) ?? " ")
            .font(.caption)
            .foregroundStyle(.secondary)
            .accessibilityIdentifier("bigOSelection.\(series)")
        }
      }
    }
    .padding(12)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
  }

  private func selectRecordedSize(offset: Int) {
    guard !observedSizes.isEmpty else { return }
    let index = selectedSize.flatMap { selected in
      observedSizes.enumerated().min {
        abs($0.element - selected) < abs($1.element - selected)
      }?.offset
    } ?? (offset > 0 ? -1 : observedSizes.count)
    selectedSize = observedSizes[min(max(index + offset, 0), observedSizes.count - 1)]
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
