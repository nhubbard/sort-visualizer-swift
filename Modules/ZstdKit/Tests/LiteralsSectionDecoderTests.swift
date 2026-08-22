import Testing

@testable import ZstdKit

/// Sequential (one stream fully decoded, then the next) reimplementation of
/// `LiteralsSectionDecoder.decodeFourStreams`'s old behavior, kept only as this test's
/// correctness oracle for the interleaved version.
private func decodeFourStreamsSequentially(
  _ body: ArraySlice<UInt8>, regeneratedSize: Int, table: HuffmanDecodeTable
) throws -> [UInt8] {
  let base = body.startIndex
  let stream1Size = Int(body[base]) | (Int(body[base + 1]) << 8)
  let stream2Size = Int(body[base + 2]) | (Int(body[base + 3]) << 8)
  let stream3Size = Int(body[base + 4]) | (Int(body[base + 5]) << 8)

  let streamsStart = base + 6
  let stream1End = streamsStart + stream1Size
  let stream2End = stream1End + stream2Size
  let stream3End = stream2End + stream3Size

  let segmentSize = (regeneratedSize + 3) / 4
  let lastSegmentSize = regeneratedSize - 3 * segmentSize

  var literals: [UInt8] = []
  literals.reserveCapacity(regeneratedSize)
  literals += try HuffmanStreamDecoder.decode(body[streamsStart..<stream1End], count: segmentSize, table: table)
  literals += try HuffmanStreamDecoder.decode(body[stream1End..<stream2End], count: segmentSize, table: table)
  literals += try HuffmanStreamDecoder.decode(body[stream2End..<stream3End], count: segmentSize, table: table)
  literals += try HuffmanStreamDecoder.decode(body[stream3End...], count: lastSegmentSize, table: table)
  return literals
}

/// Differential test: the four-stream literals decoder was restructured from four sequential
/// `HuffmanStreamDecoder.decode` calls into one round-robin loop over four independent readers.
/// The streams share no bitstream state, so this is a pure performance change — but it's checked
/// against the old ordering anyway, on the same real fixture `HuffmanTests` uses for four-stream
/// coverage.
@Suite
struct LiteralsSectionDecoderTests {
  @Test func interleavedMatchesSequentialOnRealFourStreamFixture() throws {
    let compressed = try Fixture.compressed("huffman_four_stream_zero_sequences")
    var reader = ByteReader([UInt8](compressed))
    _ = try FrameHeaderParser.parse(&reader, limits: .default)
    let blockHeader = try BlockHeaderParser.parse(&reader)
    #expect(blockHeader.blockType == .compressed)
    var blockReader = ByteReader(Array(try reader.readBytes(blockHeader.blockSize)))
    let literalsHeader = try LiteralsSectionParser.parse(&blockReader)
    #expect(literalsHeader.streamCount == 4)

    let sectionBytes = blockReader.remainingBytes()
    let huffmanBlob = sectionBytes[sectionBytes.startIndex..<(sectionBytes.startIndex + literalsHeader.compressedSize)]
    let parsed = try HuffmanTableBuilder.parse(huffmanBlob)
    let body = huffmanBlob[(huffmanBlob.startIndex + parsed.consumedBytes)...]

    let interleaved = try LiteralsSectionDecoder.decodeFourStreams(
      body, regeneratedSize: literalsHeader.regeneratedSize, table: parsed.table
    )
    let sequential = try decodeFourStreamsSequentially(
      body, regeneratedSize: literalsHeader.regeneratedSize, table: parsed.table
    )
    #expect(interleaved == sequential)
    #expect(interleaved.count == literalsHeader.regeneratedSize)
  }
}
