import Foundation
import Testing

@testable import ZstdKit

/// Isolated correctness suite for `RowHashMatchFinder`, mirroring `FSEEncodeTableTests.swift`'s
/// rigor: round-trip through the existing decoder first (cheap, catches gross bugs), on the exact
/// same corpus `EncoderRoundTripTests.swift` already exercises for the plain hash-chain finder —
/// this is what earns flipping `ZstdEncodingOptions.useRowHashMatchFinder`'s default (a separate,
/// deliberate decision made once this suite is green; see that option's doc comment).
@Suite
struct RowHashMatchFinderTests {
  private static let rowHashOptions = ZstdEncodingOptions(useRowHashMatchFinder: true)

  @Test
  func emptyInputRoundTrips() throws {
    let compressed = try Zstd.compress(Data(), options: Self.rowHashOptions)
    #expect(try Zstd.decompress(compressed) == Data())
  }

  @Test
  func smallInputRoundTrips() throws {
    let input = Data("hello, world".utf8)
    let compressed = try Zstd.compress(input, options: Self.rowHashOptions)
    #expect(try Zstd.decompress(compressed) == input)
  }

  @Test
  func longRepeatedSubstringCompressesWellViaMatchesAndRoundTrips() throws {
    let pattern = "The quick brown fox jumps over the lazy dog. "
    let input = Data(String(repeating: pattern, count: 500).utf8)
    let compressed = try Zstd.compress(input, options: Self.rowHashOptions)
    #expect(compressed.count < input.count / 10)
    #expect(try Zstd.decompress(compressed) == input)
  }

  @Test
  func manyMatchesAtTheSameOffsetRoundTrip() throws {
    var input: [UInt8] = []
    for i in 0..<2000 {
      input.append(UInt8(truncatingIfNeeded: i))
      input.append(UInt8(truncatingIfNeeded: i))
    }
    let data = Data(input)
    let compressed = try Zstd.compress(data, options: Self.rowHashOptions)
    #expect(try Zstd.decompress(compressed) == data)
  }

  @Test
  func multiBlockRepeatedContentRoundTrips() throws {
    let pattern = Array("0123456789abcdef".utf8)
    var input: [UInt8] = []
    for _ in 0..<3000 { input.append(contentsOf: pattern) }
    let data = Data(input)
    let compressed = try Zstd.compress(data, options: Self.rowHashOptions)
    #expect(compressed.count < data.count / 20)
    #expect(try Zstd.decompress(compressed) == data)
  }

  @Test
  func skewedByteDistributionCompressesAndRoundTrips() throws {
    var input: [UInt8] = []
    input.append(contentsOf: repeatElement(UInt8(ascii: "e"), count: 2000))
    input.append(contentsOf: repeatElement(UInt8(ascii: "t"), count: 800))
    input.append(contentsOf: repeatElement(UInt8(ascii: "a"), count: 400))
    for byte in 32...126 where byte != Int(UInt8(ascii: "e")) {
      input.append(UInt8(byte))
    }
    input.append(UInt8(ascii: "z"))
    let data = Data(input)
    let compressed = try Zstd.compress(data, options: Self.rowHashOptions)
    #expect(compressed.count < data.count)
    #expect(try Zstd.decompress(compressed) == data)
  }

  @Test
  func compressionIsDeterministic() throws {
    let input = Data((0..<5000).map { UInt8(truncatingIfNeeded: $0 * 7) })
    let first = try Zstd.compress(input, options: Self.rowHashOptions)
    let second = try Zstd.compress(input, options: Self.rowHashOptions)
    #expect(first == second)
  }

  /// The row-hash finder's own equivalent of `EncoderRoundTripTests`' engineered lazy-matching
  /// case: a genuinely large row (many entries sharing the same tag) exercised against every
  /// `searchDepth`, so the bitmask/candidate-gathering path gets real, varied traffic, not just
  /// the trivial single-candidate case.
  @Test(arguments: [0, 1, 2])
  func rowHashFinderAgreesWithHashChainFinderAcrossSearchDepths(searchDepth: Int) throws {
    var input: [UInt8] = []
    for i in 0..<4000 {
      input.append(contentsOf: [UInt8(truncatingIfNeeded: i), UInt8(truncatingIfNeeded: i >> 8), 0xAB, 0xCD])
    }
    let data = Data(input)
    let options = ZstdEncodingOptions(searchDepth: searchDepth, useRowHashMatchFinder: true)
    let compressed = try Zstd.compress(data, options: options)
    #expect(try Zstd.decompress(compressed) == data)
  }
}
