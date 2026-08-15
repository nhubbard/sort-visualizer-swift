import AlgorithmKit
import Foundation
import SortEngineKit
import SwiftData
import os

/// `SortSession` calls `record(...)` after `phase` transitions to `.complete` — never from inside
/// recording or replay, so the engine has zero knowledge that analytics exist at all (§3.2).
///
/// Plain SwiftData sync, not `NSPersistentCloudKitContainer` — `ModelConfiguration`'s own
/// `cloudKitDatabase: .automatic` uses whichever CloudKit container the entitlements declare
/// (`iCloud.com.nhubbard.Sort2.mobile`) with no manual container/encoder code at all.
public actor AnalyticsService {
  public static let shared = AnalyticsService()

  private let modelContext: ModelContext

  /// `fetchSummaries(algorithmID:)` results, keyed by `algorithmID.rawValue` — invalidated in
  /// `record(...)` for the one algorithm a given call could actually affect. Exists because
  /// `BigOCorrelationChart`'s `.task(id: algorithm.id)` looks like it should only refetch when the
  /// algorithm changes, but the view it lives in fully remounts (fresh `@State`) on every Full
  /// Sweep combo — not just every algorithm change — so without this cache, the exact same query
  /// re-ran against SwiftData once per combo regardless of whether the algorithm was unchanged.
  private var summariesCache: [String: [BigORecordSnapshot]] = [:]

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
    summariesCache[algorithmID.rawValue] = nil
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
  ///
  /// Cached (see `summariesCache`'s own doc comment for why): `BigOCorrelationChart`'s view
  /// remounts on every Full Sweep combo, not just every algorithm change, so without this a query
  /// that looked like it should only run once per algorithm ran once per combo instead.
  public func fetchSummaries(algorithmID: AlgorithmID) throws -> [BigORecordSnapshot] {
    let rawID = algorithmID.rawValue
    if let cached = summariesCache[rawID] { return cached }
    var descriptor = FetchDescriptor<BigORecord>(predicate: #Predicate { $0.algorithmID == rawID })
    descriptor.sortBy = [SortDescriptor(\.recordedAt, order: .reverse)]
    let result = try modelContext.fetch(descriptor).map(BigORecordSnapshot.init)
    summariesCache[rawID] = result
    return result
  }

  private static let logger = Logger(subsystem: "com.nhubbard.Sort2.mobile", category: "AnalyticsService")

  /// A genuinely broken schema/container should fail loudly at launch — but a denied or
  /// unavailable CloudKit account is a normal, expected condition, not a bug: setting up the
  /// CloudKit-backed configuration's XPC connection triggers macOS's "would like to access data
  /// from other apps" prompt, and a user is entirely within their rights to decline it (no iCloud
  /// account signed in, an enterprise/managed Mac with CloudKit restricted, etc.). Declining used
  /// to `fatalError` here, crashing the app on the very first sort of every subsequent launch —
  /// real user-reported crash, root-caused via a breakpoint on this file. Falls back to a
  /// local-only configuration instead; only `fatalError`s if *that* also fails, which really would
  /// indicate a broken schema (matches the "fail loudly on a mis-configured app" precedent already
  /// used elsewhere, e.g. `ContentView`'s `fatalError` for missing bundled algorithm resources).
  /// The one real cost: `BigOCorrelation`'s "across every device signed into the same iCloud
  /// account" promise quietly becomes "this device only" for as long as CloudKit stays denied —
  /// existing local records aren't lost, and nothing here changes behavior once access is granted.
  private static func makeDefaultContainer() -> ModelContainer {
    let schema = Schema([BigORecord.self, RecordingCapExceededRecord.self])
    return makeContainer(
      schema: schema,
      primary: ModelConfiguration(schema: schema, cloudKitDatabase: .automatic),
      fallback: ModelConfiguration(schema: schema, cloudKitDatabase: .none)
    )
  }

  /// Test seam for the fallback control flow above — real CloudKit account/permission state can't
  /// be simulated in a unit test, but "the primary configuration throws, fall back to the second"
  /// can be exercised directly by handing this an intentionally-unusable `primary` (e.g. a store
  /// URL under a directory that doesn't exist) alongside a real, working `fallback`.
  static func makeContainer(
    schema: Schema, primary: ModelConfiguration, fallback: ModelConfiguration
  ) -> ModelContainer {
    do {
      return try ModelContainer(for: schema, configurations: [primary])
    } catch {
      logger.error(
        "Primary ModelContainer configuration failed, falling back to local-only: \(error, privacy: .public)"
      )
      do {
        return try ModelContainer(for: schema, configurations: [fallback])
      } catch {
        fatalError("Failed to create even a local-only fallback ModelContainer: \(error)")
      }
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
