// This file's frame-header field layout (`Frame_Header_Descriptor`, window descriptor,
// `Dictionary_ID`, `Frame_Content_Size`) is transcribed from Zstandard's frame format
// (RFC 8878 §3.1.1.1) as implemented by the real `zstd` C source. See NOTICE.md.
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

private let zstdMagicNumber: UInt32 = 0xFD2F_B528
private let skippableFrameMagicMask: UInt32 = 0xFFFF_FFF0
private let skippableFrameMagicValue: UInt32 = 0x184D_2A50

/// A standard Zstd frame's header fields (RFC 8878 §3.1.1.1), with `windowSize` already resolved
/// for both windowed and single-segment frames so callers never branch on that distinction again.
struct FrameHeader {
  let windowSize: Int
  let frameContentSize: Int?
  let contentChecksumFlag: Bool
}

enum FrameHeaderParser {
  static func parse(_ reader: inout ByteReader, limits: ZstdDecodingLimits) throws -> FrameHeader {
    let magic = UInt32(try reader.readLittleEndianUInt(byteCount: 4))
    if magic & skippableFrameMagicMask == skippableFrameMagicValue {
      throw ZstdError.unsupportedFrameFeature("skippable frame")
    }
    guard magic == zstdMagicNumber else {
      throw ZstdError.invalidMagic
    }

    let descriptor = try reader.readByte()
    let frameContentSizeFlag = (descriptor >> 6) & 0x3
    let singleSegmentFlag = (descriptor >> 5) & 0x1 == 1
    let reservedBit = (descriptor >> 3) & 0x1
    let contentChecksumFlag = (descriptor >> 2) & 0x1 == 1
    let dictionaryIDFlag = descriptor & 0x3

    guard reservedBit == 0 else { throw ZstdError.invalidFrameHeader }

    var windowSize = 0
    if !singleSegmentFlag {
      let windowDescriptor = try reader.readByte()
      let exponent = Int(windowDescriptor >> 3)
      let mantissa = Int(windowDescriptor & 0x7)
      let windowBase = 1 << (10 + exponent)
      let windowAdd = (windowBase / 8) * mantissa
      windowSize = windowBase + windowAdd
    }

    if dictionaryIDFlag != 0 {
      let dictionaryIDFieldSize = [0, 1, 2, 4][Int(dictionaryIDFlag)]
      let dictionaryID = try reader.readLittleEndianUInt(byteCount: dictionaryIDFieldSize)
      // A present Dictionary_ID field means this frame's sequences may reference dictionary
      // content this decoder was never given — decoding further would silently produce wrong
      // output, not a crash, so this must be caught here rather than deferred.
      throw ZstdError.dictionaryRequired(id: UInt32(dictionaryID))
    }

    let frameContentSizeFieldSize: Int
    switch frameContentSizeFlag {
    case 0: frameContentSizeFieldSize = singleSegmentFlag ? 1 : 0
    case 1: frameContentSizeFieldSize = 2
    case 2: frameContentSizeFieldSize = 4
    default: frameContentSizeFieldSize = 8
    }

    var frameContentSize: Int?
    if frameContentSizeFieldSize > 0 {
      var value = try reader.readLittleEndianUInt(byteCount: frameContentSizeFieldSize)
      if frameContentSizeFieldSize == 2 { value += 256 }
      guard let size = Int(exactly: value) else {
        throw ZstdError.outputLimitExceeded(requested: Int.max, limit: limits.maximumOutputSize)
      }
      frameContentSize = size
    }

    if singleSegmentFlag {
      guard let contentSize = frameContentSize else { throw ZstdError.invalidFrameHeader }
      windowSize = contentSize
    }

    guard windowSize <= limits.maximumWindowSize else {
      throw ZstdError.unsupportedWindowSize(requested: windowSize, limit: limits.maximumWindowSize)
    }
    if let frameContentSize, frameContentSize > limits.maximumOutputSize {
      throw ZstdError.outputLimitExceeded(requested: frameContentSize, limit: limits.maximumOutputSize)
    }

    return FrameHeader(
      windowSize: windowSize,
      frameContentSize: frameContentSize,
      contentChecksumFlag: contentChecksumFlag
    )
  }
}
