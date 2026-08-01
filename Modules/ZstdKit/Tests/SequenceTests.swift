import Foundation
import Testing

@testable import ZstdKit

/// Milestone C/D: FSE-coded sequences and LZ77 execution. Each fixture's exact
/// Symbol_Compression_Mode combination (Predefined/RLE/FSE_Compressed/Repeat) was confirmed by
/// `FixtureGenerator/generate.py`'s own reference parser at generation time — see its module
/// comments for how each shape was found.
@Suite
struct SequenceTests {
  private func assertRoundTrip(_ name: String) throws {
    let compressed = try Fixture.compressed(name)
    let expected = try Fixture.expected(name)
    let decoded = try Zstd.decompress(compressed)
    #expect(decoded == expected, "\(name): decoded output didn't match the recorded plaintext")
  }

  @Test func predefinedTablesForAllThreeSymbolTypes() throws {
    try assertRoundTrip("sequences_predefined_tables")
  }

  @Test func rleTablesForOffsetAndMatchLength() throws {
    try assertRoundTrip("sequences_rle_tables")
  }

  @Test func fseCompressedTablesWithGenuineMatches() throws {
    try assertRoundTrip("compressed_block_with_sequences")
  }

  /// Real, large, production-shaped content (concatenated `AlgorithmDetails/*/*.md`) spanning 4
  /// blocks — `Compressed`/`Treeless`/`Raw` literals and `FSE_Compressed`/`Repeat` sequence
  /// tables all appear naturally across it. This is the closest thing to an end-to-end proof that
  /// the decoder is ready for the real `AlgorithmDetails.algz` archive.
  @Test func repeatModeTablesAcrossMultipleBlocks() throws {
    try assertRoundTrip("sequences_repeat_and_multiblock")
  }

  // MARK: - Malformed sequence streams

  @Test func repeatModeWithNoPriorTableThrows() throws {
    // Symbol_Compression_Modes byte requesting Repeat (0b11) for all three types, on a frame
    // whose very first block has no earlier table to repeat.
    let descriptor: UInt8 = 0b0010_0000  // single segment, FCS_flag 0 -> 1-byte content size
    let literalsHeader: UInt8 = 0  // raw literals, 1-byte header, regeneratedSize 0
    let sequencesCount: UInt8 = 1
    let modesByte: UInt8 = 0b1111_1100  // LL=repeat, OF=repeat, ML=repeat, reserved=0
    let blockContent: [UInt8] = [literalsHeader, sequencesCount, modesByte]
    let block = blockHeaderBytes(isLast: true, blockType: 2, blockSize: blockContent.count) + blockContent
    let bytes = Data([0x28, 0xB5, 0x2F, 0xFD, descriptor, 0]) + block
    #expect(throws: ZstdError.invalidSequenceStream) {
      try Zstd.decompress(bytes)
    }
  }

  @Test func reservedSymbolCompressionModeBitsThrow() throws {
    let descriptor: UInt8 = 0b0010_0000
    let literalsHeader: UInt8 = 0
    let sequencesCount: UInt8 = 1
    let modesByte: UInt8 = 0b0000_0001  // reserved low bits nonzero
    let blockContent: [UInt8] = [literalsHeader, sequencesCount, modesByte]
    let block = blockHeaderBytes(isLast: true, blockType: 2, blockSize: blockContent.count) + blockContent
    let bytes = Data([0x28, 0xB5, 0x2F, 0xFD, descriptor, 0]) + block
    #expect(throws: ZstdError.invalidSequenceStream) {
      try Zstd.decompress(bytes)
    }
  }
}

/// Independent of `Internal/BlockHeader.swift` — see `MalformedInputTests.swift`.
private func blockHeaderBytes(isLast: Bool, blockType: UInt8, blockSize: Int) -> Data {
  let raw = (isLast ? 1 : 0) | (UInt32(blockType) << 1) | (UInt32(blockSize) << 3)
  return Data([UInt8(raw & 0xFF), UInt8((raw >> 8) & 0xFF), UInt8((raw >> 16) & 0xFF)])
}
