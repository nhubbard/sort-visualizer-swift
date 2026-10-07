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
  @Environment(\.dynamicTypeSize) private var dynamicTypeSize
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

  private var referenceSeries: [String] {
    var seen: Set<String> = []
    return points.filter { $0.kind == .reference }.map(\.series)
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
      ScrollView {
        VStack(alignment: .leading, spacing: 20) {
          VStack(alignment: .leading, spacing: 6) {
            Text("Recorded work")
              .font(.title2.bold())
            Text(recordedRunSummary(points))
              .font(.subheadline)
              .foregroundStyle(.secondary)
          }
          seriesToggleRow
          VStack(alignment: .leading, spacing: 16) {
            chart
            if !hiddenSeries.contains("Observed") {
              Divider()
              Text("Point symbols")
                .font(.headline)
              RainbowStatLegend()
              if showsIndividualRuns {
                Label("Individual runs (asterisks)", systemImage: "asterisk")
                  .font(.caption)
                  .foregroundStyle(.secondary)
                  .accessibilityIdentifier("bigOScatterLegend")
              }
            }
          }
          .padding(20)
          .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
          selectionSummary
        }
        #if DEBUG
        .frame(maxWidth: auditContentWidth ?? 960, alignment: .leading)
        #else
        .frame(maxWidth: 960, alignment: .leading)
        #endif
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .center)
      }
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
    .onKeyPress(phases: .down) { press in
      // Catalyst does not always send sheet-local keyboard shortcuts through the scroll view.
      // Keep exact-value navigation available while a series toggle has keyboard focus.
      guard press.modifiers.isEmpty else { return .ignored }
      switch press.characters.lowercased() {
      case "p": selectRecordedSize(offset: -1)
      case "n": selectRecordedSize(offset: 1)
      default: return .ignored
      }
      return .handled
    }
    // Let the host choose a size that fits portrait and split-window layouts. A fixed 900-point
    // minimum clipped the controls and chart on narrower iPads.
    .presentationSizing(.page)
  }

  private var chart: some View {
    let sizeDomain = observedSizes[0]...observedSizes[observedSizes.count - 1]
    let logDomain = Double(sizeDomain.lowerBound)...Double(sizeDomain.upperBound)
    return chartContent(sizeDomain: sizeDomain, logDomain: logDomain)
      .frame(maxWidth: .infinity, minHeight: 300, maxHeight: 420)
      .accessibilityElement(children: .ignore)
      .accessibilityLabel("Recorded runs chart")
      .accessibilityValue(recordedRunSummary(points)
        + (hiddenSeries.contains("Observed") ? "" : " Solid line with circles: Observed mean. "
          + "Shaped points: observed minimum, square; maximum, triangle; median, diamond; "
          + "mean plus or minus one standard deviation, plus marks.")
        + (referenceSeries.filter { !hiddenSeries.contains($0) }.isEmpty ? "" :
          " Dashed reference curves: "
          + referenceSeries.filter { !hiddenSeries.contains($0) }.joined(separator: ", ") + ".")
        + (showsIndividualRuns && !hiddenSeries.contains("Observed")
          ? " Asterisks show individual runs." : "")
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
      "Best & Average Case": Color.blue,
      "Best & Worst Case": Color.blue,
      "Average & Worst Case": Color.green,
      "Best & Average & Worst Case": Color.blue,
      "Observed": Color.gray,
    ])
    // Keep legend entries below the plot so every name remains visible at the sheet's width.
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

  private var seriesToggleRow: some View {
    VStack(alignment: .leading, spacing: 14) {
      VStack(alignment: .leading, spacing: 4) {
        Text("Show on chart")
          .font(.headline)
        Text("Switch curves on or off to compare them.")
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }
      LazyVGrid(
        columns: dynamicTypeSize.isAccessibilitySize
          ? [GridItem(.flexible())]
          : [GridItem(.adaptive(minimum: 250), spacing: 12)],
        alignment: .leading,
        spacing: 12
      ) {
        ForEach(allSeries, id: \.self) { series in
          Toggle(isOn: Binding(
              get: { !hiddenSeries.contains(series) },
              set: { isOn in
                if isOn { hiddenSeries.remove(series) } else { hiddenSeries.insert(series) }
              }
            )) {
              HStack(spacing: 10) {
                seriesSample(for: series)
                Text(seriesDisplayName(series))
                  .font(.subheadline)
                Spacer(minLength: 8)
              }
            }
          .toggleStyle(.switch)
          .tint(.accentColor)
          .accessibilityIdentifier("bigOSeriesToggle.\(series)")
        }
      }
      Divider()
      Toggle(isOn: $showsIndividualRuns) {
        Label("Show Individual Runs", systemImage: "asterisk")
          .font(.subheadline)
      }
      .toggleStyle(.switch)
      .tint(.accentColor)
      .accessibilityIdentifier("Show Individual Runs")
    }
    .padding(16)
    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
  }

  private func seriesSample(for series: String) -> some View {
    Path { path in
      path.move(to: CGPoint(x: 0, y: 8))
      path.addLine(to: CGPoint(x: 34, y: 8))
    }
    .stroke(series == "Observed" ? Color.blue : referenceColor(for: series),
            style: series == "Observed" ? StrokeStyle(lineWidth: 2) : referenceLineStyle(for: series))
    .frame(width: 34, height: 16)
    .overlay {
      if series == "Observed" {
        Circle()
          .fill(.blue)
          .frame(width: 7, height: 7)
      }
    }
    .accessibilityHidden(true)
  }

  /// Tap selection changes at most once per gesture, so the empty state can stay compact instead
  /// of reserving a tall blank panel for values that have not been requested yet.
  private var selectionSummary: some View {
    let visibleSeries = allSeries.filter { !hiddenSeries.contains($0) }
    return VStack(alignment: .leading, spacing: 4) {
      HStack {
        Group {
          if let selectedSize {
            Text("Array Size \(selectedSize)")
          } else {
            Text("Select a size on the chart to see exact values")
          }
        }
        .font(.headline)
        .accessibilityIdentifier("bigOSelectedSize")
      }
      HStack(spacing: 8) {
        Button {
          selectRecordedSize(offset: -1)
        } label: {
          Label("Previous", systemImage: "chevron.backward")
        }
        .buttonStyle(.bordered)
        .keyboardShortcut("p", modifiers: [.command, .option])
        .help("Previous recorded size (P or ⌘⌥P)")
        .accessibilityLabel("Previous Recorded Size")
        .accessibilityIdentifier("bigOPreviousRecordedSize")
        .focusable()
        .disabled(selectedSize == observedSizes.first)
        Button {
          selectRecordedSize(offset: 1)
        } label: {
          Label("Next", systemImage: "chevron.forward")
        }
        .buttonStyle(.bordered)
        .keyboardShortcut("n", modifiers: [.command, .option])
        .help("Next recorded size (N or ⌘⌥N)")
        .accessibilityLabel("Next Recorded Size")
        .accessibilityIdentifier("bigONextRecordedSize")
        .focusable()
        .disabled(selectedSize == observedSizes.last)
        Spacer(minLength: 0)
      }
      if selectedSize != nil {
        ForEach(visibleSeries, id: \.self) { series in
          Text(selectionText(for: series) ?? " ")
            .font(.caption)
            .foregroundStyle(.secondary)
            .accessibilityIdentifier("bigOSelection.\(series)")
        }
        if visibleSeries.contains("Observed") {
          ForEach(observedStatisticTexts(), id: \.self) { value in
            Text(value)
              .font(.caption)
              .foregroundStyle(.secondary)
          }
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
        .filter({ $0.series == series &&
          (series == "Observed" ? $0.kind == .observedTrend : $0.kind == .reference) })
        .min(by: { abs($0.size - selectedSize) < abs($1.size - selectedSize) })
    else { return nil }
    let name = series == "Observed"
      ? String(localized: "Observed mean", bundle: .module)
      : seriesDisplayName(series)
    let value = point.normalizedValue.formatted(.number.precision(.fractionLength(3)))
    return String(localized: "\(name): \(value)", bundle: .module)
  }

  private func observedStatisticTexts() -> [String] {
    guard let selectedSize else { return [] }
    let atSize = points.filter { $0.size == selectedSize }
    func value(_ kind: BigOChartPoint.Kind) -> String? {
      atSize.first { $0.kind == kind }?.normalizedValue
        .formatted(.number.precision(.fractionLength(3)))
    }
    var result: [String] = []
    if let minimum = value(.statMin) {
      result.append(String(localized: "Observed minimum: \(minimum)", bundle: .module))
    }
    if let maximum = value(.statMax) {
      result.append(String(localized: "Observed maximum: \(maximum)", bundle: .module))
    }
    if let median = value(.statMedian) {
      result.append(String(localized: "Observed median: \(median)", bundle: .module))
    }
    let standardDeviation = atSize.filter { $0.kind == .statStdDevBand }
      .map(\.normalizedValue).sorted()
    if let lower = standardDeviation.first, let upper = standardDeviation.last,
       standardDeviation.count == 2 {
      let lowerValue = lower.formatted(.number.precision(.fractionLength(3)))
      let upperValue = upper.formatted(.number.precision(.fractionLength(3)))
      result.append(String(localized: "Mean ±1 standard deviation: \(lowerValue)–\(upperValue)", bundle: .module))
    }
    return result
  }

  private func seriesDisplayName(_ series: String) -> String {
    switch series {
    case "Observed": String(localized: "Observed", bundle: .module)
    case "Best Case": String(localized: "Best Case", bundle: .module)
    case "Average Case": String(localized: "Average Case", bundle: .module)
    case "Worst Case": String(localized: "Worst Case", bundle: .module)
    case "Best & Average Case": String(localized: "Best & Average Case", bundle: .module)
    case "Best & Worst Case": String(localized: "Best & Worst Case", bundle: .module)
    case "Average & Worst Case": String(localized: "Average & Worst Case", bundle: .module)
    case "Best & Average & Worst Case": String(localized: "Best & Average & Worst Case", bundle: .module)
    default: series
    }
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
