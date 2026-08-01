/// Reads a Zstd entropy bitstream (Huffman or FSE) from its END toward its START — the convention
/// both formats share. The last byte's highest set bit is a padding sentinel (not data); reading
/// proceeds MSB-first from just below it, walking backward through the buffer. Multi-bit reads
/// accumulate with the first-read bit as the result's most-significant bit, matching how the
/// reference decoder's `BIT_lookBits`/`BIT_readBits` extract from the top of a right-aligned
/// window loaded from the tail of the buffer — confirmed empirically against real zstd fixtures
/// during development (see ZstdKit's Huffman/FSE tests), not derived from the spec text alone.
struct BackwardBitReader {
  private let bytes: [UInt8]
  private var bytePosition: Int
  private var bitPosition: Int

  init(_ bytes: [UInt8]) throws {
    guard let last = bytes.last, last != 0 else {
      throw ZstdError.invalidBitstream
    }
    self.bytes = bytes
    self.bytePosition = bytes.count - 1
    var sentinelBit = 7
    while (last & (1 << sentinelBit)) == 0 { sentinelBit -= 1 }
    self.bitPosition = sentinelBit - 1
  }

  /// `false` once every real bit (everything below the sentinel) has been consumed. Reading past
  /// this point is well-defined (see `readBits`), not a bounds violation — the last lookahead at
  /// the tail of a stream routinely peeks a few bits past the actual data.
  var hasBitsRemaining: Bool {
    bytePosition > 0 || bitPosition >= 0
  }

  /// Reads `count` bits (0...32). Reads that run past the start of the buffer are padded with
  /// zero — every real decoder tolerates this for the final lookahead of a stream, where a fixed
  /// lookahead width can overshoot the last few genuine bits.
  mutating func readBits(_ count: Int) -> UInt32 {
    guard count > 0 else { return 0 }
    var result: UInt32 = 0
    var remaining = count
    while remaining > 0 {
      if bitPosition < 0 {
        bytePosition -= 1
        guard bytePosition >= 0 else {
          return result << UInt32(remaining)
        }
        bitPosition = 7
      }
      let bit = (bytes[bytePosition] >> bitPosition) & 1
      result = (result << 1) | UInt32(bit)
      bitPosition -= 1
      remaining -= 1
    }
    return result
  }

  /// Reads `count` bits without consuming them — used for Huffman's flat-LUT lookahead, where the
  /// table index must be inspected before the actual per-symbol bit count is known.
  func peekBits(_ count: Int) -> UInt32 {
    var copy = self
    return copy.readBits(count)
  }
}
