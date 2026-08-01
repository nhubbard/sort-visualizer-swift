// This file's literals-section decode flow (raw/RLE/compressed/treeless dispatch, the
// four-stream jump table) is transcribed from Zstandard's literals format (RFC 8878
// §3.1.1.3) as implemented by the real `zstd` C source. See NOTICE.md.
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
  ///
  /// The four streams are decoded as four independent scalar states advanced one symbol at a
  /// time in a single round-robin loop, rather than one stream fully decoded after another —
  /// this is where reference zstd's "four-stream" format actually earns its keep: the streams
  /// share no bitstream state, so interleaving their independent peek/consume chains is exactly
  /// as correct as decoding them one after another (same bytes go to the same output positions
  /// either way — `LiteralsSectionDecoderTests` checks the two orderings against each other
  /// directly), while letting the CPU pipeline four independent dependency chains per round
  /// instead of one long one four times over.
  static func decodeFourStreams(
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

    let segments: [(range: Range<Int>, count: Int)] = [
      (streamsStart..<stream1End, segmentSize),
      (stream1End..<stream2End, segmentSize),
      (stream2End..<stream3End, segmentSize),
      (stream3End..<body.endIndex, lastSegmentSize),
    ]

    var literals = [UInt8](repeating: 0, count: regeneratedSize)
    var streams: [(reader: BackwardBitReader, outputOffset: Int, count: Int)] = []
    var outputOffset = 0
    for segment in segments where segment.count > 0 {
      let reader = try BackwardBitReader(Array(body[segment.range]))
      streams.append((reader, outputOffset, segment.count))
      outputOffset += segment.count
    }

    let maxCount = streams.map(\.count).max() ?? 0
    for step in 0..<maxCount {
      for index in streams.indices where step < streams[index].count {
        let lutIndex = Int(streams[index].reader.peekBits(table.maxBits))
        guard lutIndex < table.symbolOf.count else { throw ZstdError.invalidHuffmanTable }
        literals[streams[index].outputOffset + step] = table.symbolOf[lutIndex]
        _ = streams[index].reader.readBits(Int(table.numberOfBits[lutIndex]))
      }
    }
    return literals
  }
}
