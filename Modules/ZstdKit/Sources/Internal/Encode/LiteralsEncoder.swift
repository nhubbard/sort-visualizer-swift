// This file's literals-section header layout mirrors `LiteralsSection.swift`'s parse logic
// (RFC 8878 §3.1.1.3.1), and the four-stream jump table mirrors `LiteralsSectionDecoder
// .decodeFourStreams`. See NOTICE.md.
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

/// Encodes one block's literals as 4-stream Huffman-compressed, or returns `nil` when that's not
/// applicable — the caller falls back to a raw block. Deliberately narrower than the full format:
/// always 4 streams (never 1), always the `Size_Format == 2` header (4 bytes, 14-bit regenerated/
/// compressed sizes — the one non-overlapping, straightforward-to-construct size-header form; the
/// widest 5-byte form's bit layout has real subtlety this milestone defers), and raw (never FSE-
/// compressed) Huffman weights, which caps the usable literal alphabet at 128 distinct high values
/// (`Size_Format == 2` limits chunks to `maximumBlockSize` for the frame overall, and the 14-bit
/// size fields cap a single literals section at 16,383 bytes — comfortably under the 16,000-byte
/// block size this encoder uses).
enum LiteralsEncoder {
  /// Huffman-compressed literals whenever that's applicable and actually smaller, raw otherwise —
  /// this is what a block *with* sequences uses for its literals section (the zero-sequences path
  /// in `BlockEncoder` calls `encodeFourStreamHuffman` directly, since it needs to know whether
  /// Huffman applied at all to decide whether that whole candidate is worth trying).
  static func encodeLiterals(_ bytes: [UInt8]) -> [UInt8] {
    if let huffman = encodeFourStreamHuffman(bytes), huffman.count < encodeRaw(bytes).count {
      return huffman
    }
    return encodeRaw(bytes)
  }

  /// `Literals_Block_Type == raw`: header (5/12/20-bit `regeneratedSize`, narrowest that fits, per
  /// `LiteralsSection.swift`'s documented layout) followed by the literal bytes verbatim.
  static func encodeRaw(_ bytes: [UInt8]) -> [UInt8] {
    var writer = ByteWriter()
    if bytes.count < 32 {
      writer.writeByte(UInt8(bytes.count << 3))
    } else if bytes.count < 4096 {
      writer.writeLittleEndianUInt(UInt64((1 << 2) | (bytes.count << 4)), byteCount: 2)
    } else {
      writer.writeLittleEndianUInt(UInt64((3 << 2) | (bytes.count << 4)), byteCount: 3)
    }
    writer.writeBytes(bytes)
    return writer.bytes
  }

  static func encodeFourStreamHuffman(_ bytes: [UInt8]) -> [UInt8]? {
    guard bytes.count >= 12 else { return nil }

    var histogram = [Int](repeating: 0, count: 256)
    for byte in bytes { histogram[Int(byte)] += 1 }
    guard let table = HuffmanEncodeTableBuilder.build(histogram: histogram) else { return nil }
    guard let weightBytes = writeRawWeights(table.weights) else { return nil }

    let segmentSize = (bytes.count + 3) / 4
    let lastSegmentSize = bytes.count - 3 * segmentSize
    guard lastSegmentSize >= 0 else { return nil }
    let ranges = [
      0..<segmentSize,
      segmentSize..<(2 * segmentSize),
      (2 * segmentSize)..<(3 * segmentSize),
      (3 * segmentSize)..<bytes.count,
    ]

    var streamBytes: [[UInt8]] = []
    for range in ranges {
      guard let encoded = HuffmanStreamEncoder.encode(Array(bytes[range]), table: table) else {
        return nil
      }
      streamBytes.append(encoded)
    }

    var body = ByteWriter()
    body.writeLittleEndianUInt(UInt64(streamBytes[0].count), byteCount: 2)
    body.writeLittleEndianUInt(UInt64(streamBytes[1].count), byteCount: 2)
    body.writeLittleEndianUInt(UInt64(streamBytes[2].count), byteCount: 2)
    for stream in streamBytes { body.writeBytes(stream) }

    let huffmanBlob = weightBytes + body.bytes
    let compressedSize = huffmanBlob.count
    guard bytes.count <= 0x3FFF, compressedSize <= 0x3FFF else { return nil }

    // Size_Format == 2, blockType == .compressed(2): descriptor bits0-1 = blockType, bits2-3 =
    // sizeFormat, then a clean (non-overlapping) 32-bit little-endian value: bits4-17 =
    // regeneratedSize, bits18-31 = compressedSize.
    let lowBits: UInt32 = 2 | (2 << 2)
    let headerValue = lowBits | (UInt32(bytes.count) << 4) | (UInt32(compressedSize) << 18)
    var writer = ByteWriter()
    writer.writeLittleEndianUInt(UInt64(headerValue), byteCount: 4)
    writer.writeBytes(huffmanBlob)
    return writer.bytes
  }

  /// The direct/raw weight-table form (`LiteralsSection`'s header-byte `>= 128` case): a header
  /// byte of `128 + (explicitCount - 1)`, then two 4-bit weights per byte. Only representable when
  /// `explicitCount` (== the highest occurring byte value, since the very last symbol's weight is
  /// always implicit) fits in 7 bits — `nil` otherwise, which is exactly when FSE-compressed
  /// weights would be required instead (not yet implemented).
  private static func writeRawWeights(_ weights: [Int]) -> [UInt8]? {
    let explicitCount = weights.count - 1
    guard explicitCount >= 1, explicitCount <= 128 else { return nil }
    var writer = ByteWriter()
    writer.writeByte(UInt8(128 + explicitCount - 1))
    var index = 0
    while index < explicitCount {
      let high = UInt8(weights[index])
      let low = index + 1 < explicitCount ? UInt8(weights[index + 1]) : 0
      writer.writeByte((high << 4) | low)
      index += 2
    }
    return writer.bytes
  }
}
