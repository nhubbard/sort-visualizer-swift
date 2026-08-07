import Foundation
import Testing

@testable import ZstdKit

/// Round-trips `Zstd.compress` output through `Zstd.decompress` — the load-bearing self-
/// consistency gate every later milestone (RLE, Huffman-only literals, full LZ77+FSE) must keep
/// passing as blocks stop being emitted raw.
@Suite
struct EncoderRoundTripTests {
  @Test
  func emptyInputRoundTrips() throws {
    let compressed = try Zstd.compress(Data())
    let decompressed = try Zstd.decompress(compressed)
    #expect(decompressed == Data())
  }

  @Test
  func smallInputRoundTrips() throws {
    let input = Data("hello, world".utf8)
    let compressed = try Zstd.compress(input)
    let decompressed = try Zstd.decompress(compressed)
    #expect(decompressed == input)
  }

  @Test
  func allSameByteRoundTripsAsRLE() throws {
    let input = Data(repeating: 0x42, count: 10_000)
    let compressed = try Zstd.compress(input)
    #expect(compressed.count < 100, "an all-one-byte input should collapse to a tiny RLE block")
    let decompressed = try Zstd.decompress(compressed)
    #expect(decompressed == input)
  }

  @Test
  func singleByteInputRoundTrips() throws {
    let input = Data([0xFF])
    let compressed = try Zstd.compress(input)
    let decompressed = try Zstd.decompress(compressed)
    #expect(decompressed == input)
  }

  @Test
  func multiBlockInputRoundTrips() throws {
    // Comfortably larger than the 128 KiB block size, forcing multiple blocks.
    var input = [UInt8]()
    input.reserveCapacity(300_000)
    for i in 0..<300_000 {
      input.append(UInt8(truncatingIfNeeded: i))
    }
    let compressed = try Zstd.compress(Data(input))
    let decompressed = try Zstd.decompress(compressed)
    #expect([UInt8](decompressed) == input)
  }

