import Foundation
import Testing

@testable import ZstdKit

/// Hand-crafted byte sequences a real encoder never produces, proving the parser throws a
/// specific `ZstdError` instead of trapping or silently misreading. Independent of
/// `FixtureGenerator/generate.py` — these bytes are built right here so this file doesn't rely on
/// the same construction logic twice.
@Suite
struct MalformedInputTests {
  @Test func emptyInputThrowsTruncatedInput() {
    #expect(throws: ZstdError.truncatedInput) {
      try Zstd.decompress(Data())
    }
  }

  @Test func partialMagicThrowsTruncatedInput() {
    #expect(throws: ZstdError.truncatedInput) {
      try Zstd.decompress(Data([0x28, 0xB5]))
    }
  }

  @Test func wrongMagicThrowsInvalidMagic() {
    let bytes = Data([0x00, 0x00, 0x00, 0x00, 0x20, 0x00, 0x01, 0x00, 0x00])
    #expect(throws: ZstdError.invalidMagic) {
      try Zstd.decompress(bytes)
    }
  }

  @Test func skippableFrameMagicThrowsUnsupportedFrameFeature() {
    // Skippable-frame magic range is 0x184D2A50...0x184D2A5F, stored little-endian.
    let bytes = Data([0x50, 0x2A, 0x4D, 0x18, 0x00, 0x00, 0x00, 0x00])
    do {
      _ = try Zstd.decompress(bytes)
      Issue.record("expected .unsupportedFrameFeature to be thrown")
    } catch ZstdError.unsupportedFrameFeature {
      // Expected.
    } catch {
      Issue.record("expected .unsupportedFrameFeature, got \(error)")
    }
  }

  @Test func reservedHeaderBitThrowsInvalidFrameHeader() {
    // Magic + descriptor with Single_Segment_flag (bit 5) and Reserved_bit (bit 3) both set.
    // The parser must reject this before reading anything past the descriptor byte.
    let descriptor: UInt8 = 0b0010_1000
    let bytes = Data([0x28, 0xB5, 0x2F, 0xFD, descriptor])
    #expect(throws: ZstdError.invalidFrameHeader) {
      try Zstd.decompress(bytes)
    }
  }

  @Test func reservedBlockTypeThrowsInvalidBlockHeader() {
    // Single-segment frame, Frame_Content_Size = 0, followed by a block header declaring the
    // reserved block type (3).
    let descriptor: UInt8 = 0b0010_0000  // single segment, FCS_flag 0 -> 1-byte content size
    let contentSize: UInt8 = 0
    let blockTypeReservedLastBlock = blockHeaderBytes(isLast: true, blockType: 3, blockSize: 0)
    let bytes = Data([0x28, 0xB5, 0x2F, 0xFD, descriptor, contentSize]) + blockTypeReservedLastBlock
    #expect(throws: ZstdError.invalidBlockHeader) {
      try Zstd.decompress(bytes)
    }
  }

  @Test func declaredContentSizeMismatchThrows() {
    // Declares Frame_Content_Size = 5 but the single raw block only supplies 3 bytes.
    let descriptor: UInt8 = 0b0010_0000
    let contentSize: UInt8 = 5
    let block = blockHeaderBytes(isLast: true, blockType: 0, blockSize: 3) + Data([0xAA, 0xBB, 0xCC])
    let bytes = Data([0x28, 0xB5, 0x2F, 0xFD, descriptor, contentSize]) + block
    #expect(throws: ZstdError.contentSizeMismatch(expected: 5, actual: 3)) {
      try Zstd.decompress(bytes)
    }
  }

  @Test func trailingDataAfterACompleteFrameThrows() throws {
    let validFrame = try Fixture.compressed("empty")
    let withTrailingByte = validFrame + Data([0xFF])
    #expect(throws: ZstdError.trailingData) {
      try Zstd.decompress(withTrailingByte)
    }
  }

  /// Every proper prefix of a known-good frame must either be rejected with a `ZstdError` or
  /// (only at full length) succeed — never crash, never silently return wrong data.
  @Test(arguments: ["empty", "raw_single_segment", "mixed_raw_and_rle_blocks", "checksum_trailer"])
  func everyProperPrefixIsRejectedOrCorrect(fixtureName: String) throws {
    let full = try Fixture.compressed(fixtureName)
    let expected = try Fixture.expected(fixtureName)

    for length in 0..<full.count {
      let prefix = full.prefix(length)
      do {
        let decoded = try Zstd.decompress(prefix)
        Issue.record(
          "\(fixtureName)[0..<\(length)] unexpectedly succeeded with \(decoded.count) bytes (full decode is \(expected.count) bytes)"
        )
      } catch is ZstdError {
        // Expected — truncated input must be rejected, not misread.
      } catch {
        Issue.record("\(fixtureName)[0..<\(length)]: unexpected non-ZstdError \(error)")
      }
    }
  }
}

/// Independent of `Internal/BlockHeader.swift` — builds the 3-byte little-endian block header by
/// hand so this test file doesn't validate the parser against its own production encoding logic.
private func blockHeaderBytes(isLast: Bool, blockType: UInt8, blockSize: Int) -> Data {
  let raw = (isLast ? 1 : 0) | (UInt32(blockType) << 1) | (UInt32(blockSize) << 3)
  return Data([UInt8(raw & 0xFF), UInt8((raw >> 8) & 0xFF), UInt8((raw >> 16) & 0xFF)])
}
