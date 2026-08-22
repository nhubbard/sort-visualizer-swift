import Foundation

/// A minimal bounds-checked byte cursor for the tape archive format, built the same way as
/// `AlgorithmDetailsEnvelope.swift`'s `ArchiveByteReader` (`SortFeature` depends on
/// `SortEngineKit`, not the reverse, so that type can't be reused directly here) — every read
/// checks `count <= remaining` before slicing, and every multi-byte integer is assembled with a
/// plain little-endian shift loop, never a typed/aligned load.
struct TapeArchiveByteReader {
  let bytes: [UInt8]
  private(set) var offset: Int

  init(_ bytes: [UInt8], offset: Int = 0) {
    self.bytes = bytes
    self.offset = offset
  }

  var remaining: Int { bytes.count - offset }

  mutating func readBytes(_ count: Int) throws -> ArraySlice<UInt8> {
    guard count >= 0, count <= remaining else { throw TapeArchiveError.invalidHeader }
    let slice = bytes[offset..<(offset + count)]
    offset += count
    return slice
  }

  mutating func readLittleEndianUInt(byteCount: Int) throws -> UInt64 {
    guard byteCount >= 0, byteCount <= 8 else { throw TapeArchiveError.invalidHeader }
    let slice = try readBytes(byteCount)
    var value: UInt64 = 0
    for (index, byte) in slice.enumerated() {
      value |= UInt64(byte) << (8 * index)
    }
    return value
  }
}

/// The write-side mirror of `TapeArchiveByteReader` — a plain little-endian byte accumulator, used
/// by both the envelope and the payload.
struct TapeArchiveByteWriter {
  private(set) var bytes: [UInt8] = []

  mutating func writeBytes(_ newBytes: some Sequence<UInt8>) {
    bytes.append(contentsOf: newBytes)
  }

  mutating func writeLittleEndianUInt(_ value: UInt64, byteCount: Int) {
    precondition(byteCount >= 0 && byteCount <= 8)
    for index in 0..<byteCount {
      bytes.append(UInt8(truncatingIfNeeded: value >> (8 * index)))
    }
  }
}

/// The outer envelope for a tape archive, modeled on `AlgorithmDetailsEnvelope` but leaner where
/// that format's own fields turned out vestigial: `AlgorithmDetailsEnvelope`'s dictionary offset/
/// length fields are always zero in practice (dictionary support was never actually built), so
/// this format doesn't carry that dead weight forward at all — no dictionary fields, no flags
/// bit for their presence, nothing to validate-as-always-zero.
struct TapeArchiveEnvelope {
  // "STAP\r\n\x1a\n" — the trailing CR/LF/SUB/LF quartet is the same "don't get mangled by a
  // text-mode transfer" trick `AlgorithmDetailsEnvelope`'s "ALGZ\r\n\x1a\n" and PNG's own magic
  // use.
  static let magic: [UInt8] = [0x53, 0x54, 0x41, 0x50, 0x0D, 0x0A, 0x1A, 0x0A]
  static let fixedHeaderSize = 80
  private static let supportedCodec: UInt64 = 1  // zstd, matching AlgorithmDetailsEnvelope's codec=1

  let frameRange: Range<Int>
  let decompressedLength: Int
  let sha256: [UInt8]

  static func parse(_ archive: [UInt8]) throws -> TapeArchiveEnvelope {
    var reader = TapeArchiveByteReader(archive)
    let magicBytes = try reader.readBytes(8)
    guard Array(magicBytes) == magic else { throw TapeArchiveError.invalidMagic }

    let major = try reader.readLittleEndianUInt(byteCount: 2)
    _ = try reader.readLittleEndianUInt(byteCount: 2)  // minor, ignored
    let headerLength = try reader.readLittleEndianUInt(byteCount: 4)
    let flags = try reader.readLittleEndianUInt(byteCount: 4)
    let codec = try reader.readLittleEndianUInt(byteCount: 2)
    _ = try reader.readLittleEndianUInt(byteCount: 2)  // reserved, ignored

    guard let headerLengthInt = Int(exactly: headerLength),
      headerLengthInt >= fixedHeaderSize, headerLengthInt <= archive.count
    else { throw TapeArchiveError.invalidHeader }
    guard major == 1 else { throw TapeArchiveError.unsupportedVersion }
    guard codec == supportedCodec else { throw TapeArchiveError.unsupportedVersion }
    guard flags == 0 else { throw TapeArchiveError.invalidHeader }

    let frameOffset = try reader.readLittleEndianUInt(byteCount: 8)
    let frameLength = try reader.readLittleEndianUInt(byteCount: 8)
    let decompressedLength = try reader.readLittleEndianUInt(byteCount: 8)
    let sha256Bytes = try reader.readBytes(32)

    guard let frameOffsetInt = Int(exactly: frameOffset),
      let frameLengthInt = Int(exactly: frameLength),
      let decompressedLengthInt = Int(exactly: decompressedLength)
    else { throw TapeArchiveError.invalidHeader }
    guard frameOffsetInt <= archive.count else { throw TapeArchiveError.invalidSectionRange }
    guard frameLengthInt <= archive.count - frameOffsetInt else {
      throw TapeArchiveError.invalidSectionRange
    }

    return TapeArchiveEnvelope(
      frameRange: frameOffsetInt..<(frameOffsetInt + frameLengthInt),
      decompressedLength: decompressedLengthInt,
      sha256: Array(sha256Bytes)
    )
  }

  /// Builds the full archive: the fixed 80-byte header immediately followed by `frame` — no
  /// dictionary section, so `frameOffset` is always exactly `fixedHeaderSize`.
  static func write(frame: [UInt8], decompressedLength: Int, sha256: [UInt8]) -> [UInt8] {
    precondition(sha256.count == 32)
    var writer = TapeArchiveByteWriter()
    writer.writeBytes(magic)
    writer.writeLittleEndianUInt(1, byteCount: 2)  // major
    writer.writeLittleEndianUInt(0, byteCount: 2)  // minor
    writer.writeLittleEndianUInt(UInt64(fixedHeaderSize), byteCount: 4)
    writer.writeLittleEndianUInt(0, byteCount: 4)  // flags
    writer.writeLittleEndianUInt(supportedCodec, byteCount: 2)
    writer.writeLittleEndianUInt(0, byteCount: 2)  // reserved
    writer.writeLittleEndianUInt(UInt64(fixedHeaderSize), byteCount: 8)  // frameOffset
    writer.writeLittleEndianUInt(UInt64(frame.count), byteCount: 8)  // frameLength
    writer.writeLittleEndianUInt(UInt64(decompressedLength), byteCount: 8)
    writer.writeBytes(sha256)
    writer.writeBytes(frame)
    return writer.bytes
  }
}
