import Foundation

/// Orchestrates a full frame decode: header, then the block loop, then the trailing content
/// checksum if present. Every standard block/literals/sequences shape decodes now — see
/// `COMPRESSION_AND_STRETCH_GOALS_PLAN.md`'s staged decoder milestones for what's still deferred
/// (XXH64 checksum verification, dictionary support, the optimized/wildcopy path).
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
    // Same lifetime as `lastHuffmanTable`, for `.repeat_` sequence-symbol tables.
    var lastSequenceTables = SequenceTableSet()
    // Reset once per frame (RFC 8878 §3.1.1.3.2.1.2), threaded through every sequence in every
    // block of this frame — never reset per block.
    var repeatOffsets = RepeatOffsets()

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

        let sequencesHeader = try SequencesHeaderParser.parse(&blockReader)
        if sequencesHeader.numberOfSequences == 0 {
          output.append(contentsOf: decoded.literals)
        } else {
          let literalLengthTable = try SequenceTableBuilder.buildTable(
            mode: sequencesHeader.literalLengthsMode, kind: .literalLength,
            reader: &blockReader, previousTables: lastSequenceTables
          )
          let offsetTable = try SequenceTableBuilder.buildTable(
            mode: sequencesHeader.offsetsMode, kind: .offset,
            reader: &blockReader, previousTables: lastSequenceTables
          )
          let matchLengthTable = try SequenceTableBuilder.buildTable(
            mode: sequencesHeader.matchLengthsMode, kind: .matchLength,
            reader: &blockReader, previousTables: lastSequenceTables
          )
          lastSequenceTables.literalLengths = literalLengthTable
          lastSequenceTables.offsets = offsetTable
          lastSequenceTables.matchLengths = matchLengthTable

          let sequences = try SequenceStreamDecoder.decode(
            blockReader.remainingBytes(),
            count: sequencesHeader.numberOfSequences,
            literalLengthTable: literalLengthTable,
            offsetTable: offsetTable,
            matchLengthTable: matchLengthTable,
            repeatOffsets: &repeatOffsets
          )
          try SequenceExecutor.execute(
            literals: decoded.literals, sequences: sequences, into: &output, limits: limits
          )
        }
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
