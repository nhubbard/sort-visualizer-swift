import Foundation
import Testing

@testable import ZstdKit

/// Cross-checks `ZstdKit` against the real Zstandard project's own test corpus
/// (`~/zstd/tests/golden-*`, `~/zstd/tests/decodecorpus`), not just this project's own
/// hand-picked/self-generated fixtures — see `COMPRESSION_DESIGN.md`'s "Verification" section for
/// why self-round-trip alone is insufficient for this kind of port. Every fixture here was
/// oracle-verified once, offline, against the real `zstd`/`unzstd` CLI before being committed
/// (mirroring `FixtureGenerator/generate.py`'s own "self-verified against the reference before
/// being written" pattern) — nothing in this file ever shells out or requires zstd installed to
/// run `swift test`. See `FixtureGenerator/README.md` for exact regeneration commands.
@Suite
struct GoldenCorpusTests {
  // MARK: - golden-decompression: real zstd-produced frames ZstdKit must decode correctly

  @Test(
    arguments: [
      "golden_decompression_block_128k",
      "golden_decompression_empty_block",
      "golden_decompression_rle_first_block",
      "golden_decompression_zeroSeq_2B"
    ]
  )
  func decodesGoldenFrameExactly(name: String) throws {
    let compressed = try Fixture.compressed(name)
    let expected = try Fixture.expected(name)
    let decompressed = try Zstd.decompress(compressed)
    #expect(decompressed == expected)
  }

  // MARK: - golden-decompression-errors: real zstd itself rejects these; so must ZstdKit

  @Test(
    arguments: [
      "golden_decompression_error_off0_bin",
      "golden_decompression_error_truncated_huff_state",
      "golden_decompression_error_zeroSeq_extraneous"
    ]
  )
  func rejectsGoldenMalformedFrame(name: String) throws {
    let compressed = try Fixture.compressed(name)
    #expect(throws: (any Error).self) {
      try Zstd.decompress(compressed)
    }
  }

  // MARK: - golden-compression: real-world/regression-shaped inputs, compressed by ZstdKit's own
  // encoder and oracle-verified via real `unzstd` at fixture-authoring time (not test time). Each
  // `.zst` here pins that verified output byte-for-byte, so a future encoder change that produces
  // different (even if still valid) bytes fails loudly instead of silently drifting.

  @Test(
    arguments: [
      "golden_compression_http",
      "golden_compression_huffman_compressed_larger",
      "golden_compression_large_literal_and_match_lengths",
      "golden_compression_pr_3517_block_splitter_corruption_test"
    ]
  )
  func goldenCompressionInputDecodesToOriginal(name: String) throws {
    let compressed = try Fixture.compressed(name)
    let expected = try Fixture.expected(name)
    let decompressed = try Zstd.decompress(compressed)
    #expect(decompressed == expected)
  }

  @Test(
    arguments: [
      "golden_compression_http",
      "golden_compression_huffman_compressed_larger",
      "golden_compression_large_literal_and_match_lengths",
      "golden_compression_pr_3517_block_splitter_corruption_test"
    ]
  )
  func goldenCompressionEncoderOutputIsPinned(name: String) throws {
    let expected = try Fixture.expected(name)
    let pinnedFrame = try Fixture.compressed(name)
    let freshlyCompressed = try Zstd.compress(expected)
    #expect(
      freshlyCompressed == pinnedFrame,
      "encoder output for \(name) changed -- re-verify against real zstd and regenerate the fixture if intentional"
    )
  }

  // MARK: - decodecorpus: upstream's own synthetic-valid-frame generator (`~/zstd/tests/
  // decodecorpus`), run offline across 6 batches -- default random shapes at two content-size
  // caps (`-s7`/`-s13`), each block type forced explicitly (`-s21`/`-s22`/`-s23`
  // --block-type=0/1/2`), and content-size always declared (`-s31 --content-size`) -- and verified
  // frame-by-frame against real `unzstd` before being committed. See `FixtureGenerator/README.md`
  // for the exact commands. Exercises the space of valid frame shapes (window sizes, single/multi-
  // segment, checksum on/off, content-size field widths, block splits, every block type) far
  // beyond anything this project's own encoder happens to produce.

  @Test(arguments: 0..<800)
  func decodesDecodecorpusFrame(index: Int) throws {
    let name = "decodecorpus_\(String(format: "%03d", index))"
    let compressed = try Fixture.compressed(name)
    let expected = try Fixture.expected(name)
    let decompressed = try Zstd.decompress(compressed)
    #expect(decompressed == expected)
  }
}
