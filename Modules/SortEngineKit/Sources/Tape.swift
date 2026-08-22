import Foundation

/// Handle for one of an algorithm's scratch buffers (merge sort's temp array, bucket sort's
/// buckets, LSD Radix's digit registers). Only ever produced by `RecordingEngine.createAuxArray`.
public struct AuxHandle: Hashable, Sendable, Codable {
  public let rawValue: Int

  public init(rawValue: Int) {
    self.rawValue = rawValue
  }
}

public struct TapeHeader: Sendable, Codable, Equatable {
  public let algorithmID: String
  public let initialValues: [Int]
  /// Seeds e.g. Radix's shuffled bucket→color map, deterministically.
  public let visualSeed: UInt64
  public let compareCount: Int
  public let swapCount: Int
  /// Writes to the main array — a swap counts as 2, matching ArrayV's `Writes.updateSwap`
  /// convention (two elements physically move), plus 1 per `.setValue`.
  public let mainWriteCount: Int
  /// Writes to auxiliary/scratch buffers created via `createAuxArray` (merge sort's temp array,
  /// radix sort's digit registers, etc.) — ArrayV's `Writes.auxWrites`.
  public let auxWriteCount: Int
  /// Whole-range-reverse operations (`RecordingEngine.reversal(_:_:)`) — ArrayV's
  /// `Writes.reversals`. Each one also contributes to `swapCount`/`mainWriteCount`
  /// element-by-element; this counts the operation, not the element moves.
  public let reversalCount: Int
  /// Wall-clock time to RECORD — this is the real perf number, decoupled from playback speed.
  public let recordingDuration: TimeInterval
  public let recordedAt: Date
  /// `nil` for a tape with no recorded shuffle (e.g. a hand-built test fixture, or an algorithm
  /// recorded directly against a specific input) — matches `Marker.bucket`-style optionality
  /// rather than a sentinel string.
  public let shuffleID: String?
  /// Where the sort's operations begin within `Tape.operations` — `0` when there's no shuffle.
  /// A shuffle-then-sort is just one longer tape from `ReplayEngine`'s point of view; this is
  /// the one piece of bookkeeping that lets a future consumer (step/scrub UI, a "skip shuffle"
  /// button) distinguish the two phases without re-deriving it (§2A.4).
  public let sortStartIndex: Int
  /// Distinct value count in the array immediately after the shuffle, before the sort runs —
  /// ArrayV's `m`. `nil` when the caller has no shuffle output to count (e.g. a hand-built test
  /// fixture). Every built-in shuffle keeps values within `~[1, n]`, but two of the five
  /// (`shuffledcubic`/`shuffledquintic`) resample through a skewed curve and can collapse several
  /// positions onto the same value — so unlike the array's value range (always `~n`, regardless
  /// of shuffle), `m` genuinely isn't a fixed function of `n` and has to be measured per run.
  public let uniqueValueCount: Int?

  public init(
    algorithmID: String,
    initialValues: [Int],
    visualSeed: UInt64,
    compareCount: Int,
    swapCount: Int,
    mainWriteCount: Int = 0,
    auxWriteCount: Int = 0,
    reversalCount: Int = 0,
    recordingDuration: TimeInterval,
    recordedAt: Date,
    shuffleID: String? = nil,
    sortStartIndex: Int = 0,
    uniqueValueCount: Int? = nil
  ) {
    self.algorithmID = algorithmID
    self.initialValues = initialValues
    self.visualSeed = visualSeed
    self.compareCount = compareCount
    self.swapCount = swapCount
    self.mainWriteCount = mainWriteCount
    self.auxWriteCount = auxWriteCount
    self.reversalCount = reversalCount
    self.recordingDuration = recordingDuration
    self.recordedAt = recordedAt
    self.shuffleID = shuffleID
    self.sortStartIndex = sortStartIndex
    self.uniqueValueCount = uniqueValueCount
  }
}

public struct Tape: Sendable, Codable, Equatable {
  public let header: TapeHeader
  public let operations: [SortOperation]

  public init(header: TapeHeader, operations: [SortOperation]) {
    self.header = header
    self.operations = operations
  }

  /// How many operations in `operations` are real algorithmic work rather than highlight
  /// bookkeeping — see `SortOperation.isSignificantForPacing`. Precomputed once per tape (rather
  /// than accumulated live during replay) so a pacing mode that needs the *total* up front, before
  /// any operation has been applied, can compute a target rate immediately.
  public var significantOperationCount: Int {
    operations.count { $0.isSignificantForPacing }
  }

  /// A replay-only copy with purely-cosmetic marker bookkeeping (`.mark`/`.unmark`/`.unmarkAll`/
  /// `.unmarkIndex`) dropped — every operation that actually mutates `values`/`auxArrays`
  /// (`.swap`/`.setValue`/`.compare`/`.auxWrite`/`.reversal`/`.markSorted`), plus aux-buffer
  /// lifecycle (`.auxCreate`/`.auxDelete`, which a later `.auxWrite` depends on for renderer
  /// state), is preserved in order untouched. `header`'s recorded stats
  /// (`compareCount`/`swapCount`/etc.) are copied verbatim — they were captured directly from the
  /// algorithm's own counters at record time, never recomputed from `operations` — so this can
  /// never change what gets reported as the true operation counts, only how much cosmetic
  /// highlight flicker plays back. `sortStartIndex` is remapped (not copied verbatim), since it's
  /// an absolute index into `operations` and dropping entries before it would otherwise desync it
  /// from the real shuffle/sort boundary.
  public func compactedForFastPlayback() -> Tape {
    var keptBeforeSortStart = 0
    var kept: [SortOperation] = []
    kept.reserveCapacity(operations.count)
    for (index, operation) in operations.enumerated() {
      switch operation {
      case .mark, .unmark, .unmarkAll, .unmarkIndex:
        continue
      default:
        if index < header.sortStartIndex {
          keptBeforeSortStart += 1
        }
        kept.append(operation)
      }
    }
    let newHeader = TapeHeader(
      algorithmID: header.algorithmID,
      initialValues: header.initialValues,
      visualSeed: header.visualSeed,
      compareCount: header.compareCount,
      swapCount: header.swapCount,
      mainWriteCount: header.mainWriteCount,
      auxWriteCount: header.auxWriteCount,
      reversalCount: header.reversalCount,
      recordingDuration: header.recordingDuration,
      recordedAt: header.recordedAt,
      shuffleID: header.shuffleID,
      sortStartIndex: keptBeforeSortStart,
      uniqueValueCount: header.uniqueValueCount
    )
    return Tape(header: newHeader, operations: kept)
  }
}
