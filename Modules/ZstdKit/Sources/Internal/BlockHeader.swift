// This file's block-header bit layout (`Block_Size`, `Block_Type`, `Last_Block`) is
// transcribed from Zstandard's frame format (RFC 8878 §3.1.1.2) as implemented by the real
// `zstd` C source. See NOTICE.md.
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

enum BlockType: UInt8 {
  case raw = 0
  case rle = 1
  case compressed = 2
  // 3 is reserved.
}

/// `Block_Size`'s meaning depends on `blockType`: the literal byte count for `.raw`, the
/// decompressed repeat count for `.rle` (exactly one byte follows in the stream), or the
/// compressed byte count for `.compressed`.
struct BlockHeader {
  let isLastBlock: Bool
  let blockType: BlockType
  let blockSize: Int
}

enum BlockHeaderParser {
  static func parse(_ reader: inout ByteReader) throws -> BlockHeader {
    let raw = try reader.readLittleEndianUInt(byteCount: 3)
    let isLastBlock = (raw & 0x1) == 1
    guard let blockType = BlockType(rawValue: UInt8((raw >> 1) & 0x3)) else {
      throw ZstdError.invalidBlockHeader
    }
    let blockSize = Int((raw >> 3) & 0x1F_FFFF)
    return BlockHeader(isLastBlock: isLastBlock, blockType: blockType, blockSize: blockSize)
  }
}