  @Test
  func checksumMismatchIsDetectedOnTamperedOutput() throws {
    var compressed = [UInt8](try Zstd.compress(Data("tamper me".utf8)))
    compressed[compressed.count - 1] ^= 0xFF  // flip a bit in the checksum trailer
    #expect(throws: ZstdError.checksumMismatch) {
      try Zstd.decompress(Data(compressed))
    }
  }

  /// A skewed byte distribution (English-text-like: heavily weighted toward a handful of common
  /// bytes) is exactly what should trigger the Huffman-literals path — a uniform distribution
  /// (e.g. a repeating 0...255 ramp) gives Huffman nothing to exploit, so this needs a genuinely
  /// skewed input to actually exercise that code path rather than silently falling back to raw.
  @Test
  func skewedByteDistributionCompressesAndRoundTrips() throws {
    var input: [UInt8] = []
    // 'e' (very common) makes up half the input, 'z' (rare) a sliver, everything else a long tail.
    input.append(contentsOf: repeatElement(UInt8(ascii: "e"), count: 2000))
    input.append(contentsOf: repeatElement(UInt8(ascii: "t"), count: 800))
    input.append(contentsOf: repeatElement(UInt8(ascii: "a"), count: 400))
    for byte in 32...126 where byte != Int(UInt8(ascii: "e")) {
      input.append(UInt8(byte))
    }
    input.append(UInt8(ascii: "z"))
    let data = Data(input)

    let compressed = try Zstd.compress(data)
    #expect(
      compressed.count < data.count,
      "a skewed distribution should compress smaller than the raw input")
    let decompressed = try Zstd.decompress(compressed)
    #expect(decompressed == data)
  }

  /// A long repeated substring is exactly what the LZ77 match finder + FSE-coded sequences path
  /// exists to exploit — Huffman alone (the previous milestone) can't compress this much, since
  /// the byte *frequency* distribution here is close to uniform (each letter appears equally
  /// often); only recognizing the *repeated structure* helps. A real compression ratio here is
  /// the actual evidence the sequences path is winning, not just present in the code.
  @Test
  func longRepeatedSubstringCompressesWellViaMatchesAndRoundTrips() throws {
    let pattern = "The quick brown fox jumps over the lazy dog. "
    let input = Data(String(repeating: pattern, count: 500).utf8)

    let compressed = try Zstd.compress(input)
    #expect(
      compressed.count < input.count / 10,
      "repeating a ~46-byte pattern 500 times should compress far better than 10:1")
    let decompressed = try Zstd.decompress(compressed)
    #expect(decompressed == input)
  }

  /// Exercises the repeat-offset machinery specifically: many matches in a row at the *same*
  /// offset should be representable via the cheap `Offset_Code` 0/1 repeat slots, not by
  /// re-encoding a full explicit offset every time.
  @Test
  func manyMatchesAtTheSameOffsetRoundTrip() throws {
    var input: [UInt8] = []
    for i in 0..<2000 {
      input.append(UInt8(truncatingIfNeeded: i))
      input.append(UInt8(truncatingIfNeeded: i))  // immediate repeat -> offset 1 opportunities
    }
    let data = Data(input)
    let compressed = try Zstd.compress(data)
    let decompressed = try Zstd.decompress(compressed)
    #expect(decompressed == data)
  }

  /// A multi-block input where the match/entropy structure genuinely differs from the single-
  /// block cases above — large enough to force several 16,000-byte blocks, exercising repeat-
  /// offset persistence *across* block boundaries (`EncodeRepeatOffsets` is frame-scoped, reset
  /// once per frame, never per block — see `FrameEncoder`).
  @Test
  func multiBlockRepeatedContentRoundTrips() throws {
    let pattern = Array("0123456789abcdef".utf8)
    var input: [UInt8] = []
    for _ in 0..<3000 { input.append(contentsOf: pattern) }  // 48,000 bytes, 3+ blocks
    let data = Data(input)
    let compressed = try Zstd.compress(data)
    #expect(compressed.count < data.count / 20)
    let decompressed = try Zstd.decompress(compressed)
    #expect(decompressed == data)
  }

  @Test
  func compressionIsDeterministic() throws {
    let input = Data((0..<5000).map { UInt8(truncatingIfNeeded: $0 * 7) })
    let first = try Zstd.compress(input)
    let second = try Zstd.compress(input)
    #expect(first == second)
  }

  @Test(arguments: [0, 1, 2])
  func everySearchDepthRoundTripsARepeatedPattern(searchDepth: Int) throws {
    let pattern = "The quick brown fox jumps over the lazy dog. "
    let input = Data(String(repeating: pattern, count: 500).utf8)
    let options = ZstdEncodingOptions(searchDepth: searchDepth)
    let compressed = try Zstd.compress(input, options: options)
    let decompressed = try Zstd.decompress(compressed)
    #expect(decompressed == input)
  }

  /// The direct, engineered proof that `searchDepth >= 1` does real work, not just plumbing: a
  /// greedy (`searchDepth: 0`) pass takes an immediate length-4 match at `ip`, capped by
  /// construction so it can't extend further, while a length-39 match to a much earlier position
  /// is available starting exactly one byte later — `depth >= 1` must wait for it. `decoySource`
  /// (`[x] + long[1...3]`, positions 40-43) is a real, independent earlier occurrence of the same
  /// 4-gram the immediate match at the test region's `x` byte finds; `afterDecoyByte` deliberately
  /// differs from `long[4]` so referencing `decoySource` can never extend past 4 bytes by
  /// accident, keeping the "immediate" candidate's length pinned at exactly 4 regardless of
  /// anything else in this construction.
  @Test
  func lazyMatchingChoosesALongerMatchOverAnImmediateShortOne() throws {
    let long: [UInt8] = (0..<40).map { UInt8(20 + ($0 * 37) % 200) }
    let x: UInt8 = 250
    var input: [UInt8] = long  // positions 0-39
    input.append(x)  // position 40
    input.append(contentsOf: long[1...3])  // positions 41-43
    let afterDecoyByte: UInt8 = long[4] == 255 ? long[4] - 1 : long[4] + 1
    input.append(afterDecoyByte)  // position 44
    input.append(contentsOf: [1, 2, 3, 4, 5])  // filler, positions 45-49
    input.append(x)  // position 50 (== test region start)
    input.append(contentsOf: long[1...])  // positions 51-89

    let greedyStore = BlockParser.parse(input, options: ZstdEncodingOptions(searchDepth: 0))
    #expect(greedyStore.sequences.first?.matchLength == 4, "greedy should take the immediate short match")

    let lazyStore = BlockParser.parse(input, options: ZstdEncodingOptions(searchDepth: 1))
    #expect(
      lazyStore.sequences.first?.matchLength == 39,
      "depth >= 1 should find the longer match one byte later instead")

    let greedyCompressed = try Zstd.compress(Data(input), options: ZstdEncodingOptions(searchDepth: 0))
    let lazyCompressed = try Zstd.compress(Data(input), options: ZstdEncodingOptions(searchDepth: 2))
    #expect(
      lazyCompressed.count < greedyCompressed.count,
      "lazy2 should compress this input strictly better than greedy")

    #expect(try Zstd.decompress(greedyCompressed) == Data(input))
    #expect(try Zstd.decompress(lazyCompressed) == Data(input))
  }
}
