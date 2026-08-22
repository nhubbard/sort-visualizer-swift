import Testing

@testable import ZstdKit

/// Direct round-trip checks against the existing, already-verified readers — the load-bearing
/// correctness gate for the two write-side primitives every entropy encoder builds on. Bugs here
/// would otherwise hide until a much later, harder-to-localize full-frame test.
@Suite
struct BitWriterTests {
  @Test
  func forwardBitWriterRoundTripsThroughForwardBitReader() throws {
    var writer = ForwardBitWriter()
    writer.writeBits(0b101, count: 3)
    writer.writeBits(0b0, count: 1)
    writer.writeBits(0b1111_0000, count: 8)
    writer.writeBits(0b11, count: 2)

    var reader = ForwardBitReader(writer.bytes)
    #expect(try reader.readBits(3) == 0b101)
    #expect(try reader.readBits(1) == 0b0)
    #expect(try reader.readBits(8) == 0b1111_0000)
    #expect(try reader.readBits(2) == 0b11)
  }

  @Test
  func forwardBitWriterHandlesWidesAndZeroWidthWrites() throws {
    var writer = ForwardBitWriter()
    writer.writeBits(0, count: 0)
    writer.writeBits(0xFFFF_FFFF, count: 32)

    var reader = ForwardBitReader(writer.bytes)
    #expect(try reader.readBits(32) == 0xFFFF_FFFF)
  }

  @Test
  func backwardBitWriterRoundTripsThroughBackwardBitReader() throws {
    var writer = BackwardBitWriter()
    writer.writeBits(0b101, count: 3)
    writer.writeBits(0b0, count: 1)
    writer.writeBits(0b1111_0000, count: 8)
    writer.writeBits(0b11, count: 2)
    let bytes = writer.finish()

    var reader = try BackwardBitReader(bytes)
    #expect(reader.readBits(3) == 0b101)
    #expect(reader.readBits(1) == 0b0)
    #expect(reader.readBits(8) == 0b1111_0000)
    #expect(reader.readBits(2) == 0b11)
  }

  /// Widths spanning multiple byte boundaries, including exactly-8-bit and >8-bit fields, and a
  /// total length that lands exactly on a byte boundary (no partial trailing byte) — the two
  /// `finish()` code paths (with and without a partial final byte) both need coverage.
  @Test
  func backwardBitWriterHandlesWideFieldsAndByteAlignedTotalLength() throws {
    var writer = BackwardBitWriter()
    writer.writeBits(0x1234, count: 16)  // total so far: sentinel(1) + 16 = 17 bits
    writer.writeBits(0x7, count: 3)  // 20 bits — not yet byte-aligned
    writer.writeBits(0x0, count: 4)  // 24 bits — byte-aligned total (3 full bytes, no partial)
    let bytes = writer.finish()

    var reader = try BackwardBitReader(bytes)
    #expect(reader.readBits(16) == 0x1234)
    #expect(reader.readBits(3) == 0x7)
    #expect(reader.readBits(4) == 0x0)
  }

  @Test
  func backwardBitWriterHandlesA32BitField() throws {
    var writer = BackwardBitWriter()
    writer.writeBits(0xDEAD_BEEF, count: 32)
    let bytes = writer.finish()

    var reader = try BackwardBitReader(bytes)
    #expect(reader.readBits(32) == 0xDEAD_BEEF)
  }

  /// Many small fields in sequence — exercises `pushBit`'s byte-boundary-crossing loop many times
  /// over, the way a real Huffman/FSE stream with hundreds of symbols would.
  @Test
  func backwardBitWriterRoundTripsManySmallFieldsInOrder() throws {
    let values: [(UInt32, Int)] = (0..<200).map { i in (UInt32(i % 7), 3) }
    var writer = BackwardBitWriter()
    for (value, count) in values {
      writer.writeBits(value, count: count)
    }
    let bytes = writer.finish()

    var reader = try BackwardBitReader(bytes)
    for (value, count) in values {
      #expect(reader.readBits(count) == value)
    }
  }
}
