import Foundation
import Testing

@testable import SortEngineKit

@Suite
struct TapeTests {
  private func makeTape(
    operations: [SortOperation], sortStartIndex: Int = 0,
    compareCount: Int = 3, swapCount: Int = 2
  ) -> Tape {
    Tape(
      header: TapeHeader(
        algorithmID: "test",
        initialValues: [3, 1, 2],
        visualSeed: 0,
        compareCount: compareCount,
        swapCount: swapCount,
        mainWriteCount: 4,
        auxWriteCount: 1,
        reversalCount: 0,
        recordingDuration: 0,
        recordedAt: Date(timeIntervalSince1970: 0),
        sortStartIndex: sortStartIndex
      ),
      operations: operations
    )
  }

  @Test
  func significantOperationCountCountsOnlyRealAlgorithmicWork() {
    let tape = makeTape(operations: [
      .mark(marker: 0, index: 0),
      .mark(marker: 1, index: 1),
      .compare(0, 1),
      .unmarkIndex(marker: 0, index: 0),
      .unmarkIndex(marker: 1, index: 1),
      .swap(0, 1),
      .unmarkAll,
      .markSorted(0)
    ])
    // .compare, .swap, .markSorted are significant; the four mark/unmark entries are not.
    #expect(tape.significantOperationCount == 3)
  }

  @Test
  func compactedForFastPlaybackDropsOnlyCosmeticMarkerOps() {
    let tape = makeTape(operations: [
      .mark(marker: 0, index: 0),
      .mark(marker: 1, index: 1),
      .compare(0, 1),
      .unmarkIndex(marker: 0, index: 0),
      .unmarkIndex(marker: 1, index: 1),
      .swap(0, 1),
      .unmark(marker: 0),
      .unmarkAll,
      .auxCreate(handle: 0, length: 2),
      .auxWrite(handle: 0, index: 0, value: 9),
      .auxDelete(handle: 0),
      .markSorted(0)
    ])
    let compacted = tape.compactedForFastPlayback()

    #expect(
      compacted.operations == [
        .compare(0, 1),
        .swap(0, 1),
        .auxCreate(handle: 0, length: 2),
        .auxWrite(handle: 0, index: 0, value: 9),
        .auxDelete(handle: 0),
        .markSorted(0)
      ])
  }

  @Test
  func compactedForFastPlaybackPreservesHeaderStatsVerbatim() {
    let tape = makeTape(
      operations: [.mark(marker: 0, index: 0), .compare(0, 1)],
      compareCount: 123, swapCount: 45
    )
    let compacted = tape.compactedForFastPlayback()

    #expect(compacted.header.compareCount == 123)
    #expect(compacted.header.swapCount == 45)
    #expect(compacted.header.mainWriteCount == tape.header.mainWriteCount)
    #expect(compacted.header.auxWriteCount == tape.header.auxWriteCount)
    #expect(compacted.header.algorithmID == tape.header.algorithmID)
  }

  /// The real correctness detail: `sortStartIndex` is an absolute index into `operations`, so
  /// dropping entries before it must shift it by exactly how many of those dropped entries
  /// preceded it — copying it verbatim would desync `ReplayEngine`'s shuffle/sort stat gate from
  /// the actual boundary in the compacted stream.
  @Test
  func compactedForFastPlaybackRemapsSortStartIndex() {
    let tape = makeTape(
      operations: [
        // "Shuffle" phase (indices 0...3): two significant swaps, two cosmetic marks.
        .swap(0, 1),
        .mark(marker: 0, index: 0),
        .swap(1, 2),
        .unmarkAll,
        // "Sort" phase begins at original index 4.
        .compare(0, 1),
        .markSorted(0)
      ],
      sortStartIndex: 4
    )
    let compacted = tape.compactedForFastPlayback()

    // Only the two swaps survive from the shuffle phase, so the boundary shifts from 4 to 2.
    #expect(compacted.header.sortStartIndex == 2)
    #expect(compacted.operations == [.swap(0, 1), .swap(1, 2), .compare(0, 1), .markSorted(0)])
  }
}
