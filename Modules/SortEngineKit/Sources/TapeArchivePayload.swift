import Foundation

/// The decompressed inner payload of a tape archive: a "TAPE"-magic header, `TapeHeader`'s 13
/// fields at fixed widths, then `operations` as a tag-byte-per-case mirror of `SortOperation`'s
/// 12 cases — more compact than a fixed-max-width record, and a direct structural mirror of the
/// enum itself.
enum TapeArchivePayload {
  private static let magic: [UInt8] = [0x54, 0x41, 0x50, 0x45]  // "TAPE"

  static func encode(_ tape: Tape) -> [UInt8] {
    var writer = TapeArchiveByteWriter()
    writer.writeBytes(magic)

    writeString(tape.header.algorithmID, into: &writer)

    writer.writeLittleEndianUInt(UInt64(tape.header.initialValues.count), byteCount: 4)
    for value in tape.header.initialValues {
      writer.writeLittleEndianUInt(UInt64(UInt32(truncatingIfNeeded: value)), byteCount: 4)
    }

    writer.writeLittleEndianUInt(tape.header.visualSeed, byteCount: 8)
    writer.writeLittleEndianUInt(UInt64(UInt32(truncatingIfNeeded: tape.header.compareCount)), byteCount: 4)
    writer.writeLittleEndianUInt(UInt64(UInt32(truncatingIfNeeded: tape.header.swapCount)), byteCount: 4)
    writer.writeLittleEndianUInt(UInt64(UInt32(truncatingIfNeeded: tape.header.mainWriteCount)), byteCount: 4)
    writer.writeLittleEndianUInt(UInt64(UInt32(truncatingIfNeeded: tape.header.auxWriteCount)), byteCount: 4)
    writer.writeLittleEndianUInt(UInt64(UInt32(truncatingIfNeeded: tape.header.reversalCount)), byteCount: 4)

    writer.writeLittleEndianUInt(tape.header.recordingDuration.bitPattern, byteCount: 8)
    writer.writeLittleEndianUInt(tape.header.recordedAt.timeIntervalSince1970.bitPattern, byteCount: 8)

    if let shuffleID = tape.header.shuffleID {
      writer.writeLittleEndianUInt(1, byteCount: 1)
      writeString(shuffleID, into: &writer)
    } else {
      writer.writeLittleEndianUInt(0, byteCount: 1)
    }

    writer.writeLittleEndianUInt(UInt64(UInt32(truncatingIfNeeded: tape.header.sortStartIndex)), byteCount: 4)

    if let uniqueValueCount = tape.header.uniqueValueCount {
      writer.writeLittleEndianUInt(1, byteCount: 1)
      writer.writeLittleEndianUInt(UInt64(UInt32(truncatingIfNeeded: uniqueValueCount)), byteCount: 4)
    } else {
      writer.writeLittleEndianUInt(0, byteCount: 1)
    }

    writer.writeLittleEndianUInt(UInt64(tape.operations.count), byteCount: 4)
    for operation in tape.operations {
      encode(operation, into: &writer)
    }

    return writer.bytes
  }

  static func decode(_ bytes: [UInt8]) throws -> Tape {
    var reader = TapeArchiveByteReader(bytes)
    let magicBytes = try reader.readBytes(4)
    guard Array(magicBytes) == magic else { throw TapeArchiveError.invalidMagic }

    let algorithmID = try readString(from: &reader)

    let initialValueCount = try reader.readLittleEndianUInt(byteCount: 4)
    guard let initialValueCountInt = Int(exactly: initialValueCount) else { throw TapeArchiveError.invalidHeader }
    var initialValues: [Int] = []
    initialValues.reserveCapacity(initialValueCountInt)
    for _ in 0..<initialValueCountInt {
      let raw = try reader.readLittleEndianUInt(byteCount: 4)
      initialValues.append(Int(Int32(bitPattern: UInt32(truncatingIfNeeded: raw))))
    }

    let visualSeed = try reader.readLittleEndianUInt(byteCount: 8)
    let compareCount = try readInt32(from: &reader)
    let swapCount = try readInt32(from: &reader)
    let mainWriteCount = try readInt32(from: &reader)
    let auxWriteCount = try readInt32(from: &reader)
    let reversalCount = try readInt32(from: &reader)

    let recordingDuration = Double(bitPattern: try reader.readLittleEndianUInt(byteCount: 8))
    let recordedAt = Date(
      timeIntervalSince1970: Double(bitPattern: try reader.readLittleEndianUInt(byteCount: 8)))

    let hasShuffleID = try reader.readLittleEndianUInt(byteCount: 1)
    let shuffleID: String?
    switch hasShuffleID {
    case 0: shuffleID = nil
    case 1: shuffleID = try readString(from: &reader)
    default: throw TapeArchiveError.invalidHeader
    }

    let sortStartIndex = try readInt32(from: &reader)

    let hasUniqueValueCount = try reader.readLittleEndianUInt(byteCount: 1)
    let uniqueValueCount: Int?
    switch hasUniqueValueCount {
    case 0: uniqueValueCount = nil
    case 1: uniqueValueCount = try readInt32(from: &reader)
    default: throw TapeArchiveError.invalidHeader
    }

    let header = TapeHeader(
      algorithmID: algorithmID,
      initialValues: initialValues,
      visualSeed: visualSeed,
      compareCount: compareCount,
      swapCount: swapCount,
      mainWriteCount: mainWriteCount,
      auxWriteCount: auxWriteCount,
      reversalCount: reversalCount,
      recordingDuration: recordingDuration,
      recordedAt: recordedAt,
      shuffleID: shuffleID,
      sortStartIndex: sortStartIndex,
      uniqueValueCount: uniqueValueCount
    )

    let operationCount = try reader.readLittleEndianUInt(byteCount: 4)
    guard let operationCountInt = Int(exactly: operationCount) else { throw TapeArchiveError.invalidHeader }
    var operations: [SortOperation] = []
    operations.reserveCapacity(operationCountInt)
    for _ in 0..<operationCountInt {
      operations.append(try decodeOperation(from: &reader))
    }

    guard reader.remaining == 0 else { throw TapeArchiveError.truncatedOperationList }

    return Tape(header: header, operations: operations)
  }

