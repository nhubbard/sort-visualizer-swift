import AlgorithmKit
import Foundation
import SortEngineKit
import SwiftUI
import Testing

@testable import PersistenceKit
@testable import SortFeature

@Suite
struct BigOCorrelationChartTests {
  private func point(size: Int, kind: BigOChartPoint.Kind, series: String = "Observed")
    -> BigOChartPoint {
    BigOChartPoint(id: UUID().uuidString, series: series, size: size, normalizedValue: 0.5, kind: kind)
  }

  @Test
  func scatterPointsAreCappedPerDistinctSize() {
    let points = (0..<20).map { _ in point(size: 100, kind: .observedRun) }
    let capped = cappedForRendering(points, maxScatterPerSize: 15)
    #expect(capped.count == 15)
  }

  @Test
  func differentSizesAreCappedIndependently() {
    let points = (0..<20).map { _ in point(size: 100, kind: .observedRun) }
      + (0..<5).map { _ in point(size: 200, kind: .observedRun) }
    let capped = cappedForRendering(points, maxScatterPerSize: 15)
    #expect(capped.filter { $0.size == 100 }.count == 15)
    #expect(capped.filter { $0.size == 200 }.count == 5)
  }

  @Test
  func trendAndReferencePointsAreNeverCappedEvenPastTheLimit() {
    let points = (0..<20).map { _ in point(size: 100, kind: .observedTrend) }
      + (0..<20).map { _ in point(size: 100, kind: .reference) }
    let capped = cappedForRendering(points, maxScatterPerSize: 15)
    #expect(capped.count == 40)
  }

  @Test
  func compactSizesKeepEndpointsAndNeverRequirePowersOfTwo() {
    let sizes = Array(stride(from: 17, through: 217, by: 10))
    let selected = representativeSizes(sizes, maximum: 8)
    #expect(selected.count == 8)
    #expect(selected.contains(17))
    #expect(selected.contains(217))
    #expect(selected.isSubset(of: Set(sizes)))
  }

  @Test
  func compactSizesKeepAllSparseObservations() {
    #expect(representativeSizes([17, 35, 91], maximum: 8) == [17, 35, 91])
  }

  @Test
  func compactChartShowsMeanAndStatsAtNoMoreThanEightObservedSizes() {
    let points = (0..<40).flatMap { index -> [BigOChartPoint] in
      let size = 17 + index * 10
      return [
        point(size: size, kind: .observedRun),
        point(size: size, kind: .observedTrend),
        point(size: size, kind: .statMin),
        point(size: size, kind: .statMax),
        point(size: size, kind: .statMedian),
        point(size: size, kind: .statStdDevBand),
        point(size: size, kind: .reference),
      ]
    }
    let selected = compactChartPoints(points)
    #expect(Set(selected.map(\.size)).count == 8)
    #expect(selected.count == 8 * 5)
    #expect(selected.filter { $0.kind == .observedTrend }.count == 8)
    #expect(!selected.contains { $0.kind == .observedRun || $0.kind == .reference })
  }

  @Test
  func detailScatterHasATotalRenderingBudgetWithoutDroppingSummaryCurves() {
    let scatter = (0..<1_000).map { index in point(size: 16 + index, kind: .observedRun) }
    let trends = (0..<1_000).map { index in point(size: 16 + index, kind: .observedTrend) }
    let result = cappedForRendering(scatter + trends)
    #expect(result.filter { $0.kind == .observedRun }.count == 300)
    #expect(result.filter { $0.kind == .observedTrend }.count == 1_000)
    #expect(result.first { $0.kind == .observedRun }?.size == 16)
  }

  @Test
  func powerOfTwoAxisValuesBracketsANonPowerOfTwoRange() {
    #expect(powerOfTwoAxisValues(in: 16...300) == [16, 32, 64, 128, 256, 512])
  }

  @Test
  func powerOfTwoAxisValuesBoundsDenseLabelCounts() {
    let values = powerOfTwoAxisValues(in: 2...8192, maximumCount: 6)
    #expect(values.count == 6)
    #expect(values.first == 2)
    #expect(values.last == 8192)
    #expect(values == values.sorted())
  }

