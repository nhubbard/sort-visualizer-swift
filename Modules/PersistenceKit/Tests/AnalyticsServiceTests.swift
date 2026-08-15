import AlgorithmKit
import Foundation
import SortEngineKit
import SwiftData
import Testing

@testable import PersistenceKit

@Suite
struct AnalyticsServiceTests {
  /// Isolated, in-memory, non-CloudKit container per test — never touches the real disk or
  /// account-bound CloudKit database that `AnalyticsService.shared`'s default container would.
  private func makeInMemoryService() throws -> AnalyticsService {
    let schema = Schema([BigORecord.self, RecordingCapExceededRecord.self])
    let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try ModelContainer(for: schema, configurations: [configuration])
    return AnalyticsService(modelContainer: container)
  }

  @Test
  func recordInsertsAFetchableBigORecordWithTheExpectedFields() async throws {
    let service = try makeInMemoryService()
    let recordedAt = Date()
    let header = TapeHeader(
      algorithmID: "quicksort",
      initialValues: [3, 1, 2],
      visualSeed: 0,
      compareCount: 7,
      swapCount: 4,
      mainWriteCount: 8,
      auxWriteCount: 2,
      reversalCount: 1,
      recordingDuration: 0.042,
      recordedAt: recordedAt
    )

    try await service.record(header, algorithmID: AlgorithmID(rawValue: "quicksort"))

    let rows = try await service.fetchAllForTesting()
    #expect(rows.count == 1)

    let row = rows[0]
    #expect(row.algorithmID == "quicksort")
    #expect(row.arraySize == 3)
    #expect(row.compareCount == 7)
    #expect(row.swapCount == 4)
    #expect(row.mainWriteCount == 8)
    #expect(row.auxWriteCount == 2)
    #expect(row.reversalCount == 1)
    #expect(row.recordedAt == recordedAt)
    #expect(row.uniqueValueCount == nil)
    // `header.recordingDuration` (0.042, set above) — this specific assertion is what would
    // have caught `record(_:algorithmID:)` silently dropping it before it was wired through.
    #expect(row.recordingDuration == 0.042)
    // Neither supplied to this call — `record`'s two playback params both default to `nil`.
    #expect(row.playbackDuration == nil)
    #expect(row.playbackSpeed == nil)
  }

  /// `SortSession`'s `monitorTask` supplies these from `replay.elapsedPlaybackDuration`/
  /// `replay.speed` at the exact moment it observes genuine completion — a plain round-trip
  /// check that `record`/`fetchAllForTesting` carry both through unchanged, mirroring
  /// `recordCarriesThroughUniqueValueCountWhenPresent` below.
  @Test
  func recordCarriesThroughPlaybackDurationAndSpeedWhenPresent() async throws {
    let service = try makeInMemoryService()
    let header = TapeHeader(
      algorithmID: "bitonicsortiterative",
      initialValues: [1, 2, 3, 4],
      visualSeed: 0,
      compareCount: 3,
      swapCount: 2,
      recordingDuration: 0.003,
      recordedAt: Date()
    )

    try await service.record(
      header, algorithmID: AlgorithmID(rawValue: "bitonicsortiterative"),
      playbackDuration: 12.5, playbackSpeed: 30.0
    )

    let rows = try await service.fetchAllForTesting()
    #expect(rows.count == 1)
    #expect(rows[0].playbackDuration == 12.5)
    #expect(rows[0].playbackSpeed == 30.0)
  }

  /// `SortSession.makeTape` measures this from the post-shuffle array before the sort runs — a
  /// plain round-trip check that `record`/`fetchAllForTesting` carry it through unchanged.
  @Test
  func recordCarriesThroughUniqueValueCountWhenPresent() async throws {
    let service = try makeInMemoryService()
    let header = TapeHeader(
      algorithmID: "bingosort",
      initialValues: [1, 2, 3, 4],
      visualSeed: 0,
      compareCount: 3,
      swapCount: 2,
      recordingDuration: 0,
      recordedAt: Date(),
      uniqueValueCount: 3
    )

    try await service.record(header, algorithmID: AlgorithmID(rawValue: "bingosort"))

    let rows = try await service.fetchAllForTesting()
    #expect(rows.count == 1)
    #expect(rows[0].uniqueValueCount == 3)
  }

