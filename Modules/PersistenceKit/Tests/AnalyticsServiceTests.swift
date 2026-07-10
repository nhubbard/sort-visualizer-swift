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
        let schema = Schema([BigORecord.self])
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

    /// `BenchmarkFeature`'s `BigOCorrelationChart` relies on this filtering to one algorithm and
    /// sorting newest-first — both are asserted directly here rather than only indirectly through
    /// a UI test.
    @Test
    func fetchSummariesFiltersByAlgorithmAndSortsNewestFirst() async throws {
        let service = try makeInMemoryService()
        let older = Date(timeIntervalSince1970: 1000)
        let newer = Date(timeIntervalSince1970: 2000)

        for (algorithmID, recordedAt) in [("quicksort", older), ("quicksort", newer), ("gnomesort", newer)] {
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

        let quickSortRows = try await service.fetchSummaries(algorithmID: AlgorithmID(rawValue: "quicksort"))
        #expect(quickSortRows.count == 2)
        #expect(quickSortRows.map(\.recordedAt) == [newer, older])
        #expect(quickSortRows.allSatisfy { $0.algorithmID == "quicksort" })
    }
}
