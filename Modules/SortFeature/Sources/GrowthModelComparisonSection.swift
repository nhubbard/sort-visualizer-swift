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
        Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 6) {
          MathGridRow(text: "Detected", equation: detected.latex)
          MathGridRow(text: "Fitted (Used by App)", equation: metadata.fittedGrowthModelLatex)
        }
        chart(detected: detected)
        if let divergence = averageDivergencePercent(detected: detected) {
          Text(
            "Averages \(divergence.formatted(.number.precision(.fractionLength(1))))% divergence "
              + "from the detected curve across sizes this algorithm can actually run at."
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

  private func chart(detected: DetectedGrowthModel) -> some View {
    let detectedCurve = sampledCurve(predict: detected.predictedOperations(atSize:))
    let fittedCurve = sampledCurve(predict: metadata.growthModel.predictedOperations(atSize:))
    let normalizer = max(
      detectedCurve.last?.value ?? 1, fittedCurve.last?.value ?? 1, 1)

    return Chart {
      ForEach(Array(detectedCurve.enumerated()), id: \.offset) { _, point in
        LineMark(
          x: .value("Array Size", point.size),
          y: .value("Normalized Work", point.value / normalizer)
        )
        .foregroundStyle(by: .value("Series", "Detected"))
      }
      ForEach(Array(fittedCurve.enumerated()), id: \.offset) { _, point in
        LineMark(
          x: .value("Array Size", point.size),
          y: .value("Normalized Work", point.value / normalizer)
        )
        .foregroundStyle(by: .value("Series", "Fitted (Used by App)"))
        .lineStyle(StrokeStyle(dash: [4, 4]))
      }
      RuleMark(x: .value("Operation Cap Cutoff", cutoffSize))
        .foregroundStyle(.secondary)
        .lineStyle(StrokeStyle(lineWidth: 1, dash: [2, 2]))
        .annotation(position: .top, alignment: .center) {
          Text("Cutoff").font(.caption2).foregroundStyle(.secondary)
        }
    }
    .chartXScale(domain: domain, type: .log)
    .chartXAxis {
      AxisMarks(values: powerOfTwoAxisValues(in: domain))
    }
    .chartXAxisLabel("Array Size")
    .chartYAxisLabel("Normalized Work")
    .chartLegend(position: .bottom, alignment: .center, spacing: 16)
    .frame(maxWidth: .infinity, minHeight: 160)
    .accessibilityIdentifier("growthModelComparisonChart")
  }

  /// The mean of `abs(detected(n) - fitted(n)) / detected(n)` sampled log-spaced across the range
  /// a user can actually reach (`domain.lowerBound...cutoffSize`) — not a single point at the
  /// cutoff, and not the full chart domain out to `AlgorithmMetadata.maxReasonableArraySize`
  /// either. An algorithm like Bad Sort can diverge sharply well past `cutoffSize` (the chart
  /// plots out to `maxReasonableArraySize` purely for visual context), at sizes no user could
  /// ever actually reach under the current operation cap, so including them here would report a
  /// scarier number than the one that's actually reachable. Log-spaced, not linear, so the
  /// average isn't dominated by the handful of samples nearest `cutoffSize` — each order of
  /// magnitude of array size contributes about equally.
  private func averageDivergencePercent(detected: DetectedGrowthModel) -> Double? {
    let lowerBound = domain.lowerBound
    guard cutoffSize > lowerBound, lowerBound > 0 else { return nil }

    let sampleCount = 20
    let logLowerBound = log(lowerBound)
    let logUpperBound = log(cutoffSize)
    let divergences: [Double] = (0..<sampleCount).compactMap { index in
      let fraction = Double(index) / Double(sampleCount - 1)
      let size = exp(logLowerBound + fraction * (logUpperBound - logLowerBound))
      let detectedValue = detected.predictedOperations(atSize: size)
      guard detectedValue > 0 else { return nil }
      let fittedValue = metadata.growthModel.predictedOperations(atSize: size)
      return abs(detectedValue - fittedValue) / detectedValue * 100
    }
    guard !divergences.isEmpty else { return nil }
    return divergences.reduce(0, +) / Double(divergences.count)
  }
}
