import Foundation
import Testing

@testable import SortEngineKit

@Suite
struct TapeArchiveTests {
  private func makeTape(
    operations: [SortOperation],
    shuffleID: String? = nil,
    uniqueValueCount: Int? = nil
  ) -> Tape {
    Tape(
      header: TapeHeader(
        algorithmID: "test-algorithm",
        initialValues: [3, 1, 2, 0, -5],
        visualSeed: 0xDEAD_BEEF_1234_5678,
        compareCount: 7,
        swapCount: 3,
        mainWriteCount: 6,
        auxWriteCount: 2,
        reversalCount: 1,
        recordingDuration: 12.5,
        recordedAt: Date(timeIntervalSince1970: 1_700_000_000),
        shuffleID: shuffleID,
        sortStartIndex: 2,
        uniqueValueCount: uniqueValueCount
      ),
      operations: operations
    )
  }

  /// One of every `SortOperation` case, including both zero-payload cases (`.unmarkAll`,
  /// `.reversal`), with distinct field values so a field-order or tag mixup would show up as a
  /// value mismatch rather than accidentally matching.
  private static let oneOfEachOperation: [SortOperation] = [
    .swap(1, 2),
    .setValue(3, 40),
    .mark(marker: 5, index: 6),
    .unmark(marker: 7),
    .unmarkAll,
    .unmarkIndex(marker: 8, index: 9),
    .compare(10, 11),
    .markSorted(12),
    .auxCreate(handle: 13, length: 14),
    .auxWrite(handle: 15, index: 16, value: 17),
    .auxDelete(handle: 18),
    .reversal
  ]

  @Test
  func roundTripsEveryOperationCase() throws {
    let tape = makeTape(operations: Self.oneOfEachOperation)
    let archived = try tape.archived()
    let reloaded = try Tape(archivedData: archived)
    #expect(reloaded == tape)
  }

  @Test
  func roundTripsWithNeitherOptionalHeaderFieldPresent() throws {
    let tape = makeTape(operations: [.compare(0, 1), .swap(0, 1)])
    #expect(try Tape(archivedData: try tape.archived()) == tape)
  }

  @Test
  func roundTripsWithOnlyShuffleIDPresent() throws {
    let tape = makeTape(operations: [.compare(0, 1), .swap(0, 1)], shuffleID: "fisherYates")
    #expect(try Tape(archivedData: try tape.archived()) == tape)
  }

  @Test
  func roundTripsWithOnlyUniqueValueCountPresent() throws {
    let tape = makeTape(operations: [.compare(0, 1), .swap(0, 1)], uniqueValueCount: 42)
    #expect(try Tape(archivedData: try tape.archived()) == tape)
  }

  @Test
  func roundTripsWithBothOptionalHeaderFieldsPresent() throws {
    let tape = makeTape(
      operations: [.compare(0, 1), .swap(0, 1)], shuffleID: "fisherYates", uniqueValueCount: 42)
    #expect(try Tape(archivedData: try tape.archived()) == tape)
  }

  @Test
  func flippedMagicByteThrowsInvalidMagic() throws {
    let tape = makeTape(operations: [.compare(0, 1)])
    var archived = [UInt8](try tape.archived())
    archived[0] ^= 0xFF
    #expect(throws: TapeArchiveError.invalidMagic) {
      try Tape(archivedData: Data(archived))
    }
  }

  @Test
  func truncatedArchiveThrows() throws {
    let tape = makeTape(operations: [.compare(0, 1), .swap(0, 1), .markSorted(0)])
    let archived = [UInt8](try tape.archived())
    let truncated = Data(archived.prefix(archived.count - 5))
    #expect(throws: (any Error).self) {
      try Tape(archivedData: truncated)
    }
  }

  @Test
  func tamperedSHA256ThrowsHashMismatch() throws {
    let tape = makeTape(operations: [.compare(0, 1)])
    var archived = [UInt8](try tape.archived())
    // The SHA-256 field is the last 32 bytes of the fixed 80-byte header, right before the frame.
    archived[TapeArchiveEnvelope.fixedHeaderSize - 1] ^= 0xFF
    #expect(throws: TapeArchiveError.hashMismatch) {
      try Tape(archivedData: Data(archived))
    }
  }

  @Test
  func unknownOperationTagThrows() {
    // Hand-built payload: "TAPE" magic, a minimal valid header (empty algorithmID, no initial
    // values, zero counters, no shuffleID/uniqueValueCount), one declared operation, then a tag
    // byte (200) no real case ever produces.
    var bytes: [UInt8] = [0x54, 0x41, 0x50, 0x45]  // "TAPE"
    bytes += [0, 0]  // algorithmID length = 0
    bytes += [0, 0, 0, 0]  // initialValues count = 0
    bytes += [0, 0, 0, 0, 0, 0, 0, 0]  // visualSeed
    bytes += Array(repeating: 0, count: 4 * 5)  // 5 counters
    bytes += Array(repeating: 0, count: 8)  // recordingDuration
    bytes += Array(repeating: 0, count: 8)  // recordedAt
    bytes += [0]  // no shuffleID
    bytes += [0, 0, 0, 0]  // sortStartIndex
    bytes += [0]  // no uniqueValueCount
    bytes += [1, 0, 0, 0]  // operation count = 1
    bytes += [200]  // unknown tag

    #expect(throws: TapeArchiveError.unknownOperationTag) {
      _ = try TapeArchivePayload.decode(bytes)
    }
  }

  @Test
  @MainActor
  func exportedAndReimportedTapeReplaysIdenticallyToTheOriginal() throws {
    let tape = makeTape(
      operations: [
        .mark(marker: Marker.primary, index: 0),
        .mark(marker: Marker.secondary, index: 1),
        .compare(0, 1),
        .swap(0, 1),
        .unmarkAll,
        .auxCreate(handle: 0, length: 2),
        .auxWrite(handle: 0, index: 0, value: 99),
        .auxDelete(handle: 0),
        .markSorted(0),
        .markSorted(1)
      ],
      shuffleID: "fisherYates", uniqueValueCount: 5
    )
    let reloaded = try Tape(archivedData: try tape.archived())

    let originalEngine = ReplayEngine(tape: tape)
    let reloadedEngine = ReplayEngine(tape: reloaded)
    for _ in 0..<tape.operations.count {
      originalEngine.stepForward()
      reloadedEngine.stepForward()
    }

    #expect(reloadedEngine.frame.map(\.value) == originalEngine.frame.map(\.value))
    #expect(reloadedEngine.frame.map(\.isSorted) == originalEngine.frame.map(\.isSorted))
    #expect(reloadedEngine.compareCount == originalEngine.compareCount)
    #expect(reloadedEngine.swapCount == originalEngine.swapCount)
    #expect(reloadedEngine.mainWriteCount == originalEngine.mainWriteCount)
    #expect(reloadedEngine.auxWriteCount == originalEngine.auxWriteCount)
  }
}
