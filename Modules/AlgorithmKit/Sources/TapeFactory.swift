import Foundation
import SortEngineKit

/// Thrown by `TapeFactory.makeTape` when a recording (shuffle or sort) hits `RecordingEngine`'s
/// operation cap before finishing. `compareCount`/`swapCount`/`mainWriteCount`/`auxWriteCount` are
/// the algorithm's true totals (kept incrementing past the cap, see `RecordingEngine.appendOp`),
/// not just the truncated tape length, so a caller has real numbers to log or display.
public enum TapeRecordingError: Error, Equatable, Sendable {
  case tooLarge(
    operationCount: Int, cap: Int,
    compareCount: Int, swapCount: Int, mainWriteCount: Int, auxWriteCount: Int
  )
}

/// Moved here from `SortFeature`'s `SortSession.makeTape` (see Documentation/docs/architecture/audio.md) — recording
/// a shuffle-then-sort tape has zero UI dependency and needs to be callable by both the standalone
/// app's `SortSession` and `SortAudioCore`'s headless driver, neither of which may depend on the
/// other's module.
public enum TapeFactory {
  /// Records the shuffle against an identity array, then the sort against the shuffle's output,
  /// concatenating both into one continuous `Tape` — from `ReplayEngine`'s point of view a
  /// shuffle-then-sort is just one longer tape (see Documentation/docs/architecture/content.md's "Shuffles are tapes too").
  public static func makeTape(
    algorithm: any SortAlgorithm, shuffle: any ShuffleAlgorithm, size: Int, operationCap: Int
  ) throws -> Tape {
    let identity = Array(1...size)

    var shuffleEngine = RecordingEngine(values: identity, operationCap: operationCap)
    shuffle.record(into: &shuffleEngine)
    let uniqueValueCount = Set(shuffleEngine.values).count
    // `compare`/`swap`'s auto-retraction (`markPrimarySecondary`) only clears the *previous*
    // pair right before marking a new one — there's nothing to retract whatever pair the
    // shuffle's own last `compare`/`swap` marked, since no further call ever comes along to
    // trigger it. Without this, that leftover primary/secondary would sit on the frame for
    // however long it takes the sort's own first `compare`/`swap` to happen to overwrite it
    // (each `RecordingEngine` instance only tracks the marks *it* applied, so the sort's fresh
    // instance doesn't know to retract them either) — same bug as below, one phase earlier.
    shuffleEngine.unmarkAll()
    let shuffleSummary = shuffleEngine.finish()
    if shuffleSummary.didExceedCap {
      throw TapeRecordingError.tooLarge(
        operationCount: shuffleSummary.tape.count, cap: operationCap,
        compareCount: shuffleSummary.compareCount, swapCount: shuffleSummary.swapCount,
        mainWriteCount: shuffleSummary.mainWriteCount, auxWriteCount: shuffleSummary.auxWriteCount)
    }

    // recordingDuration measures only the sort, not the shuffle — it's the real algorithmic
    // performance number (see Documentation/docs/architecture/overview.md), and a shuffle's cost isn't the
    // algorithm's to answer for.
    let recordingStart = Date()
    var sortEngine = RecordingEngine(values: shuffleEngine.values, operationCap: operationCap)
    algorithm.record(into: &sortEngine)
    let recordingDuration = Date().timeIntervalSince(recordingStart)
    // Same reasoning as `shuffleEngine.unmarkAll()` above, but for the far more visible case:
    // whichever pair the algorithm's very last `compare`/`swap` touched would otherwise stay
    // marked (one red, one blue) forever on the completed, fully-sorted final frame, since
    // nothing ever calls another `compare`/`swap` afterward to retract it. Placed after
    // `recordingDuration` is captured, not before, so this bookkeeping never counts against the
    // algorithm's own measured recording time.
    sortEngine.unmarkAll()
    let sortSummary = sortEngine.finish()
    if sortSummary.didExceedCap {
      throw TapeRecordingError.tooLarge(
        operationCount: sortSummary.tape.count, cap: operationCap,
        compareCount: sortSummary.compareCount, swapCount: sortSummary.swapCount,
        mainWriteCount: sortSummary.mainWriteCount, auxWriteCount: sortSummary.auxWriteCount)
    }

    return Tape(
      header: TapeHeader(
        algorithmID: algorithm.id.rawValue,
        initialValues: identity,
        visualSeed: UInt64.random(in: .min ... .max),
        compareCount: sortSummary.compareCount,
        swapCount: sortSummary.swapCount,
        mainWriteCount: sortSummary.mainWriteCount,
        auxWriteCount: sortSummary.auxWriteCount,
        reversalCount: sortSummary.reversalCount,
        recordingDuration: recordingDuration,
        recordedAt: Date(),
        shuffleID: shuffle.id.rawValue,
        sortStartIndex: shuffleSummary.tape.count,
        uniqueValueCount: uniqueValueCount
      ),
      operations: shuffleSummary.tape + sortSummary.tape
    )
  }
}
