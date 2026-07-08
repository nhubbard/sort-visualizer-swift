import AlgorithmKit
import Foundation
import SortEngineKit
import SwiftData

/// `SortSession` calls `record(...)` after `phase` transitions to `.complete` — never from inside
/// recording or replay, so the engine has zero knowledge that analytics exist at all (§3.2).
///
/// Plain SwiftData sync, not `NSPersistentCloudKitContainer` — `ModelConfiguration`'s own
/// `cloudKitDatabase: .automatic` uses whichever CloudKit container the entitlements declare
/// (`iCloud.com.nhubbard.Sort2.mobile`) with no manual container/encoder code at all.
public actor AnalyticsService {
    public static let shared = AnalyticsService()

    private let modelContext: ModelContext

    /// Tests inject an `isStoredInMemoryOnly: true` container instead of touching CloudKit/disk —
    /// the real app never passes this parameter, so it always gets the CloudKit-backed default.
    public init(modelContainer: ModelContainer? = nil) {
        self.modelContext = ModelContext(modelContainer ?? Self.makeDefaultContainer())
    }

    public func record(_ header: TapeHeader, algorithmID: AlgorithmID, speed: Double = 30.0) async throws {
        let device = DeviceInfoProvider.current()
        let summary = RunSummary(
            algorithmID: algorithmID.rawValue,
            arraySize: header.initialValues.count,
            compareCount: header.compareCount,
            swapCount: header.swapCount,
            recordingDuration: header.recordingDuration,
            deviceModel: device.model,
            recordedAt: header.recordedAt,
            speed: speed
        )
        modelContext.insert(summary)
        try modelContext.save()
    }

    /// Test-only: `ModelContext`/`RunSummary` aren't `Sendable`, so tests can't reach into
    /// `modelContext` directly from outside the actor without a concurrency error — this stays
    /// isolated and hands back plain `Sendable` values instead.
    func fetchAllForTesting() throws -> [RunSummarySnapshot] {
        try modelContext.fetch(FetchDescriptor<RunSummary>()).map(RunSummarySnapshot.init)
    }

    /// `BenchmarkFeature`'s `DeviceComparisonView` — every recorded run for one algorithm, across
    /// every device that's ever completed a sort while signed into the same iCloud account (§9 of
    /// ARCHITECTURE_V2.md: this is the entire reason `AnalyticsService` tags rows by device at
    /// all). Sorted newest-first so a device that's run the algorithm many times shows its most
    /// recent result first.
    public func fetchSummaries(algorithmID: AlgorithmID) throws -> [RunSummarySnapshot] {
        let rawID = algorithmID.rawValue
        var descriptor = FetchDescriptor<RunSummary>(predicate: #Predicate { $0.algorithmID == rawID })
        descriptor.sortBy = [SortDescriptor(\.recordedAt, order: .reverse)]
        return try modelContext.fetch(descriptor).map(RunSummarySnapshot.init)
    }

    /// A broken schema/container should fail loudly at launch, not be swallowed — matches the
    /// "fail loudly on a mis-configured app" precedent already used elsewhere (e.g. `ContentView`'s
    /// `fatalError` for missing bundled algorithm resources).
    private static func makeDefaultContainer() -> ModelContainer {
        let schema = Schema([RunSummary.self])
        let configuration = ModelConfiguration(schema: schema, cloudKitDatabase: .automatic)
        return try! ModelContainer(for: schema, configurations: [configuration])
    }
}

public struct RunSummarySnapshot: Sendable, Equatable, Identifiable {
    public let algorithmID: String
    public let arraySize: Int
    public let compareCount: Int
    public let swapCount: Int
    public let recordingDuration: TimeInterval
    public let deviceModel: String
    public let recordedAt: Date
    public let speed: Double

    public var id: String { "\(deviceModel)-\(recordedAt.timeIntervalSinceReferenceDate)" }

    init(_ summary: RunSummary) {
        algorithmID = summary.algorithmID
        arraySize = summary.arraySize
        compareCount = summary.compareCount
        swapCount = summary.swapCount
        recordingDuration = summary.recordingDuration
        deviceModel = summary.deviceModel
        recordedAt = summary.recordedAt
        speed = summary.speed
    }
}
