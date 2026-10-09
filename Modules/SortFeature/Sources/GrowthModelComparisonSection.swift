import Foundation
import AlgorithmKit
import Charts
import MathRenderingKit
import SettingsKit
import SwiftUI

/// The growth family `Tools/GrowthModelCalibration` actually detected for this algorithm,
/// alongside the Taylor-polynomial curve (`AlgorithmMetadata.growthModel`) the app uses for
/// sizing — display-only, nothing here feeds back into sizing. Algorithms without a calibrated
/// detected model show the fitted model and an explanation instead of silently losing the section.
struct GrowthModelComparisonSection: View {
  let algorithm: any SortAlgorithm

  @Environment(AppSettings.self) private var settings

  private var metadata: AlgorithmMetadata { algorithm.metadata }

  private var domain: ClosedRange<Double> {
    metadata.growthComparisonDomain(operationCap: settings.recordingOperationCap)
  }

  private var cutoffSize: Double {
    Double(metadata.effectiveSizeRange(operationCap: settings.recordingOperationCap).upperBound)
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(String(localized: "Growth Model", bundle: .module)).font(.title2.bold())
      if let detected = metadata.detectedGrowthModel {
        let scale = normalizer(detected: detected)
        let summary = growthModelSummary(
          fitted: metadata.growthModel, detected: detected, domain: domain,
          cutoffSize: cutoffSize, scale: scale,
          divergencePercent: averageDivergencePercent(detected: detected))
        VStack(alignment: .leading, spacing: 8) {
          LabeledEquationCell(label: String(localized: "Detected", bundle: .module), equation: detected.latex)
          LabeledEquationCell(label: String(localized: "Fitted (Used by App)", bundle: .module), equation: metadata.fittedGrowthModelLatex)
        }
        chart(detected: detected, scale: scale)
        Text(summary)
          .font(.caption)
          .foregroundStyle(.secondary)
          .accessibilityIdentifier("growthModelSummary")
      } else {
        LabeledEquationCell(label: String(localized: "Fitted (Used by App)", bundle: .module), equation: metadata.fittedGrowthModelLatex)
        Text(String(localized: "A measured growth model is not available for this algorithm yet.", bundle: .module))
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  private func sampledCurve(
    sampleCount: Int = 40, predict: (Double) -> Double
  ) -> [(size: Double, value: Double)] {
    (0..<sampleCount).map { index in
      let fraction = Double(index) / Double(sampleCount - 1)
      let size = domain.lowerBound + fraction * (domain.upperBound - domain.lowerBound)
      return (size, predict(size))
    }
  }

  /// The larger of the two curves' own value at `domain.upperBound` — the same anchor
  /// `bigOChartPoints`' reference curves use, and shared here between the chart's own normalized
  /// y-values and `averageDivergencePercent`'s gap calculation so "N% divergence" means exactly
  /// the same N% a viewer sees as a vertical gap between the two lines on the chart below.
  private func normalizer(detected: DetectedGrowthModel) -> Double {
    max(
      detected.predictedOperations(atSize: domain.upperBound),
      metadata.growthModel.predictedOperations(atSize: domain.upperBound),
      1
    )
  }

  private func chart(detected: DetectedGrowthModel, scale: Double) -> some View {
    let detectedCurve = sampledCurve(predict: detected.predictedOperations(atSize:))
    let fittedCurve = sampledCurve(predict: metadata.growthModel.predictedOperations(atSize:))
    let normalizedValues = (detectedCurve + fittedCurve).map { $0.value / scale }
    // Without an explicit domain, Swift Charts' automatic "nice round number" y-axis picked
    // something like -1...2 for data that's actually within a hair of 0...1 -- a detected curve
    // can dip slightly negative at small sizes (e.g. a polynomialIntercept fit with a small
    // negative constant term), and the auto-scaler over-corrects for that sliver by rounding out
    // to whole numbers instead of the tight range the data actually occupies.
    let yDomain = min(0, normalizedValues.min() ?? 0)...max(1, normalizedValues.max() ?? 1)
    let detectedLabel = String(localized: "Detected", bundle: .module)
    let fittedLabel = String(localized: "Fitted (Used by App)", bundle: .module)

    return Chart {
      ForEach(Array(detectedCurve.enumerated()), id: \.offset) { _, point in
        LineMark(
          x: .value("Array Size", point.size),
          y: .value("Predicted Work", point.value / scale)
        )
        .foregroundStyle(by: .value("Series", detectedLabel))
      }
      ForEach(Array(fittedCurve.enumerated()), id: \.offset) { _, point in
        LineMark(
          x: .value("Array Size", point.size),
          y: .value("Predicted Work", point.value / scale)
        )
        .foregroundStyle(by: .value("Series", fittedLabel))
        .lineStyle(StrokeStyle(dash: [4, 4]))
      }
      RuleMark(x: .value("Operation Cap Cutoff", cutoffSize))
        .foregroundStyle(.secondary)
        .lineStyle(StrokeStyle(lineWidth: 1, dash: [2, 2]))
    }
    .chartXScale(domain: domain, type: .log)
    .chartXAxis {
      AxisMarks(values: powerOfTwoAxisValues(in: domain, maximumCount: 6))
    }
    .chartYScale(domain: yDomain)
    .chartXAxisLabel(String(localized: "Array Size", bundle: .module))
    .chartYAxisLabel(String(localized: "Predicted Work (Normalized)", bundle: .module))
    .chartLegend(position: .bottom, alignment: .center, spacing: 16)
    .frame(maxWidth: .infinity, minHeight: 160)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(String(localized: "Growth model comparison", bundle: .module))
    .accessibilityValue(String(localized:
      "Detected, solid line. Fitted (Used by App), dashed line. Dotted line: maximum selectable size, \(Int(cutoffSize)) items.",
      bundle: .module))
    .accessibilityIdentifier("growthModelComparisonChart")
  }

  /// The mean absolute gap between the two curves' own *normalized* values (the same 0-1-ish
  /// scale plotted on the chart below), sampled log-spaced across the range a user can actually
  /// reach (`domain.lowerBound...cutoffSize`) — not a single point at the cutoff, and not the
  /// chart's nearby extrapolation past `cutoffSize` either. An algorithm
  /// like Bad Sort can diverge sharply beyond the usable range, at sizes no user could actually
  /// reach under the current operation cap, so including them here would report a scarier number
  /// than the one that's actually reachable. Log-spaced, not linear, so the average isn't
  /// dominated by the handful of samples nearest `cutoffSize` — each order of magnitude of array
  /// size contributes about equally.
  ///
  /// Deliberately *not* `abs(detected - fitted) / detected` (relative error): that blows up
  /// without bound the moment `detected(n)` passes near zero anywhere in the sampled range, which
  /// real polynomial-family fits can do well before `cutoffSize` even for a curve that looks
  /// visually close on the chart (a real case measured 637% this way for a curve whose worst
  /// visual gap, at the cutoff itself, was 0.6 vs. 1.0 normalized — 40 percentage points, not
  /// 637%). Comparing the same normalized values the chart already draws avoids dividing by
  /// something that can be near-zero, and reports a number that means what it looks like on the
  /// chart: an average vertical gap between the two lines, as a percentage of the chart's own
  /// normalized scale.
  private func averageDivergencePercent(detected: DetectedGrowthModel) -> Double? {
    normalizedGrowthDivergencePercent(
      fitted: metadata.growthModel, detected: detected, lowerBound: domain.lowerBound,
      cutoffSize: cutoffSize, scale: normalizer(detected: detected))
  }
}

#if DEBUG
/// Renders the shipping growth section in isolation for the all-algorithm narrow-width UI audit.
public struct GrowthModelAuditContent: View {
  private let algorithm: any SortAlgorithm

  public init(algorithm: any SortAlgorithm) {
    self.algorithm = algorithm
  }

  public var body: some View {
    GrowthModelComparisonSection(algorithm: algorithm)
  }
}
#endif

/// The caption's percent gap uses the same normalization as the two plotted curves. Kept
/// independent of SwiftUI so the reachable-range calculation can be checked with known curves.
func normalizedGrowthDivergencePercent(
  fitted: OperationGrowthModel, detected: DetectedGrowthModel, lowerBound: Double,
  cutoffSize: Double, scale: Double
) -> Double? {
  guard cutoffSize > lowerBound, lowerBound > 0, scale > 0 else { return nil }

  let sampleCount = 20
  let logLowerBound = log(lowerBound)
  let logUpperBound = log(cutoffSize)
  let gaps: [Double] = (0..<sampleCount).map { index in
    let fraction = Double(index) / Double(sampleCount - 1)
    let size = exp(logLowerBound + fraction * (logUpperBound - logLowerBound))
    let detectedNormalized = detected.predictedOperations(atSize: size) / scale
    let fittedNormalized = fitted.predictedOperations(atSize: size) / scale
    return abs(detectedNormalized - fittedNormalized)
  }
  return gaps.reduce(0, +) / Double(gaps.count) * 100
}

/// Uses the chart's exact model inputs, upper-domain normalizer, and reachable cutoff. Endpoint
/// values describe the overall change without assigning a growth family to a polynomial fit.
func growthModelSummary(
  fitted: OperationGrowthModel, detected: DetectedGrowthModel,
  domain: ClosedRange<Double>, cutoffSize: Double, scale: Double,
  divergencePercent: Double?
) -> String {
  let lower = domain.lowerBound
  let upper = domain.upperBound
  func value(_ prediction: Double) -> String {
    (prediction / scale).formatted(.number.precision(.fractionLength(2)))
  }

  let lowerSize = Int(lower)
  let upperSize = Int(upper)
  let maximumSize = Int(cutoffSize)
  let detectedStart = value(detected.predictedOperations(atSize: lower))
  let detectedEnd = value(detected.predictedOperations(atSize: cutoffSize))
  let fittedStart = value(fitted.predictedOperations(atSize: lower))
  let fittedEnd = value(fitted.predictedOperations(atSize: cutoffSize))
  var summary = String(localized:
    "Horizontal axis: array size from \(lowerSize) to \(upperSize) items. Vertical axis: predicted operations on a shared scale set at \(upperSize) items, without units. Across selectable sizes \(lowerSize) to \(maximumSize), Detected (solid line) changes from \(detectedStart) to \(detectedEnd); Fitted (Used by App, dashed line) changes from \(fittedStart) to \(fittedEnd). The dotted line marks the maximum selectable size, \(maximumSize) items.",
    bundle: .module)
  if let divergencePercent {
    let percent = divergencePercent.formatted(.number.precision(.fractionLength(1)))
    summary += String(localized:
      " Their average separation across selectable sizes is \(percent)% of the normalized work scale; this is an approximation.",
      bundle: .module)
  }
  return summary
}
