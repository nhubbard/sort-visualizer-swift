/// A bounds-checked forward cursor over the archive's raw bytes — this file's own minimal
/// implementation, not `ZstdKit`'s internal `ByteReader` (not exported cross-module, and this
/// layer is meant to stay independent of `ZstdKit`'s internals per
/// `COMPRESSION_DESIGN.md`'s safety model). Shared with
/// `AlgorithmDetailsManifest.swift` for the same reason.
struct ArchiveByteReader {
  let bytes: [UInt8]
  private(set) var offset: Int

  init(_ bytes: [UInt8], offset: Int = 0) {
    self.bytes = bytes
    self.offset = offset
  }

  var remaining: Int { bytes.count - offset }

  mutating func readBytes(_ count: Int) throws -> ArraySlice<UInt8> {
    guard count >= 0, count <= remaining else { throw AlgorithmDetailsArchiveError.invalidHeader }
    let slice = bytes[offset..<(offset + count)]
    offset += count
    return slice
  }

  /// Reconstructs an unsigned little-endian integer from `byteCount` bytes (0...8) via plain
  /// bit-shift assembly — never an aligned typed load.
  mutating func readLittleEndianUInt(byteCount: Int) throws -> UInt64 {
    guard byteCount >= 0, byteCount <= 8 else { throw AlgorithmDetailsArchiveError.invalidHeader }
    let slice = try readBytes(byteCount)
    var value: UInt64 = 0
    for (index, byte) in slice.enumerated() {
      value |= UInt64(byte) << (8 * index)
    }
    return value
  }
}

/// The outer `ALGZ` envelope (`COMPRESSION_DESIGN.md`'s "Container format" §
/// "Outer envelope"), parsed from the raw archive bytes — everything needed to locate and verify
/// the single zstd frame inside, before `ZstdKit` ever sees it.
struct AlgorithmDetailsEnvelope {
  static let magic: [UInt8] = [0x41, 0x4C, 0x47, 0x5A, 0x0D, 0x0A, 0x1A, 0x0A]
  static let fixedHeaderSize = 96
  /// v1's only valid `Flags` value: bit 2 (SHA-256 present) set, bits 0/1 (dictionary present/
  /// formatted) clear. `AlgorithmDetails.algz` never carries a dictionary, so anything else is
  /// unsupported rather than partially honored.
  private static let expectedFlags: UInt64 = 0x4

  /// Absolute byte range of the zstd frame within the archive.
  let frameRange: Range<Int>
  /// The complete decompressed payload's expected length — checked against `Zstd.decompress`'s
  /// actual output independently of the zstd frame's own (optional) `Frame_Content_Size` check.
  let decompressedLength: Int
  /// SHA-256 of the complete decompressed payload (32 bytes).
  let sha256: [UInt8]

  static func parse(_ archive: [UInt8]) throws -> AlgorithmDetailsEnvelope {
    var reader = ArchiveByteReader(archive)
    let magicBytes = try reader.readBytes(8)
    guard Array(magicBytes) == magic else { throw AlgorithmDetailsArchiveError.invalidMagic }

    let major = try reader.readLittleEndianUInt(byteCount: 2)
    _ = try reader.readLittleEndianUInt(byteCount: 2)  // minor: no v1 behavior depends on it
    let headerLength = try reader.readLittleEndianUInt(byteCount: 4)
    let flags = try reader.readLittleEndianUInt(byteCount: 4)
    let codec = try reader.readLittleEndianUInt(byteCount: 2)
    _ = try reader.readLittleEndianUInt(byteCount: 2)  // reserved, must be zero in v1 but unchecked:
    // an unrecognized nonzero reserved value here doesn't change how anything below is parsed.

    guard let headerLengthInt = Int(exactly: headerLength),
      headerLengthInt >= fixedHeaderSize, headerLengthInt <= archive.count
    else {
      throw AlgorithmDetailsArchiveError.invalidHeader
    }
    guard major == 1 else { throw AlgorithmDetailsArchiveError.unsupportedVersion }
    // No case in `AlgorithmDetailsArchiveError` distinguishes "unsupported codec" from
    // "unsupported version" — both mean "this reader doesn't know how to handle this format."
    guard codec == 1 else { throw AlgorithmDetailsArchiveError.unsupportedVersion }
    guard flags == expectedFlags else { throw AlgorithmDetailsArchiveError.unsupportedFlags }

    // Checked independently of `flags`' dictionary bits: a corrupted packer run could clear the
    // flag while leaving garbage in these fields, which `flags == expectedFlags` alone wouldn't
    // catch.
    let dictionaryOffset = try reader.readLittleEndianUInt(byteCount: 8)
    let dictionaryLength = try reader.readLittleEndianUInt(byteCount: 8)
    guard dictionaryOffset == 0, dictionaryLength == 0 else {
      throw AlgorithmDetailsArchiveError.invalidHeader
    }

    let frameOffset = try reader.readLittleEndianUInt(byteCount: 8)
    let frameLength = try reader.readLittleEndianUInt(byteCount: 8)
    let decompressedLength = try reader.readLittleEndianUInt(byteCount: 8)
    let sha256Bytes = try reader.readBytes(32)

    guard let frameOffsetInt = Int(exactly: frameOffset),
      let frameLengthInt = Int(exactly: frameLength),
      let decompressedLengthInt = Int(exactly: decompressedLength)
    else {
      throw AlgorithmDetailsArchiveError.invalidHeader
    }
    // Overflow-safe two-step range check: never `offset + length <= count` before separately
    // proving the addition itself can't overflow.
    guard frameOffsetInt <= archive.count else { throw AlgorithmDetailsArchiveError.invalidSectionRange }
    guard frameLengthInt <= archive.count - frameOffsetInt else {
      throw AlgorithmDetailsArchiveError.invalidSectionRange
    }

    return AlgorithmDetailsEnvelope(
      frameRange: frameOffsetInt..<(frameOffsetInt + frameLengthInt),
      decompressedLength: decompressedLengthInt,
      sha256: Array(sha256Bytes)
    )
  }
}
