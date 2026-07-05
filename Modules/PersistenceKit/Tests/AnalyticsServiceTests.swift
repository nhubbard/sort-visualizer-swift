import AlgorithmKit
import Foundation
import SortEngineKit
import Testing
@testable import PersistenceKit

@Suite
struct AnalyticsServiceTests {
    @Test
    func recordNeverThrowsEvenThoughItDoesNothingYet() async throws {
        let service = AnalyticsService()
        let header = TapeHeader(
            algorithmID: "quicksort",
            initialValues: [3, 1, 2],
            visualSeed: 0,
            compareCount: 1,
            swapCount: 1,
            recordingDuration: 0,
            recordedAt: Date()
        )
        try await service.record(header, algorithmID: AlgorithmID(rawValue: "quicksort"))
    }
}
