import AlgorithmKit
import Foundation
import SortEngineKit
import SwiftData
import Testing

@testable import PersistenceKit

@Suite
struct BigOCorrelationTests {
  /// Matches `QuickSort`'s real declared bounds — a mix of parseable pure-`n` shapes
  /// (`"O(n log n)"`) with one duplicated across two cases, exercising both the parse path and
  /// the "same shape, different label" overlap.
  private let quicksortComplexity = ComplexityBounds(
    best: "O(n log n)", average: "O(n log n)", worst: "O(n^2)"
  )

  private func makeInMemoryService() throws -> AnalyticsService {
    let schema = Schema([BigORecord.self])
    let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try ModelContainer(for: schema, configurations: [configuration])
    return AnalyticsService(modelContainer: container)
  }

  private func record(
    _ service: AnalyticsService, size: Int, total: Int,
    algorithmID: String = "quicksort", uniqueValueCount: Int? = nil
  ) async throws {
    let header = TapeHeader(
      algorithmID: algorithmID,
      initialValues: Array(repeating: 0, count: size),
      visualSeed: 0,
      compareCount: total,
      swapCount: 0,
      recordingDuration: 0,
      recordedAt: Date(),
      uniqueValueCount: uniqueValueCount
    )
    try await service.record(header, algorithmID: AlgorithmID(rawValue: algorithmID))
  }

  @Test
  func fewerThanTwoDistinctSizesYieldsNoPoints() async throws {
    let service = try makeInMemoryService()
    try await record(service, size: 10, total: 5)
    try await record(service, size: 10, total: 7)

    let summaries = try await service.fetchAllForTesting()
    #expect(bigOChartPoints(for: summaries, timeComplexity: quicksortComplexity).isEmpty)
  }

  @Test
  func averagesMultipleRunsAtTheSameSize() async throws {
    let service = try makeInMemoryService()
    try await record(service, size: 10, total: 4)
    try await record(service, size: 10, total: 6)
    try await record(service, size: 100, total: 100)

    let summaries = try await service.fetchAllForTesting()
    let points = bigOChartPoints(for: summaries, timeComplexity: quicksortComplexity)
    let trend = points.filter { $0.kind == .observedTrend }.sorted { $0.size < $1.size }

    #expect(trend.map(\.size) == [10, 100])
    // (4 + 6) / 2 = 5, normalized against the largest individual run (100) → 0.05.
    #expect(abs(trend[0].normalizedValue - 0.05) < 0.0001)
    #expect(abs(trend[1].normalizedValue - 1.0) < 0.0001)
  }

  @Test
  func everyReferenceSeriesReachesOneAtTheMaxSampledSize() async throws {
    let service = try makeInMemoryService()
    try await record(service, size: 10, total: 5)
    try await record(service, size: 500, total: 50)

    let summaries = try await service.fetchAllForTesting()
    let points = bigOChartPoints(for: summaries, timeComplexity: quicksortComplexity)
    let referenceSeries = Set(points.filter { $0.kind == .reference }.map(\.series))

    for name in referenceSeries {
      let pointsForSeries = points.filter { $0.kind == .reference && $0.series == name }
      let atMaxSize = pointsForSeries.max { $0.size < $1.size }
      #expect(atMaxSize != nil)
      #expect(abs((atMaxSize?.normalizedValue ?? -1) - 1.0) < 0.0001)
    }
  }

  /// The real-data anchor is the largest *individual run*, not the largest per-size average — a
  /// worst-case-shaped run at a smaller size should be able to outrank a later, larger, but
  /// unremarkable run instead of the chart being forced to always favor the rightmost size.
  @Test
  func aSmallerOutlierRunNormalizesHigherThanALaterLargerUnremarkableRun() async throws {
    let service = try makeInMemoryService()
    try await record(service, size: 40, total: 1000)
    try await record(service, size: 96, total: 200)
    try await record(service, size: 96, total: 220)

    let summaries = try await service.fetchAllForTesting()
    let points = bigOChartPoints(for: summaries, timeComplexity: quicksortComplexity)

    let outlierRun = points.first { $0.kind == .observedRun && $0.size == 40 }
    let laterTrend = points.first { $0.kind == .observedTrend && $0.size == 96 }

    #expect(outlierRun != nil)
    #expect(laterTrend != nil)
    #expect(abs((outlierRun?.normalizedValue ?? -1) - 1.0) < 0.0001)
    // (200 + 220) / 2 = 210, normalized against the outlier's 1000 → 0.21, well below 1.0.
    #expect(abs((laterTrend?.normalizedValue ?? -1) - 0.21) < 0.0001)
  }

