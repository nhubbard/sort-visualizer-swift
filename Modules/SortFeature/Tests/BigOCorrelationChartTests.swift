import Foundation
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

  @Test(arguments: [.statMin, .statMax, .statMedian, .statStdDevBand] as [BigOChartPoint.Kind])
  func rainbowStatKindsAreKeptOnlyAtPowerOfTwoSizes(kind: BigOChartPoint.Kind) {
    let points = [1, 3, 16, 17, 100, 256].map { point(size: $0, kind: kind) }
    let filtered = powerOfTwoSizesOnly(points)
    #expect(filtered.map(\.size).sorted() == [1, 16, 256])
  }

  @Test(arguments: [.observedRun, .observedTrend, .reference] as [BigOChartPoint.Kind])
  func nonStatKindsPassThroughRegardlessOfSize(kind: BigOChartPoint.Kind) {
    let points = [1, 3, 16, 17, 100, 256].map { point(size: $0, kind: kind) }
    let filtered = powerOfTwoSizesOnly(points)
    #expect(filtered.map(\.size).sorted() == [1, 3, 16, 17, 100, 256])
  }

  @Test
  func powerOfTwoAxisValuesBracketsANonPowerOfTwoRange() {
    #expect(powerOfTwoAxisValues(in: 16...300) == [16, 32, 64, 128, 256, 512])
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
}
