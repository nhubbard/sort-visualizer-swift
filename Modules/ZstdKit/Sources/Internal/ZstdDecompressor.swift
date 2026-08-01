import Foundation

/// Orchestrates a full frame decode: header, then the block loop, then the trailing content
/// checksum if present. `.compressed` blocks with a nonzero sequence count still throw —
/// FSE-coded sequence decoding and LZ77 execution are later milestones (see
/// `COMPRESSION_AND_STRETCH_GOALS_PLAN.md`'s staged decoder milestones). A block with zero
/// sequences is fully decodable now: its literals section *is* the block's entire output.
enum ZstdDecompressor {
  static func decompress(_ data: Data, limits: ZstdDecodingLimits) throws -> Data {
    guard data.count <= limits.maximumFrameSize else {
      throw ZstdError.frameSizeExceeded(requested: data.count, limit: limits.maximumFrameSize)
    }

    var reader = ByteReader([UInt8](data))
    let header = try FrameHeaderParser.parse(&reader, limits: limits)

    var output: [UInt8] = []
    if let frameContentSize = header.frameContentSize {
      output.reserveCapacity(frameContentSize)
    }

    // Persists across blocks within this frame (never across separate `decompress` calls) so a
    // `.treeless` block can reuse the table the most recent `.compressed` block built.
    var lastHuffmanTable: HuffmanDecodeTable?

    var blockCount = 0
    var isLastBlock = false
    while !isLastBlock {
      blockCount += 1
      guard blockCount <= limits.maximumBlockCount else {
        throw ZstdError.blockCountExceeded(limit: limits.maximumBlockCount)
      }

      let blockHeader = try BlockHeaderParser.parse(&reader)
      isLastBlock = blockHeader.isLastBlock

      switch blockHeader.blockType {
      case .raw:
        output.append(contentsOf: try reader.readBytes(blockHeader.blockSize))
      case .rle:
        let byte = try reader.readByte()
        output.append(contentsOf: repeatElement(byte, count: blockHeader.blockSize))
      case .compressed:
        var blockReader = ByteReader(Array(try reader.readBytes(blockHeader.blockSize)))
        let literalsHeader = try LiteralsSectionParser.parse(&blockReader)
        let decoded = try LiteralsSectionDecoder.decode(
          header: literalsHeader,
          sectionBytes: blockReader.remainingBytes(),
          previousHuffmanTable: lastHuffmanTable
        )
        lastHuffmanTable = decoded.huffmanTable

        let literalsSectionByteCount =
          literalsHeader.blockType == .raw || literalsHeader.blockType == .rle
          ? literalsHeader.regeneratedSize : literalsHeader.compressedSize
        try blockReader.skip(literalsSectionByteCount)

        // Only Number_of_Sequences == 0 is decodable so far: the whole block is then just its
        // literals, with no LZ77 matches. A single peeked byte is enough to tell zero from
        // nonzero without needing the full variable-length count encoding (Milestone C's job).
        let firstSequenceByte = try blockReader.readByte()
        guard firstSequenceByte == 0 else {
          throw ZstdError.unsupportedFrameFeature("FSE-coded sequences are not implemented yet")
        }
        output.append(contentsOf: decoded.literals)
      }

      guard output.count <= limits.maximumOutputSize else {
        throw ZstdError.outputLimitExceeded(requested: output.count, limit: limits.maximumOutputSize)
      }
    }

    if let frameContentSize = header.frameContentSize, output.count != frameContentSize {
      throw ZstdError.contentSizeMismatch(expected: frameContentSize, actual: output.count)
    }

    if header.contentChecksumFlag {
      // XXH64 verification is a separate milestone; consuming these 4 bytes here keeps frame-length
      // accounting (and the trailing-data check below) correct in the meantime.
      _ = try reader.readBytes(4)
    }

    guard reader.remaining == 0 else {
      throw ZstdError.trailingData
    }

    return Data(output)
  }
}
