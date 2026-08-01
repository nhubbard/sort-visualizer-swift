struct DecodedLiteralsSection {
  let literals: [UInt8]
  /// The Huffman table this section used — `nil` for `.raw`/`.rle`, carried forward by the
  /// caller so a following `.treeless` block in the same frame can reuse it.
  let huffmanTable: HuffmanDecodeTable?
}

enum LiteralsSectionDecoder {
  /// `sectionBytes` starts immediately after the literals section header. `previousHuffmanTable`
  /// is whatever a prior `.compressed` block in this frame built, required for `.treeless`.
  static func decode(
    header: LiteralsSectionHeader,
    sectionBytes: ArraySlice<UInt8>,
    previousHuffmanTable: HuffmanDecodeTable?
  ) throws -> DecodedLiteralsSection {
    switch header.blockType {
    case .raw:
      guard sectionBytes.count >= header.regeneratedSize else { throw ZstdError.invalidLiteralsSection }
      let start = sectionBytes.startIndex
      let literals = Array(sectionBytes[start..<(start + header.regeneratedSize)])
      return DecodedLiteralsSection(literals: literals, huffmanTable: previousHuffmanTable)

    case .rle:
      guard let byte = sectionBytes.first else { throw ZstdError.invalidLiteralsSection }
      let literals = [UInt8](repeating: byte, count: header.regeneratedSize)
      return DecodedLiteralsSection(literals: literals, huffmanTable: previousHuffmanTable)

    case .compressed, .treeless:
      guard sectionBytes.count >= header.compressedSize else { throw ZstdError.invalidLiteralsSection }
      let start = sectionBytes.startIndex
      let huffmanBlob = sectionBytes[start..<(start + header.compressedSize)]

      let table: HuffmanDecodeTable
      var bodyStart = huffmanBlob.startIndex
      if header.blockType == .compressed {
        let parsed = try HuffmanTableBuilder.parse(huffmanBlob)
        table = parsed.table
        bodyStart = huffmanBlob.startIndex + parsed.consumedBytes
      } else {
        guard let previousHuffmanTable else { throw ZstdError.invalidLiteralsSection }
        table = previousHuffmanTable
      }
      guard bodyStart <= huffmanBlob.endIndex else { throw ZstdError.invalidLiteralsSection }
      let body = huffmanBlob[bodyStart...]

      let literals: [UInt8]
      if header.streamCount == 1 {
        literals = try HuffmanStreamDecoder.decode(body, count: header.regeneratedSize, table: table)
      } else {
        literals = try decodeFourStreams(body, regeneratedSize: header.regeneratedSize, table: table)
      }
      return DecodedLiteralsSection(literals: literals, huffmanTable: table)
    }
  }

  /// Jump_Table (RFC 8878 §3.1.1.3.1.6): 3 little-endian `UInt16` compressed sizes for streams
  /// 1-3; stream 4's compressed size is whatever bytes remain. Streams 1-3 each decode
  /// `ceil(regeneratedSize / 4)` symbols; stream 4 decodes the remainder.
  private static func decodeFourStreams(
    _ body: ArraySlice<UInt8>, regeneratedSize: Int, table: HuffmanDecodeTable
  ) throws -> [UInt8] {
    guard body.count >= 6 else { throw ZstdError.invalidLiteralsSection }
    let base = body.startIndex
    let stream1Size = Int(body[base]) | (Int(body[base + 1]) << 8)
    let stream2Size = Int(body[base + 2]) | (Int(body[base + 3]) << 8)
    let stream3Size = Int(body[base + 4]) | (Int(body[base + 5]) << 8)

    let streamsStart = base + 6
    let stream1End = streamsStart + stream1Size
    let stream2End = stream1End + stream2Size
    let stream3End = stream2End + stream3Size
    guard stream3End <= body.endIndex else { throw ZstdError.invalidLiteralsSection }

    let segmentSize = (regeneratedSize + 3) / 4
    let lastSegmentSize = regeneratedSize - 3 * segmentSize
    guard lastSegmentSize >= 0 else { throw ZstdError.invalidLiteralsSection }

    var literals: [UInt8] = []
    literals.reserveCapacity(regeneratedSize)
    literals += try HuffmanStreamDecoder.decode(body[streamsStart..<stream1End], count: segmentSize, table: table)
    literals += try HuffmanStreamDecoder.decode(body[stream1End..<stream2End], count: segmentSize, table: table)
    literals += try HuffmanStreamDecoder.decode(body[stream2End..<stream3End], count: segmentSize, table: table)
    literals += try HuffmanStreamDecoder.decode(body[stream3End...], count: lastSegmentSize, table: table)
    return literals
  }
}
