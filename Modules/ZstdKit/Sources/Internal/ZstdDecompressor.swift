// This file's frame-decode orchestration (header, then the block loop, then the checksum
// trailer) mirrors the real `zstd` C source's top-level decompression flow. See NOTICE.md.
//
// Used under the BSD License:
//
// BSD License
//
// For Zstandard software
//
// Copyright (c) Meta Platforms, Inc. and affiliates. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without modification,
// are permitted provided that the following conditions are met:
//
//  * Redistributions of source code must retain the above copyright notice, this
//    list of conditions and the following disclaimer.
//
//  * Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions and the following disclaimer in the documentation
//    and/or other materials provided with the distribution.
//
//  * Neither the name Facebook, nor Meta, nor the names of its contributors may
//    be used to endorse or promote products derived from this software without
//    specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
// ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
// WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR
// ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
// (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
// LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
// ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
// SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

import Foundation

/// Orchestrates a full frame decode: header, then the block loop, then the trailing content
/// checksum if present. Every standard block/literals/sequences shape decodes, with the optimized
/// wildcopy/bit-reader path wired in — see `COMPRESSION_DESIGN.md` for the full decoder-
/// completeness/performance rundown. Dictionary support is the one generic `ZstdKit` capability
/// not required (or exercised) by `AlgorithmDetails.algz`.
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
      let trailer = try reader.readLittleEndianUInt(byteCount: 4)
      let expected = UInt32(truncatingIfNeeded: trailer)
      let actual = XXH64.checksum32(output)
      guard actual == expected else { throw ZstdError.checksumMismatch }
    }

    guard reader.remaining == 0 else {
      throw ZstdError.trailingData
    }

    return Data(output)
  }
}
