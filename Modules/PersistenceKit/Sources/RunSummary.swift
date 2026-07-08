import Foundation
import SwiftData

/// Replaces `Legacy/`'s `RunRecord` + `CloudKitRecordEncoder`/`Decoder` (§3.2 of
/// ARCHITECTURE_V2.md) — plain SwiftData, synced via `ModelConfiguration(cloudKitDatabase:
/// .automatic)` rather than a hand-rolled CloudKit encoder or `NSPersistentCloudKitContainer`.
///
/// Every property has a default value even though `AnalyticsService.record(...)` always supplies
/// real ones — CloudKit-backed SwiftData models require every attribute to have a default (or be
/// optional); a model without one fails to sync at runtime, not at compile time.
@Model
public final class RunSummary {
    public var algorithmID: String = ""
    public var arraySize: Int = 0
    public var compareCount: Int = 0
    public var swapCount: Int = 0
    public var recordingDuration: TimeInterval = 0
    public var deviceModel: String = ""
    public var recordedAt: Date = Date.distantPast
    public var speed: Double = 30.0

    public init(
        algorithmID: String,
        arraySize: Int,
        compareCount: Int,
        swapCount: Int,
        recordingDuration: TimeInterval,
        deviceModel: String,
        recordedAt: Date,
        speed: Double
    ) {
        self.algorithmID = algorithmID
        self.arraySize = arraySize
        self.compareCount = compareCount
        self.swapCount = swapCount
        self.recordingDuration = recordingDuration
        self.deviceModel = deviceModel
        self.recordedAt = recordedAt
        self.speed = speed
    }
}
