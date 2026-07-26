import Foundation
import SwiftData

/// Replaces `Legacy/`'s `RunRecord` + `CloudKitRecordEncoder`/`Decoder` — plain SwiftData, synced
/// via `ModelConfiguration(cloudKitDatabase: .automatic)` rather than a hand-rolled CloudKit
/// encoder or `NSPersistentCloudKitContainer`.
///
/// Records the same ArrayV-style operation counters `TapeHeader` already tracks per run, so
/// growth against the classic Big-O reference curves (`BigOCorrelation.bigOChartPoints`) can be
/// charted across every device signed into the same iCloud account — not for comparing device
/// speed, since `speed` is now a fixed pacing target the user dials in, not a device measurement.
///
/// `recordingDuration`/`playbackDuration`/`playbackSpeed` capture the "algorithm is fast but
/// watching it is slow" gap on a single run/device; `playbackSpeed` is stored alongside
/// `playbackDuration` so a reader knows what pacing target that duration was measured against.
///
/// Every property has a default value even though `AnalyticsService.record(...)` always supplies
/// real ones — CloudKit-backed SwiftData models require every attribute to have a default (or be
/// optional); a model without one fails to sync at runtime, not at compile time.
@Model
public final class BigORecord {
  public var algorithmID: String = ""
  public var arraySize: Int = 0
  public var compareCount: Int = 0
  public var swapCount: Int = 0
  public var mainWriteCount: Int = 0
  public var auxWriteCount: Int = 0
  public var reversalCount: Int = 0
  public var recordedAt: Date = Date.distantPast
  /// Distinct value count right after the shuffle, before the sort ran (`TapeHeader.uniqueValueCount`)
  /// — nullable because records written before this field existed predate it, not because a real
  /// run can't measure it. `BigOCorrelation` uses this to estimate Bingo sort's `m`, the one
  /// declared-complexity variable that isn't a fixed function of `n` in this app.
  public var uniqueValueCount: Int?
  /// Wall-clock time to record the sort itself (`TapeHeader.recordingDuration`) — always present
  /// going forward, `0` only for rows synced from before this field existed (an honest "not
  /// measured" sentinel, matching `arraySize`'s own placeholder-default convention in this file,
  /// not a real zero-duration run).
  public var recordingDuration: TimeInterval = 0
  /// Active wall-clock time spent actually playing this run back (`ReplayEngine
  /// .elapsedPlaybackDuration` at genuine completion — excludes any time spent paused). `nil`
  /// for rows from before this field existed, or for a run that never reached genuine completion
  /// (crash, force-quit mid-replay) — not recorded in either case, not a real zero.
  public var playbackDuration: TimeInterval?
  /// The `ReplayEngine.speed` (operations/second) actually in effect while `playbackDuration` was
  /// measured — `nil` in exactly the same cases `playbackDuration` is, since a duration alone
  /// doesn't say how much work that pacing target was asked to get through.
  public var playbackSpeed: Double?

  public init(
    algorithmID: String,
    arraySize: Int,
    compareCount: Int,
    swapCount: Int,
    mainWriteCount: Int,
    auxWriteCount: Int,
    reversalCount: Int,
    recordedAt: Date,
    uniqueValueCount: Int? = nil,
    recordingDuration: TimeInterval = 0,
    playbackDuration: TimeInterval? = nil,
    playbackSpeed: Double? = nil
  ) {
    self.algorithmID = algorithmID
    self.arraySize = arraySize
    self.compareCount = compareCount
    self.swapCount = swapCount
    self.mainWriteCount = mainWriteCount
    self.auxWriteCount = auxWriteCount
    self.reversalCount = reversalCount
    self.recordedAt = recordedAt
    self.uniqueValueCount = uniqueValueCount
    self.recordingDuration = recordingDuration
    self.playbackDuration = playbackDuration
    self.playbackSpeed = playbackSpeed
  }
}