  @Test
  func powerOfTwoAxisValuesMatchesARangeAlreadyAtExactPowers() {
    #expect(powerOfTwoAxisValues(in: 8...64) == [8, 16, 32, 64])
  }

  @Test
  func powerOfTwoAxisValuesBracketsASingleNonPowerOfTwoValue() {
    #expect(powerOfTwoAxisValues(in: 5...5) == [4, 8])
  }

  @Test
  func powerOfTwoAxisValuesNeverGoesBelowOneEvenForASubOneLowerBound() {
    #expect(powerOfTwoAxisValues(in: 0.5...4) == [1, 2, 4])
  }

  @Test
  func powerOfTwoAxisValuesIsEmptyWhenTheUpperBoundIsBelowOne() {
    #expect(powerOfTwoAxisValues(in: 0.1...0.5).isEmpty)
  }

  @MainActor
  @Test
  func detailChartRendersRecordedAndReferenceSeries() {
    let sizes = [16, 32, 64, 128]
    let points = sizes.flatMap { size in
      [
        BigOChartPoint(
          id: "trend-\(size)", series: "Observed", size: size,
          normalizedValue: Double(size) / 128, kind: .observedTrend),
        BigOChartPoint(
          id: "run-\(size)", series: "Observed", size: size,
          normalizedValue: Double(size) / 120, kind: .observedRun),
        BigOChartPoint(
          id: "reference-\(size)", series: "O(n)", size: size,
          normalizedValue: Double(size) / 128, kind: .reference),
      ]
    }
    let renderer = ImageRenderer(content: BigOCorrelationDetailView(
      algorithm: ChartTestAlgorithm(), points: points))
    renderer.proposedSize = ProposedViewSize(width: 1000, height: 800)

    let image = renderer.uiImage
    #expect(image != nil)
    #expect(image?.size.width == 1000)
    #expect(image?.size.height == 800)
  }
}

private struct ChartTestAlgorithm: SortAlgorithm {
  let id = AlgorithmID(rawValue: "chart-test")
  var metadata: AlgorithmMetadata {
    AlgorithmMetadata(
      displayName: "Chart Test", category: .exchange, sizeRange: 1...128,
      growthModel: .unconstrained, implementationComplexity: 0, stable: true,
      timeComplexity: ComplexityBounds(best: "O(n)", average: "O(n)", worst: "O(n)"),
      spaceComplexity: "O(1)", iconName: "chart")
  }
  func record(into engine: inout RecordingEngine) {}
}

@Suite
struct GrowthModelComparisonTests {
  private let detected = DetectedGrowthModel(
    family: .powerLaw, coefficients: [2, 1], rSquared: 1)

  @Test
  func matchingCurvesHaveNoReportedDivergence() throws {
    let fitted = OperationGrowthModel(anchorSize: 0, coefficients: [0, 2])
    let percent = try #require(normalizedGrowthDivergencePercent(
      fitted: fitted, detected: detected, lowerBound: 2, cutoffSize: 128, scale: 256))
    #expect(abs(percent) < 0.0000001)
  }

  @Test
  func divergenceUsesOnlyTheReachableRange() throws {
    let fitted = OperationGrowthModel(anchorSize: 0, coefficients: [0, 1])
    let narrow = try #require(normalizedGrowthDivergencePercent(
      fitted: fitted, detected: detected, lowerBound: 2, cutoffSize: 8, scale: 256))
    let wide = try #require(normalizedGrowthDivergencePercent(
      fitted: fitted, detected: detected, lowerBound: 2, cutoffSize: 128, scale: 256))
    #expect(narrow > 0)
    #expect(wide > narrow)
    #expect(wide < 100)
  }

  @Test
  func invalidReachableDomainsDoNotProduceACaption() {
    let fitted = OperationGrowthModel(anchorSize: 0, coefficients: [0, 2])
    #expect(normalizedGrowthDivergencePercent(
      fitted: fitted, detected: detected, lowerBound: 8, cutoffSize: 8, scale: 256) == nil)
    #expect(normalizedGrowthDivergencePercent(
      fitted: fitted, detected: detected, lowerBound: 0, cutoffSize: 8, scale: 256) == nil)
    #expect(normalizedGrowthDivergencePercent(
      fitted: fitted, detected: detected, lowerBound: 2, cutoffSize: 8, scale: 0) == nil)
  }
}
