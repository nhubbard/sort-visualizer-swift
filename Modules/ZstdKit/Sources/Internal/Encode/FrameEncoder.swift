// This file's frame-header field layout is the write-side mirror of `FrameHeader.swift`'s parse
// logic (RFC 8878 §3.1.1.1) as implemented by the real `zstd` C source. See NOTICE.md.
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

private let zstdMagicNumber: UInt64 = 0xFD2F_B528

/// Orchestrates a full frame encode: header, then the block loop, then an optional checksum
/// trailer — the write-side mirror of `ZstdDecompressor`'s top-level flow.
///
/// Always writes `Single_Segment_flag = 1` (this encoder holds the whole input in memory, so the
/// content size is always known up front) and never sets `Dictionary_ID_flag` (no dictionary
/// support — see `COMPRESSION_DESIGN.md`), which together mean the window-descriptor byte and
/// dictionary-ID field are always absent, not just narrowed.
enum FrameEncoder {
  static func encode(_ input: [UInt8], options: ZstdEncodingOptions) throws -> [UInt8] {
    guard input.count <= options.maximumInputSize else {
      throw ZstdEncodeError.inputTooLarge(requested: input.count, limit: options.maximumInputSize)
    }

    var writer = ByteWriter()
    writer.writeLittleEndianUInt(zstdMagicNumber, byteCount: 4)

    let (frameContentSizeFlag, fieldByteCount) = frameContentSizeEncoding(for: input.count)
    let descriptor: UInt8 =
      (frameContentSizeFlag << 6) | (1 << 5) | (options.checksum ? 1 << 2 : 0)
    writer.writeByte(descriptor)
    // No window descriptor (single-segment) and no Dictionary_ID field (flag always 0 — see
    // this type's doc comment).

    if fieldByteCount > 0 {
      let wireValue = fieldByteCount == 2 ? UInt64(input.count) - 256 : UInt64(input.count)
      writer.writeLittleEndianUInt(wireValue, byteCount: fieldByteCount)
    }

    // Frame-scoped, reset once here (never per block) — matches decode's own `RepeatOffsets`
    // lifetime exactly (RFC 8878 §3.1.1.3.2.1.2).
    var repeatOffsets = EncodeRepeatOffsets()
    let chunks = chunked(input, into: maximumBlockSize)
    for (index, chunk) in chunks.enumerated() {
      let isLast = index == chunks.count - 1
      writer.writeBytes(
        BlockEncoder.encode(chunk, isLastBlock: isLast, options: options, repeatOffsets: &repeatOffsets))
    }

    if options.checksum {
      writer.writeLittleEndianUInt(UInt64(XXH64.checksum32(input)), byteCount: 4)
    }

    return writer.bytes
  }

  /// Mirrors `FrameHeaderParser`'s field-size table exactly: flag 0 is 1 byte, direct value
  /// (0...255); flag 1 is 2 bytes, wire value is `actualSize - 256` (256...65,791); flag 2 is 4
  /// bytes, direct value; flag 3 is 8 bytes, direct value.
  private static func frameContentSizeEncoding(for size: Int) -> (flag: UInt8, byteCount: Int) {
    switch size {
    case 0...255: return (0, 1)
    case 256...65791: return (1, 2)
    case 65792...Int(UInt32.max): return (2, 4)
    default: return (3, 8)
    }
  }

  private static func chunked(_ input: [UInt8], into size: Int) -> [[UInt8]] {
    guard !input.isEmpty else { return [[]] }
    var result: [[UInt8]] = []
    var index = 0
    while index < input.count {
      let end = min(index + size, input.count)
      result.append(Array(input[index..<end]))
      index = end
    }
    return result
  }
}
