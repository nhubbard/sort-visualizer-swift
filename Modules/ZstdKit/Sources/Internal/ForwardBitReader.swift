/// Reads an FSE normalized-count table description — the one part of the entropy-coding sections
/// read forward, LSB-first within each byte (opposite of `BackwardBitReader`, which reads the
/// entropy-coded symbol bitstream that follows it). Bounds-checked: unlike the backward reader,
/// running past the end here means the declared table description is truncated, a real error.
struct ForwardBitReader {
  private let bytes: [UInt8]
  private var bitOffset: Int = 0

  init(_ bytes: [UInt8]) {
    self.bytes = bytes
  }

  mutating func readBits(_ count: Int) throws -> UInt32 {
    guard count >= 0, count <= 32 else { throw ZstdError.invalidFSETable }
    var result: UInt32 = 0
    for index in 0..<count {
      let bit = try bit(at: bitOffset + index)
      result |= UInt32(bit) << index
    }
    bitOffset += count
    return result
  }

  /// Puts back `count` bits — the normalized-count algorithm sometimes over-reads by 1 bit to
  /// check a fast-path condition, then un-reads it once the condition is known to be false.
  mutating func rewind(bits count: Int) {
    bitOffset -= count
  }

  /// Byte offset just past the last bit read, rounded up — where the entropy-coded bitstream that
  /// follows this table description begins.
  var consumedBytes: Int { (bitOffset + 7) / 8 }

  private func bit(at position: Int) throws -> UInt8 {
    let byteIndex = position / 8
    guard byteIndex < bytes.count else { throw ZstdError.invalidFSETable }
    return (bytes[byteIndex] >> (position % 8)) & 1
  }
}
