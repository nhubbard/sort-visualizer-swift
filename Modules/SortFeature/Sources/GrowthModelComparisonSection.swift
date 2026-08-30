import AlgorithmKit
import Charts
import MathRenderingKit
import SettingsKit
import SwiftUI

/// The growth family `Tools/GrowthModelCalibration` actually detected for this algorithm,
/// alongside the Taylor-polynomial curve (`AlgorithmMetadata.growthModel`) the app uses for
/// sizing — display-only, nothing here feeds back into sizing. Renders nothing when
/// `algorithm.metadata.detectedGrowthModel` is nil, which is every algorithm
/// `Tools/GrowthModelCalibration/apply_detected_models.py` hasn't processed yet — so this ships
/// safely regardless of calibration coverage.
struct GrowthModelComparisonSection: View {
  let algorithm: any SortAlgorithm

  @Environment(AppSettings.self) private var settings

  private var metadata: AlgorithmMetadata { algorithm.metadata }

  /// Same fixed clamp `AlgorithmMetadata.effectiveSizeRange` uses for the sizing UI — keeping the
  /// comparison chart on the same scale as everywhere else that plots against array size.
  private var domain: ClosedRange<Double> {
    Double(metadata.sizeRange.lowerBound)...Double(AlgorithmMetadata.maxReasonableArraySize)
  }

  private var cutoffSize: Double {
    Double(metadata.effectiveSizeRange(operationCap: settings.recordingOperationCap).upperBound)
  }

  var body: some View {
    if let detected = metadata.detectedGrowthModel {
      VStack(alignment: .leading, spacing: 8) {
        Text("Growth Model").font(.title2.bold())
        VStack(alignment: .leading, spacing: 8) {
          LabeledEquationCell(label: "Detected", equation: detected.latex)
          LabeledEquationCell(label: "Fitted (Used by App)", equation: metadata.fittedGrowthModelLatex)
        }
        chart(detected: detected)
        if let divergence = averageDivergencePercent(detected: detected) {
          Text(
            "Diverges from the detected curve by an average of "
              + "\(divergence.formatted(.number.precision(.fractionLength(1))))% of normalized "
              + "work across sizes this algorithm can actually run at. This comparison is "
              + "approximate, not an exact measurement."
          )
          .font(.caption)
          .foregroundStyle(.secondary)
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
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

  private func chart(detected: DetectedGrowthModel) -> some View {
    let normalizer = normalizer(detected: detected)
    let detectedCurve = sampledCurve(predict: detected.predictedOperations(atSize:))
    let fittedCurve = sampledCurve(predict: metadata.growthModel.predictedOperations(atSize:))
    let normalizedValues = (detectedCurve + fittedCurve).map { $0.value / normalizer }
    // Without an explicit domain, Swift Charts' automatic "nice round number" y-axis picked
    // something like -1...2 for data that's actually within a hair of 0...1 -- a detected curve
    // can dip slightly negative at small sizes (e.g. a polynomialIntercept fit with a small
    // negative constant term), and the auto-scaler over-corrects for that sliver by rounding out
    // to whole numbers instead of the tight range the data actually occupies.
    let yDomain = min(0, normalizedValues.min() ?? 0)...max(1, normalizedValues.max() ?? 1)

    return Chart {
      ForEach(Array(detectedCurve.enumerated()), id: \.offset) { _, point in
        LineMark(
          x: .value("Array Size", point.size),
          y: .value("Predicted Work", point.value / normalizer)
        )
        .foregroundStyle(by: .value("Series", "Detected"))
      }
      ForEach(Array(fittedCurve.enumerated()), id: \.offset) { _, point in
        LineMark(
          x: .value("Array Size", point.size),
          y: .value("Predicted Work", point.value / normalizer)
        )
        .foregroundStyle(by: .value("Series", "Fitted (Used by App)"))
        .lineStyle(StrokeStyle(dash: [4, 4]))
      }
      RuleMark(x: .value("Operation Cap Cutoff", cutoffSize))
        .foregroundStyle(.secondary)
        .lineStyle(StrokeStyle(lineWidth: 1, dash: [2, 2]))
        .annotation(position: .bottom, alignment: .center) {
          Text("Cutoff").font(.caption2).foregroundStyle(.secondary)
        }
    }
    .chartXScale(domain: domain, type: .log)
    .chartXAxis {
      AxisMarks(values: powerOfTwoAxisValues(in: domain))
    }
    .chartYScale(domain: yDomain)
    .chartXAxisLabel("Array Size")
    .chartYAxisLabel("Predicted Work (Normalized)")
    .chartLegend(position: .bottom, alignment: .center, spacing: 16)
    .frame(maxWidth: .infinity, minHeight: 160)
    .accessibilityIdentifier("growthModelComparisonChart")
  }

  /// The mean absolute gap between the two curves' own *normalized* values (the same 0-1-ish
  /// scale plotted on the chart below), sampled log-spaced across the range a user can actually
  /// reach (`domain.lowerBound...cutoffSize`) — not a single point at the cutoff, and not the
  /// full chart domain out to `AlgorithmMetadata.maxReasonableArraySize` either. An algorithm
  /// like Bad Sort can diverge sharply well past `cutoffSize` (the chart plots out to
  /// `maxReasonableArraySize` purely for visual context), at sizes no user could ever actually
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
    let lowerBound = domain.lowerBound
    guard cutoffSize > lowerBound, lowerBound > 0 else { return nil }
    let scale = normalizer(detected: detected)
    guard scale > 0 else { return nil }

    let sampleCount = 20
    let logLowerBound = log(lowerBound)
    let logUpperBound = log(cutoffSize)
    let gaps: [Double] = (0..<sampleCount).map { index in
      let fraction = Double(index) / Double(sampleCount - 1)
      let size = exp(logLowerBound + fraction * (logUpperBound - logLowerBound))
      let detectedNormalized = detected.predictedOperations(atSize: size) / scale
      let fittedNormalized = metadata.growthModel.predictedOperations(atSize: size) / scale
      return abs(detectedNormalized - fittedNormalized)
    }
    return gaps.reduce(0, +) / Double(gaps.count) * 100
  }
}
