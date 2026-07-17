import Foundation
import SwiftData

/// A write-only diagnostic record: whenever an automation/sweep run's recording hits
/// `RecordingEngine`'s operation cap, `AnalyticsService.recordCapExceeded(...)` inserts one of
/// these instead of showing anything in the app (automation silently moves on to the next size —
/// see `SortSession.start(size:)`). The point is for the developer to review these later, across
/// every device signed into the same iCloud account, and decide whether to narrow that
/// algorithm's `sizeRange` or fix the algorithm itself — same CloudKit-backed `ModelConfiguration
/// (cloudKitDatabase: .automatic)` sync as `BigORecord`, just a second record type in the same
/// container/schema. Deliberately has no `fetchSummaries`-style public accessor (unlike
/// `BigORecord`) — nothing in the app ever reads this back.
///
/// Every property has a default even though `AnalyticsService.recordCapExceeded(...)` always
/// supplies real ones — CloudKit-backed SwiftData models require every attribute to have a
/// default (or be optional); a model without one fails to sync at runtime, not at compile time.
@Model
public final class RecordingCapExceededRecord {
  public var algorithmID: String = ""
  public var arraySize: Int = 0
  public var operationCap: Int = 0
  public var compareCount: Int = 0
  public var swapCount: Int = 0
  public var mainWriteCount: Int = 0
  public var auxWriteCount: Int = 0
  public var recordedAt: Date = Date.distantPast

  public init(
    algorithmID: String,
    arraySize: Int,
    operationCap: Int,
    compareCount: Int,
    swapCount: Int,
    mainWriteCount: Int,
    auxWriteCount: Int,
    recordedAt: Date
  ) {
    self.algorithmID = algorithmID
    self.arraySize = arraySize
    self.operationCap = operationCap
    self.compareCount = compareCount
    self.swapCount = swapCount
    self.mainWriteCount = mainWriteCount
    self.auxWriteCount = auxWriteCount
    self.recordedAt = recordedAt
  }
}
