import Foundation
import Testing

@testable import ZstdKit

/// Milestone A: magic/frame-header parsing, the block loop, `Raw_Block`/`RLE_Block`, and the
/// checksum-trailer skip — every fixture here is decodable without `.compressed` block support.
@Suite
struct FrameShellTests {
  private func assertRoundTrip(_ name: String) throws {
    let compressed = try Fixture.compressed(name)
    let expected = try Fixture.expected(name)
    let decoded = try Zstd.decompress(compressed)
    #expect(decoded == expected, "\(name): decoded output didn't match the recorded plaintext")
  }

  @Test func empty() throws {
    try assertRoundTrip("empty")
  }

  @Test func rawSingleSegment() throws {
    try assertRoundTrip("raw_single_segment")
  }

  @Test func checksumTrailerIsSkippedNotVerified() throws {
    // XXH64 verification is a later milestone; for now this just proves the trailing 4 bytes are
    // consumed correctly rather than misread as trailing data or a second frame.
    try assertRoundTrip("checksum_trailer")
  }

  @Test func rleSingleSegment() throws {
    try assertRoundTrip("rle_single_segment")
  }

  @Test func rleWindowedKnownSize() throws {
    try assertRoundTrip("rle_windowed_known_size")
  }

  @Test func rawWindowedUnknownSize() throws {
    try assertRoundTrip("raw_windowed_unknown_size")
  }

  @Test func mixedRawAndRLEBlocksAcrossMultipleBlocks() throws {
    try assertRoundTrip("mixed_raw_and_rle_blocks")
  }

  @Test func dictionaryIDPresentThrowsDictionaryRequired() throws {
    let compressed = try Fixture.compressed("dictionary_id_present")
    do {
      _ = try Zstd.decompress(compressed)
      Issue.record("expected .dictionaryRequired to be thrown")
    } catch ZstdError.dictionaryRequired {
      // Expected — the exact ID varies by fixture-generation run, so only the case is checked.
    } catch {
      Issue.record("expected .dictionaryRequired, got \(error)")
    }
  }
}
