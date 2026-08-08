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
}
