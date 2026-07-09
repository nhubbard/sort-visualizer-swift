import AlgorithmKit
import Foundation
import SortEngineKit
import SwiftData
import Testing
@testable import PersistenceKit

@Suite
struct BigOCorrelationTests {
    private func makeInMemoryService() throws -> AnalyticsService {
        let schema = Schema([BigORecord.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        return AnalyticsService(modelContainer: container)
    }

    private func record(_ service: AnalyticsService, size: Int, total: Int) async throws {
        let header = TapeHeader(
            algorithmID: "quicksort",
            initialValues: Array(repeating: 0, count: size),
            visualSeed: 0,
            compareCount: total,
            swapCount: 0,
            recordingDuration: 0,
            recordedAt: Date()
        )
        try await service.record(header, algorithmID: AlgorithmID(rawValue: "quicksort"))
    }

    @Test
    func fewerThanTwoDistinctSizesYieldsNoPoints() async throws {
        let service = try makeInMemoryService()
        try await record(service, size: 10, total: 5)
        try await record(service, size: 10, total: 7)

        let summaries = try await service.fetchAllForTesting()
        #expect(bigOChartPoints(for: summaries).isEmpty)
    }

    @Test
    func averagesMultipleRunsAtTheSameSize() async throws {
        let service = try makeInMemoryService()
        try await record(service, size: 10, total: 4)
        try await record(service, size: 10, total: 6)
        try await record(service, size: 100, total: 100)

        let summaries = try await service.fetchAllForTesting()
        let points = bigOChartPoints(for: summaries)
        let observed = points.filter(\.isObserved).sorted { $0.size < $1.size }

        #expect(observed.map(\.size) == [10, 100])
        // (4 + 6) / 2 = 5, normalized against the max bucket (100) → 0.05.
        #expect(abs(observed[0].normalizedValue - 0.05) < 0.0001)
        #expect(abs(observed[1].normalizedValue - 1.0) < 0.0001)
    }

    @Test
    func everySeriesReachesOneAtTheMaxObservedSize() async throws {
        let service = try makeInMemoryService()
        try await record(service, size: 10, total: 5)
        try await record(service, size: 500, total: 50)

        let summaries = try await service.fetchAllForTesting()
        let points = bigOChartPoints(for: summaries)
        let series = Set(points.map(\.series))

        for name in series {
            let pointsForSeries = points.filter { $0.series == name }
            let atMaxSize = pointsForSeries.max { $0.size < $1.size }
            #expect(atMaxSize != nil)
            #expect(abs((atMaxSize?.normalizedValue ?? -1) - 1.0) < 0.0001)
        }
    }
}