  @Test
  func recordingMultipleRunsAccumulatesRatherThanOverwriting() async throws {
    let service = try makeInMemoryService()

    for algorithmID in ["quicksort", "gnomesort", "bogosort"] {
      let header = TapeHeader(
        algorithmID: algorithmID,
        initialValues: [1, 2, 3],
        visualSeed: 0,
        compareCount: 1,
        swapCount: 1,
        recordingDuration: 0,
        recordedAt: Date()
      )
      try await service.record(header, algorithmID: AlgorithmID(rawValue: algorithmID))
    }

    let rows = try await service.fetchAllForTesting()
    #expect(rows.count == 3)
  }

  /// `BigOCorrelationChart` relies on this filtering to one algorithm and sorting newest-first —
  /// both are asserted directly here rather than only indirectly through a UI test.
  @Test
  func fetchSummariesFiltersByAlgorithmAndSortsNewestFirst() async throws {
    let service = try makeInMemoryService()
    let older = Date(timeIntervalSince1970: 1000)
    let newer = Date(timeIntervalSince1970: 2000)

    for (algorithmID, recordedAt) in [
      ("quicksort", older), ("quicksort", newer), ("gnomesort", newer)
    ] {
      let header = TapeHeader(
        algorithmID: algorithmID,
        initialValues: [1, 2, 3],
        visualSeed: 0,
        compareCount: 1,
        swapCount: 1,
        recordingDuration: 0,
        recordedAt: recordedAt
      )
      try await service.record(header, algorithmID: AlgorithmID(rawValue: algorithmID))
    }

    let quickSortRows = try await service.fetchSummaries(
      algorithmID: AlgorithmID(rawValue: "quicksort"))
    #expect(quickSortRows.count == 2)
    #expect(quickSortRows.map(\.recordedAt) == [newer, older])
    #expect(quickSortRows.allSatisfy { $0.algorithmID == "quicksort" })
  }

  /// Regression guard for the Full Sweep finding: `fetchSummaries` is now cached per algorithm ID
  /// (`BigOCorrelationChart`'s view remounts every combo, not just every algorithm change, so an
  /// uncached fetch re-ran once per combo). The cache must not go stale — a `record(...)` call for
  /// the *same* algorithm has to be reflected on the very next `fetchSummaries` call, not just
  /// eventually. A different algorithm's cached entry must be left alone.
  @Test
  func fetchSummariesCacheInvalidatesOnlyForTheAlgorithmJustRecorded() async throws {
    let service = try makeInMemoryService()
    let header = TapeHeader(
      algorithmID: "quicksort", initialValues: [1, 2, 3], visualSeed: 0, compareCount: 1,
      swapCount: 1, recordingDuration: 0, recordedAt: Date(timeIntervalSince1970: 1000))
    try await service.record(header, algorithmID: AlgorithmID(rawValue: "quicksort"))
    try await service.record(
      TapeHeader(
        algorithmID: "gnomesort", initialValues: [1, 2, 3], visualSeed: 0, compareCount: 1,
        swapCount: 1, recordingDuration: 0, recordedAt: Date(timeIntervalSince1970: 1000)),
      algorithmID: AlgorithmID(rawValue: "gnomesort"))

    // Populates the cache for both algorithms.
    #expect(try await service.fetchSummaries(algorithmID: AlgorithmID(rawValue: "quicksort")).count == 1)
    #expect(try await service.fetchSummaries(algorithmID: AlgorithmID(rawValue: "gnomesort")).count == 1)

    // A second recorded quicksort run must show up immediately, not on some later fetch.
    try await service.record(
      TapeHeader(
        algorithmID: "quicksort", initialValues: [1, 2, 3], visualSeed: 0, compareCount: 1,
        swapCount: 1, recordingDuration: 0, recordedAt: Date(timeIntervalSince1970: 2000)),
      algorithmID: AlgorithmID(rawValue: "quicksort"))

    #expect(try await service.fetchSummaries(algorithmID: AlgorithmID(rawValue: "quicksort")).count == 2)
    // gnomesort's own cached entry was untouched by quicksort's write.
    #expect(try await service.fetchSummaries(algorithmID: AlgorithmID(rawValue: "gnomesort")).count == 1)
  }

