import Foundation
import Testing

@testable import ZstdKit

/// Milestone B: Huffman-coded literals (`Compressed`/`Treeless` literals sections), tested via
/// real zstd fixtures whose sequences count happens to be zero — so the block's entire output is
/// exactly its literals section, letting this land before FSE-coded sequences (Milestone C) exist.
@Suite
struct HuffmanTests {
  private func assertRoundTrip(_ name: String) throws {
    let compressed = try Fixture.compressed(name)
    let expected = try Fixture.expected(name)
    let decoded = try Zstd.decompress(compressed)
    #expect(decoded == expected, "\(name): decoded output didn't match the recorded plaintext")
  }

  @Test func oneStreamFSECompressedWeights() throws {
    try assertRoundTrip("huffman_one_stream_zero_sequences")
  }

  @Test func fourStreamFSECompressedWeights() throws {
    try assertRoundTrip("huffman_four_stream_zero_sequences")
  }

  @Test func treelessReusesThePreviousBlocksTable() throws {
    try assertRoundTrip("huffman_treeless_zero_sequences")
  }

  /// A block with a nonzero sequence count is still explicitly unsupported (Milestone C) — this
  /// fixture's content is repetitive enough to force genuine LZ77 matches, so it also proves the
  /// "peek one byte to check for zero" logic in `ZstdDecompressor` doesn't misfire on ordinary
  /// compressed content that isn't the literals-only special case the rest of this suite covers.
  @Test func nonzeroSequenceCountThrowsUnsupportedFrameFeature() throws {
    let compressed = try Fixture.compressed("compressed_block_with_sequences")
    do {
      _ = try Zstd.decompress(compressed)
      Issue.record("expected .unsupportedFrameFeature for a block with real sequences")
    } catch ZstdError.unsupportedFrameFeature {
      // Expected.
    } catch {
      Issue.record("expected .unsupportedFrameFeature, got \(error)")
    }
  }

  // --- Huffman weight direct-encoding: no real zstd fixture was found to trigger this path
  // (the reference encoder always preferred FSE-compressed weights in every input shape tried
  // during development — see FixtureGenerator's history). This is a self-consistency check only:
  // it proves the direct-weight parsing branch and the canonical table builder agree with each
  // other, not that they match the reference encoder's exact byte layout for this case.

  @Test func directHuffmanWeightsSelfConsistency() throws {
    // 2 *explicit* weights (header byte 127+2=129) packed as one byte of 4-bit nibbles (RFC 8878
    // §4.2.1.1: high nibble = even-indexed symbol, low nibble = odd-indexed), plus a 3rd, implicit
    // last weight that's never packed — 3 symbols total.
    let headerByte: UInt8 = 129  // 127 + 2 explicit symbols

    // Kraft sum check done by hand: weight 2 -> 2^1=2, weight 1 -> 2^0=1; explicit total = 3;
    // next power of two = 4; implicit last weight's contribution = 1 -> weight 1.
    // So all three symbols end up with weights [2, 1, 1] (last one derived, not packed).
    let packedWeights: UInt8 = 0x21  // symbol0=2 (high nibble), symbol1=1 (low nibble)
    let blob: [UInt8] = [headerByte, packedWeights]
    let parsed = try HuffmanTableBuilder.parse(blob[...])
    #expect(parsed.consumedBytes == 2)
    #expect(parsed.table.maxBits == 2)
  }
}