  // MARK: - Strings

  private static func writeString(_ string: String, into writer: inout TapeArchiveByteWriter) {
    let utf8 = Array(string.utf8)
    writer.writeLittleEndianUInt(UInt64(utf8.count), byteCount: 2)
    writer.writeBytes(utf8)
  }

  private static func readString(from reader: inout TapeArchiveByteReader) throws -> String {
    let length = try reader.readLittleEndianUInt(byteCount: 2)
    guard let lengthInt = Int(exactly: length) else { throw TapeArchiveError.invalidHeader }
    let bytes = try reader.readBytes(lengthInt)
    guard let string = String(bytes: bytes, encoding: .utf8) else { throw TapeArchiveError.invalidUTF8 }
    return string
  }

  // MARK: - Int32 fields

  private static func readInt32(from reader: inout TapeArchiveByteReader) throws -> Int {
    let raw = try reader.readLittleEndianUInt(byteCount: 4)
    return Int(Int32(bitPattern: UInt32(truncatingIfNeeded: raw)))
  }

  // MARK: - Operations

  /// Tag byte per case, in `SortOperation`'s own declaration order — 0 through 11. Each case's
  /// fields are written as plain `Int32`s (0 to 3 of them, per the case), the same width used for
  /// every other count-like field in this format.
  private static func encode(_ operation: SortOperation, into writer: inout TapeArchiveByteWriter) {
    func writeInt32(_ value: Int) {
      writer.writeLittleEndianUInt(UInt64(UInt32(truncatingIfNeeded: value)), byteCount: 4)
    }
    switch operation {
    case .swap(let a, let b):
      writer.writeLittleEndianUInt(0, byteCount: 1)
      writeInt32(a)
      writeInt32(b)
    case .setValue(let index, let value):
      writer.writeLittleEndianUInt(1, byteCount: 1)
      writeInt32(index)
      writeInt32(value)
    case .mark(let marker, let index):
      writer.writeLittleEndianUInt(2, byteCount: 1)
      writeInt32(marker)
      writeInt32(index)
    case .unmark(let marker):
      writer.writeLittleEndianUInt(3, byteCount: 1)
      writeInt32(marker)
    case .unmarkAll:
      writer.writeLittleEndianUInt(4, byteCount: 1)
    case .unmarkIndex(let marker, let index):
      writer.writeLittleEndianUInt(5, byteCount: 1)
      writeInt32(marker)
      writeInt32(index)
    case .compare(let a, let b):
      writer.writeLittleEndianUInt(6, byteCount: 1)
      writeInt32(a)
      writeInt32(b)
    case .markSorted(let index):
      writer.writeLittleEndianUInt(7, byteCount: 1)
      writeInt32(index)
    case .auxCreate(let handle, let length):
      writer.writeLittleEndianUInt(8, byteCount: 1)
      writeInt32(handle)
      writeInt32(length)
    case .auxWrite(let handle, let index, let value):
      writer.writeLittleEndianUInt(9, byteCount: 1)
      writeInt32(handle)
      writeInt32(index)
      writeInt32(value)
    case .auxDelete(let handle):
      writer.writeLittleEndianUInt(10, byteCount: 1)
      writeInt32(handle)
    case .reversal:
      writer.writeLittleEndianUInt(11, byteCount: 1)
    }
  }

  private static func decodeOperation(from reader: inout TapeArchiveByteReader) throws -> SortOperation {
    let tag = try reader.readLittleEndianUInt(byteCount: 1)
    switch tag {
    case 0: return .swap(try readInt32(from: &reader), try readInt32(from: &reader))
    case 1: return .setValue(try readInt32(from: &reader), try readInt32(from: &reader))
    case 2: return .mark(marker: try readInt32(from: &reader), index: try readInt32(from: &reader))
    case 3: return .unmark(marker: try readInt32(from: &reader))
    case 4: return .unmarkAll
    case 5: return .unmarkIndex(marker: try readInt32(from: &reader), index: try readInt32(from: &reader))
    case 6: return .compare(try readInt32(from: &reader), try readInt32(from: &reader))
    case 7: return .markSorted(try readInt32(from: &reader))
    case 8: return .auxCreate(handle: try readInt32(from: &reader), length: try readInt32(from: &reader))
    case 9:
      return .auxWrite(
        handle: try readInt32(from: &reader), index: try readInt32(from: &reader),
        value: try readInt32(from: &reader))
    case 10: return .auxDelete(handle: try readInt32(from: &reader))
    case 11: return .reversal
    default: throw TapeArchiveError.unknownOperationTag
    }
  }
}