  /// `recordCapExceeded` is deliberately write-only in the app (no public fetch), but a plain
  /// round-trip against the internal, test-only `fetchCapExceededForTesting()` is still the
  /// right way to prove the insert actually carries every field through correctly.
  @Test
  func recordCapExceededInsertsAFetchableRecordWithTheExpectedFields() async throws {
    let service = try makeInMemoryService()

    try await service.recordCapExceeded(
      algorithmID: AlgorithmID(rawValue: "snufflesort"), arraySize: 64, cap: 300_000,
      compareCount: 3_400_000, swapCount: 1_200_000, mainWriteCount: 2_400_000, auxWriteCount: 0
    )

    let rows = try await service.fetchCapExceededForTesting()
    #expect(rows.count == 1)
    let row = rows[0]
    #expect(row.algorithmID == "snufflesort")
    #expect(row.arraySize == 64)
    #expect(row.operationCap == 300_000)
    #expect(row.compareCount == 3_400_000)
    #expect(row.swapCount == 1_200_000)
    #expect(row.mainWriteCount == 2_400_000)
    #expect(row.auxWriteCount == 0)
  }

  /// Regression guard for a real crash: `makeDefaultContainer()` used to `fatalError` whenever its
  /// CloudKit-backed configuration failed to construct — including the entirely routine case of a
  /// user declining the "access data from other apps" prompt CloudKit's XPC setup triggers, or
  /// having no iCloud account signed in at all. Real CloudKit/TCC state can't be simulated in a
  /// unit test, but the fallback control flow itself can: an intentionally-unusable `primary`
  /// configuration (a store URL under a directory that doesn't exist) stands in for "CloudKit
  /// unavailable," and this asserts `makeContainer` falls back to `fallback` instead of crashing.
  @Test
  func makeContainerFallsBackToTheSecondConfigurationWhenThePrimaryFails() async throws {
    let schema = Schema([BigORecord.self, RecordingCapExceededRecord.self])
    let brokenPrimary = ModelConfiguration(
      schema: schema,
      url: URL(fileURLWithPath: "/nonexistent-\(UUID().uuidString)/db.sqlite"))
    let workingFallback = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)

    let container = AnalyticsService.makeContainer(
      schema: schema, primary: brokenPrimary, fallback: workingFallback)

    // Proves the returned container is genuinely the (working) fallback, not just a non-nil
    // value — the same round-trip `recordInsertsAFetchableBigORecordWithTheExpectedFields` uses.
    let service = AnalyticsService(modelContainer: container)
    let header = TapeHeader(
      algorithmID: "quicksort", initialValues: [3, 1, 2], visualSeed: 0, compareCount: 1,
      swapCount: 1, recordingDuration: 0, recordedAt: Date())
    try await service.record(header, algorithmID: AlgorithmID(rawValue: "quicksort"))
    let rows = try await service.fetchAllForTesting()
    #expect(rows.count == 1)
  }

  @Test
  func recordCapExceededAccumulatesRatherThanOverwriting() async throws {
    let service = try makeInMemoryService()

    for size in [16, 32, 64] {
      try await service.recordCapExceeded(
        algorithmID: AlgorithmID(rawValue: "snufflesort"), arraySize: size, cap: 300_000,
        compareCount: 0, swapCount: 0, mainWriteCount: 0, auxWriteCount: 0
      )
    }

    let rows = try await service.fetchCapExceededForTesting()
    #expect(rows.count == 3)
  }
}
