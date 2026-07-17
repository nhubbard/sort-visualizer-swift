/// A plain, synchronous, `mutating`-method struct — no actor, no `async`, no `@MainActor`. This is
/// the *only* interface an algorithm ever touches. `compare`/`swap` auto-apply
/// `Marker.primary`/`.secondary` (matching ArrayV's `Reads.compareIndices`/`Writes.swap`
/// convention of always marking what they touch), and auto-*retract* the previous call's marks
/// first — so at most one index carries `.primary` and one carries `.secondary` at a time, a
/// "what's happening right now" highlight rather than a permanent stain (§ colors: a `Visualizer`
/// falls back to its own base/value color for every unmarked index, so without retraction, every
/// index a sort has ever touched stays highlighted forever instead of reverting once the operation
/// moves on). Everything past primary/secondary — `pivot`, `bucket(n)`, custom markers — is the
/// algorithm's own choice, held across as many operations as it likes.
///
/// A synchronous function cannot be cancelled mid-loop-body anyway, so there is no
/// `enforceRunning()`-style guard anywhere here — cancellation is a `ReplayEngine` concern.
public struct RecordingEngine: Sendable {
  /// 5 minutes at the app's own 1000 ops/sec max playback speed (`SettingsView`'s speed slider
  /// tops out there) — the fallback used when a caller doesn't pass its own `operationCap`.
  /// `SortSession` always passes the live, user-tunable `AppSettings.recordingOperationCap`
  /// instead, so this constant in practice only matters to callers (tests, previews) that
  /// construct a `RecordingEngine` directly.
  public static let defaultOperationCap = 300_000

  public private(set) var values: [Int]
  private var tape: [SortOperation] = []
  private let operationCap: Int
  /// Set once `tape.count` reaches `operationCap` — from that point on, `compare`/`swap`/etc.
  /// keep doing real work on `values` (so the algorithm still runs to genuine, correct
  /// completion) but stop growing `tape`, capping this run's RAM footprint and guaranteeing
  /// `finish()`'s tape is never larger than `operationCap`. Callers use this to decide whether
  /// to skip the run entirely rather than building a `Tape`/`ReplayEngine` from a truncated one.
  public private(set) var didExceedCap = false
  private var compareCount = 0
  private var swapCount = 0
  private var mainWriteCount = 0
  private var auxWriteCount = 0
  private var reversalCount = 0
  private var nextAuxHandle = 0
  private var primaryIndex: Int?
  private var secondaryIndex: Int?

  public init(values: [Int], operationCap: Int = RecordingEngine.defaultOperationCap) {
    self.values = values
    self.operationCap = operationCap
  }

  public var count: Int { values.count }

  private mutating func appendOp(_ op: SortOperation) {
    guard !didExceedCap else { return }
    guard tape.count < operationCap else {
      didExceedCap = true
      return
    }
    tape.append(op)
  }

  @discardableResult
  public mutating func compare(_ i: Int, _ j: Int, by cmp: (Int, Int) -> Bool = (>=)) -> Bool {
    markPrimarySecondary(i, j)
    appendOp(.compare(i, j))
    compareCount += 1
    return cmp(values[i], values[j])
  }

  public mutating func swap(_ i: Int, _ j: Int) {
    markPrimarySecondary(i, j)
    appendOp(.swap(i, j))
    values.swapAt(i, j)
    swapCount += 1
    // ArrayV's own convention (`Writes.updateSwap`): a swap is two array writes, not one.
    mainWriteCount += 2
  }

  private mutating func markPrimarySecondary(_ i: Int, _ j: Int) {
    if let primaryIndex {
      appendOp(.unmarkIndex(marker: Marker.primary, index: primaryIndex))
    }
    if let secondaryIndex {
      appendOp(.unmarkIndex(marker: Marker.secondary, index: secondaryIndex))
    }
    appendOp(.mark(marker: Marker.primary, index: i))
    appendOp(.mark(marker: Marker.secondary, index: j))
    primaryIndex = i
    secondaryIndex = j
  }

  public mutating func setValue(_ i: Int, _ value: Int) {
    appendOp(.setValue(i, value))
    values[i] = value
    mainWriteCount += 1
  }

  public mutating func mark(_ marker: Int, at index: Int) {
    appendOp(.mark(marker: marker, index: index))
  }

  public mutating func unmark(_ marker: Int) {
    appendOp(.unmark(marker: marker))
  }

  public mutating func unmarkAll() {
    appendOp(.unmarkAll)
  }

  /// Scratch buffers for algorithms that need one — LSD Radix's per-digit registers, merge
  /// sort's temp array, bucket sort's buckets. Mirrors ArrayV's `Writes.createExternalArray`.
  public mutating func createAuxArray(length: Int) -> AuxHandle {
    defer { nextAuxHandle += 1 }
    appendOp(.auxCreate(handle: nextAuxHandle, length: length))
    return AuxHandle(rawValue: nextAuxHandle)
  }

  public mutating func writeAux(_ handle: AuxHandle, at index: Int, value: Int) {
    appendOp(.auxWrite(handle: handle.rawValue, index: index, value: value))
    auxWriteCount += 1
  }

  public mutating func deleteAuxArray(_ handle: AuxHandle) {
    appendOp(.auxDelete(handle: handle.rawValue))
  }

  public mutating func markSorted(_ i: Int) {
    appendOp(.markSorted(i))
  }

  /// Reverses the inclusive range `[start, end]` via repeated `swap` calls — ArrayV's own
  /// `Writes.reversal` is likewise *built from* `swap()`, so a reversal still contributes to
  /// `swapCount`/`mainWriteCount` element-by-element while also counting once against
  /// `reversalCount`, a distinct ArrayV stat (an operation, not an element-move count). Pancake-
  /// family algorithms (`PancakeSort`/`BurntPancakeSort`) use this instead of a manual swap loop.
  public mutating func reversal(_ start: Int, _ end: Int) {
    appendOp(.reversal)
    reversalCount += 1
    var low = start
    var high = end
    while low < high {
      swap(low, high)
      low += 1
      high -= 1
    }
  }

  public func finish() -> RecordingSummary {
    RecordingSummary(
      tape: tape,
      compareCount: compareCount,
      swapCount: swapCount,
      mainWriteCount: mainWriteCount,
      auxWriteCount: auxWriteCount,
      reversalCount: reversalCount,
      didExceedCap: didExceedCap
    )
  }
}

/// `RecordingEngine.finish()`'s result — a real type rather than a growing tuple, so adding the
/// next ArrayV-parity statistic only means adding a field here, not updating every call site's
/// destructuring arity.
public struct RecordingSummary: Sendable {
  public let tape: [SortOperation]
  public let compareCount: Int
  public let swapCount: Int
  public let mainWriteCount: Int
  public let auxWriteCount: Int
  public let reversalCount: Int
  /// `true` if `tape` was cut short at `RecordingEngine`'s `operationCap` — `tape` still reflects
  /// a genuinely-completed run's real touches up to the cap, but stops short of the whole thing.
  public let didExceedCap: Bool
}
