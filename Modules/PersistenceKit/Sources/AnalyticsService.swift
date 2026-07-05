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

    public func record(_ header: TapeHeader, algorithmID: AlgorithmID) async throws {
        let device = DeviceInfoProvider.current()
        let summary = RunSummary(
            algorithmID: algorithmID.rawValue,
            arraySize: header.initialValues.count,
            compareCount: header.compareCount,
            swapCount: header.swapCount,
            recordingDuration: header.recordingDuration,
            deviceModel: device.model,
            recordedAt: header.recordedAt
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

    /// A broken schema/container should fail loudly at launch, not be swallowed — matches the
    /// "fail loudly on a mis-configured app" precedent already used elsewhere (e.g. `ContentView`'s
    /// `fatalError` for missing bundled algorithm resources).
    private static func makeDefaultContainer() -> ModelContainer {
        let schema = Schema([RunSummary.self])
        let configuration = ModelConfiguration(schema: schema, cloudKitDatabase: .automatic)
        return try! ModelContainer(for: schema, configurations: [configuration])
    }
}

struct RunSummarySnapshot: Sendable, Equatable {
    let algorithmID: String
    let arraySize: Int
    let compareCount: Int
    let swapCount: Int
    let recordingDuration: TimeInterval
    let deviceModel: String
    let recordedAt: Date

    init(_ summary: RunSummary) {
        algorithmID = summary.algorithmID
        arraySize = summary.arraySize
        compareCount = summary.compareCount
        swapCount = summary.swapCount
        recordingDuration = summary.recordingDuration
        deviceModel = summary.deviceModel
        recordedAt = summary.recordedAt
    }
}
