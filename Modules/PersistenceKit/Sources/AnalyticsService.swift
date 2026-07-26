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

  /// `playbackDuration`/`playbackSpeed` aren't on `TapeHeader` itself: `TapeHeader`/`Tape` are
  /// fully immutable, and playback duration isn't knowable until playback finishes, well after
  /// the header already exists. `SortSession.monitorTask` passes `replay.elapsedPlaybackDuration`/
  /// `replay.speed` straight through instead; both default to `nil` so a caller that only runs
  /// `RecordingEngine` (never `ReplayEngine`) needs no dummy values.
  public func record(
    _ header: TapeHeader, algorithmID: AlgorithmID,
    playbackDuration: TimeInterval? = nil, playbackSpeed: Double? = nil
  ) async throws {
    let summary = BigORecord(
      algorithmID: algorithmID.rawValue,
      arraySize: header.initialValues.count,
      compareCount: header.compareCount,
      swapCount: header.swapCount,
      mainWriteCount: header.mainWriteCount,
      auxWriteCount: header.auxWriteCount,
      reversalCount: header.reversalCount,
      recordedAt: header.recordedAt,
      uniqueValueCount: header.uniqueValueCount,
      recordingDuration: header.recordingDuration,
      playbackDuration: playbackDuration,
      playbackSpeed: playbackSpeed
    )
    modelContext.insert(summary)
    try modelContext.save()
  }

  /// Fired only from an automation/sweep run whose recording hit `RecordingEngine`'s operation
  /// cap — a manual run shows the skip reason directly in the UI instead. Deliberately
  /// write-only: no public fetch accessor exists for `RecordingCapExceededRecord`. These records
  /// exist purely so cap-tripping algorithm/size combinations can be reviewed later (across every
  /// device on the same iCloud account) and have their `sizeRange` adjusted by hand.
  public func recordCapExceeded(
    algorithmID: AlgorithmID, arraySize: Int, cap: Int,
    compareCount: Int, swapCount: Int, mainWriteCount: Int, auxWriteCount: Int
  ) async throws {
    let record = RecordingCapExceededRecord(
      algorithmID: algorithmID.rawValue,
      arraySize: arraySize,
      operationCap: cap,
      compareCount: compareCount,
      swapCount: swapCount,
      mainWriteCount: mainWriteCount,
      auxWriteCount: auxWriteCount,
      recordedAt: Date()
    )
    modelContext.insert(record)
    try modelContext.save()
  }

  /// Test-only: `ModelContext`/`BigORecord` aren't `Sendable`, so tests can't reach into
  /// `modelContext` directly from outside the actor without a concurrency error — this stays
  /// isolated and hands back plain `Sendable` values instead.
  func fetchAllForTesting() throws -> [BigORecordSnapshot] {
    try modelContext.fetch(FetchDescriptor<BigORecord>()).map(BigORecordSnapshot.init)
  }

  /// Test-only, same reasoning as `fetchAllForTesting()` above — `recordCapExceeded(...)` is
  /// otherwise write-only by design; nothing app-facing ever calls this.
  func fetchCapExceededForTesting() throws -> [RecordingCapExceededSnapshot] {
    try modelContext.fetch(FetchDescriptor<RecordingCapExceededRecord>()).map(
      RecordingCapExceededSnapshot.init)
  }

  /// Every recorded run for one algorithm, across every device that's ever completed a sort
  /// while signed into the same iCloud account — the real-world data `BigOCorrelation` charts
  /// against the classic Big-O reference curves. Sorted newest-first, matching the "most recent
  /// result first" convention the fetch already had before this data fed a chart.
  public func fetchSummaries(algorithmID: AlgorithmID) throws -> [BigORecordSnapshot] {
    let rawID = algorithmID.rawValue
    var descriptor = FetchDescriptor<BigORecord>(predicate: #Predicate { $0.algorithmID == rawID })
    descriptor.sortBy = [SortDescriptor(\.recordedAt, order: .reverse)]
    return try modelContext.fetch(descriptor).map(BigORecordSnapshot.init)
  }

  /// A broken schema/container should fail loudly at launch, not be swallowed — matches the
  /// "fail loudly on a mis-configured app" precedent already used elsewhere (e.g. `ContentView`'s
  /// `fatalError` for missing bundled algorithm resources).
  private static func makeDefaultContainer() -> ModelContainer {
    let schema = Schema([BigORecord.self, RecordingCapExceededRecord.self])
    let configuration = ModelConfiguration(schema: schema, cloudKitDatabase: .automatic)
    do {
      return try ModelContainer(for: schema, configurations: [configuration])
    } catch {
      fatalError("Failed to create default ModelContainer: \(error)")
    }
  }
}

public struct BigORecordSnapshot: Sendable, Equatable, Identifiable {
  public let algorithmID: String
  public let arraySize: Int
  public let compareCount: Int
  public let swapCount: Int
  public let mainWriteCount: Int
  public let auxWriteCount: Int
  public let reversalCount: Int
  public let recordedAt: Date
  public let uniqueValueCount: Int?
  public let recordingDuration: TimeInterval
  public let playbackDuration: TimeInterval?
  public let playbackSpeed: Double?

  public var id: String {
    "\(algorithmID)-\(arraySize)-\(recordedAt.timeIntervalSinceReferenceDate)-\(compareCount)"
  }

  init(_ summary: BigORecord) {
    algorithmID = summary.algorithmID
    arraySize = summary.arraySize
    compareCount = summary.compareCount
    swapCount = summary.swapCount
    mainWriteCount = summary.mainWriteCount
    auxWriteCount = summary.auxWriteCount
    reversalCount = summary.reversalCount
    recordedAt = summary.recordedAt
    uniqueValueCount = summary.uniqueValueCount
    recordingDuration = summary.recordingDuration
    playbackDuration = summary.playbackDuration
    playbackSpeed = summary.playbackSpeed
  }
}

/// Test-only counterpart to `BigORecordSnapshot` — `RecordingCapExceededRecord` itself isn't
/// `Sendable` (no SwiftData `@Model` class is), so `fetchCapExceededForTesting()` hands back this
/// instead of raw model instances.
struct RecordingCapExceededSnapshot: Sendable, Equatable {
  let algorithmID: String
  let arraySize: Int
  let operationCap: Int
  let compareCount: Int
  let swapCount: Int
  let mainWriteCount: Int
  let auxWriteCount: Int
  let recordedAt: Date

  init(_ record: RecordingCapExceededRecord) {
    algorithmID = record.algorithmID
    arraySize = record.arraySize
    operationCap = record.operationCap
    compareCount = record.compareCount
    swapCount = record.swapCount
    mainWriteCount = record.mainWriteCount
    auxWriteCount = record.auxWriteCount
    recordedAt = record.recordedAt
  }
}
