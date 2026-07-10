import Foundation
import SwiftData

/// Replaces `Legacy/`'s `RunRecord` + `CloudKitRecordEncoder`/`Decoder` (§3.2 of
/// ARCHITECTURE_V2.md) — plain SwiftData, synced via `ModelConfiguration(cloudKitDatabase:
/// .automatic)` rather than a hand-rolled CloudKit encoder or `NSPersistentCloudKitContainer`.
///
/// Records the same ArrayV-style operation counters `TapeHeader` already tracks per run — the
/// point of collecting these across every device signed into the same iCloud account is charting
/// how they actually grow with array size against the classic Big-O reference curves
/// (`BigOCorrelation.bigOChartPoints`), not comparing device speed (a prior revision recorded
/// `deviceModel`/`speed`/`recordingDuration` for that; playback speed no longer reflects device
/// performance since the replay engine was reworked).
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

    public init(
        algorithmID: String,
        arraySize: Int,
        compareCount: Int,
        swapCount: Int,
        mainWriteCount: Int,
        auxWriteCount: Int,
        reversalCount: Int,
        recordedAt: Date,
        uniqueValueCount: Int? = nil
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
    }
}