  /// Radix sort's `O(d*n)`/`O(d*(n+b))` reference bounds `BigOShape.parse` can't touch on its
  /// own — `bigOChartPoints` still has to render a curve for them by resolving `d`/`b` from `n`.
  @Test
  func rendersReferenceCurvesForRadixSortsExtraVariables() async throws {
    let service = try makeInMemoryService()
    try await record(service, size: 10, total: 5, algorithmID: "msdradixsort")
    try await record(service, size: 1000, total: 50, algorithmID: "msdradixsort")

    let summaries = try await service.fetchSummaries(
      algorithmID: AlgorithmID(rawValue: "msdradixsort"))
    let complexity = ComplexityBounds(
      best: "O(d \\times n)", average: "O(d \\times n)", worst: "O(d \\times n)")
    let points = bigOChartPoints(for: summaries, timeComplexity: complexity)
    let referenceSeries = Set(points.filter { $0.kind == .reference }.map(\.series))

    // All three cases resolve to the same shape, so they merge into one labeled series
    // instead of three indistinguishable overlapping lines.
    #expect(referenceSeries == ["Best & Average & Worst Case"])
  }

  /// Bingo sort's `m` (unique value count) isn't a fixed function of `n` in this app — it has to
  /// come from `uniqueValueCount` samples on the actual recorded runs. A ratio well below 1.0
  /// should pull the mid-range curve down relative to the `m = n` assumption.
  @Test
  func bingoSortCurveReflectsRecordedUniqueValueRatio() async throws {
    let service = try makeInMemoryService()
    try await record(service, size: 10, total: 5, algorithmID: "bingosort", uniqueValueCount: 5)
    try await record(service, size: 100, total: 50, algorithmID: "bingosort", uniqueValueCount: 50)

    let summaries = try await service.fetchSummaries(
      algorithmID: AlgorithmID(rawValue: "bingosort"))
    let complexity = ComplexityBounds(
      best: "O(n+m^2)", average: "O(n \\times m)", worst: "O(n \\times m)")
    let points = bigOChartPoints(for: summaries, timeComplexity: complexity)
    // Average and Worst resolve to the same shape here, so they merge into one series.
    let averageCase = points.filter { $0.series == "Average & Worst Case" }.sorted {
      $0.size < $1.size
    }

    #expect(!averageCase.isEmpty)
    // With uniqueValueRatio == 0.5, "Average Case" is n*(0.5n) = 0.5n^2 — still a pure n^2 shape
    // once normalized to 1.0 at the max size, so it should match a plain O(n^2) curve exactly.
    let quadratic = BigOShape.polynomial(2)
    let maxSize = averageCase.map(\.size).max().map(Double.init) ?? 1
    let valueAtMax = quadratic.value(n: maxSize)
    for point in averageCase {
      let expected = quadratic.value(n: Double(point.size)) / valueAtMax
      #expect(abs(point.normalizedValue - expected) < 0.01)
    }
  }

  /// Older records predate `uniqueValueCount` entirely (`nil`, not a low number) — the resolver
  /// should fall back to the `m = n` assumption rather than treating a missing sample as `m = 0`.
  @Test
  func bingoSortFallsBackToMEqualsNWithoutRecordedUniqueValueCounts() async throws {
    let service = try makeInMemoryService()
    try await record(service, size: 10, total: 5, algorithmID: "bingosort")
    try await record(service, size: 100, total: 50, algorithmID: "bingosort")

    let summaries = try await service.fetchSummaries(
      algorithmID: AlgorithmID(rawValue: "bingosort"))
    let complexity = ComplexityBounds(
      best: "O(n+m^2)", average: "O(n \\times m)", worst: "O(n \\times m)")
    let points = bigOChartPoints(for: summaries, timeComplexity: complexity)
    let averageCase = points.filter { $0.series == "Average & Worst Case" }

    #expect(!averageCase.isEmpty)
  }

  /// Exercises the merge itself: `QuickSort`'s real declared bounds duplicate `"O(n log n)"`
  /// across best and average while worst differs, so those two should merge into one labeled
  /// series and worst should remain separate.
  @Test
  func mergesReferenceSeriesThatShareTheSameNormalizedShape() async throws {
    let service = try makeInMemoryService()
    try await record(service, size: 10, total: 5)
    try await record(service, size: 500, total: 50)

    let summaries = try await service.fetchAllForTesting()
    let points = bigOChartPoints(for: summaries, timeComplexity: quicksortComplexity)
    let referenceSeries = Set(points.filter { $0.kind == .reference }.map(\.series))

    #expect(referenceSeries == ["Best & Average Case", "Worst Case"])
  }

  /// When all three cases share the same shape, they should merge into a single series rather
  /// than three overlapping duplicates.
  @Test
  func mergesAllThreeReferenceSeriesWhenAllShareTheSameShape() async throws {
    let service = try makeInMemoryService()
    try await record(service, size: 10, total: 5, algorithmID: "msdradixsort")
    try await record(service, size: 1000, total: 50, algorithmID: "msdradixsort")

    let summaries = try await service.fetchSummaries(
      algorithmID: AlgorithmID(rawValue: "msdradixsort"))
    let complexity = ComplexityBounds(
      best: "O(d \\times n)", average: "O(d \\times n)", worst: "O(d \\times n)")
    let points = bigOChartPoints(for: summaries, timeComplexity: complexity)
    let referenceSeries = Set(points.filter { $0.kind == .reference }.map(\.series))

    #expect(referenceSeries == ["Best & Average & Worst Case"])
  }
}
