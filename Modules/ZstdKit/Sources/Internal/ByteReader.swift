/// A bounds-checked forward cursor over a byte buffer. Every read throws `.truncatedInput` rather
/// than trapping when it would run past the end — this is the safe-Swift parsing layer the plan's
/// safety model requires for anything outside the optimized (later, `Unsafe*`-using) hot path.
struct ByteReader {
  let bytes: [UInt8]
  private(set) var offset: Int

  init(_ bytes: [UInt8], offset: Int = 0) {
    self.bytes = bytes
    self.offset = offset
  }

  var remaining: Int { bytes.count - offset }

  func peekByte() throws -> UInt8 {
    guard offset < bytes.count else { throw ZstdError.truncatedInput }
    return bytes[offset]
  }

  /// Every byte not yet consumed, as a slice sharing storage with the underlying buffer.
  func remainingBytes() -> ArraySlice<UInt8> {
    bytes[offset...]
  }

  mutating func readByte() throws -> UInt8 {
    guard offset < bytes.count else { throw ZstdError.truncatedInput }
    defer { offset += 1 }
    return bytes[offset]
  }

  mutating func readBytes(_ count: Int) throws -> ArraySlice<UInt8> {
    guard count >= 0, count <= remaining else { throw ZstdError.truncatedInput }
    let slice = bytes[offset..<(offset + count)]
    offset += count
    return slice
  }

  /// Reconstructs an unsigned little-endian integer from `byteCount` bytes (0...8) via plain
  /// bit-shift assembly — never an aligned typed load.
  mutating func readLittleEndianUInt(byteCount: Int) throws -> UInt64 {
    guard byteCount >= 0, byteCount <= 8 else { throw ZstdError.invalidFrameHeader }
    let slice = try readBytes(byteCount)
    var value: UInt64 = 0
    for (index, byte) in slice.enumerated() {
      value |= UInt64(byte) << (8 * index)
    }
    return value
  }

  mutating func skip(_ count: Int) throws {
    guard count >= 0, count <= remaining else { throw ZstdError.truncatedInput }
    offset += count
  }
}
