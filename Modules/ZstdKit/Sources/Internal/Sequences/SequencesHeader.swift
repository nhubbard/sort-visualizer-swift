// This file's Number_of_Sequences and Symbol_Compression_Modes parsing (RFC 8878 §3.1.1.3.2)
// matches the real `zstd` C source's `SymbolEncodingType_e` values. See NOTICE.md.
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

/// One symbol type's Symbol_Compression_Mode (RFC 8878 §3.1.1.3.2.2). Numeric values match the
/// real decoder's `SymbolEncodingType_e` (`set_basic`/`set_rle`/`set_compressed`/`set_repeat`).
enum SequenceSymbolCompressionMode: UInt8 {
  case predefined = 0
  case rle = 1
  case fseCompressed = 2
  case repeat_ = 3
}

struct SequencesHeader {
  let numberOfSequences: Int
  let literalLengthsMode: SequenceSymbolCompressionMode
  let offsetsMode: SequenceSymbolCompressionMode
  let matchLengthsMode: SequenceSymbolCompressionMode
}

/// `LONGNBSEQ` — the offset added to the 2-byte extended sequence count.
private let longSequenceCountOffset = 0x7F00

enum SequencesHeaderParser {
  static func parse(_ reader: inout ByteReader) throws -> SequencesHeader {
    let first = try reader.readByte()

    let numberOfSequences: Int
    if first < 128 {
      numberOfSequences = Int(first)
    } else if first == 255 {
      numberOfSequences = Int(try reader.readLittleEndianUInt(byteCount: 2)) + longSequenceCountOffset
    } else {
      let extra = try reader.readByte()
      numberOfSequences = ((Int(first) - 0x80) << 8) + Int(extra)
    }

    // Section ends immediately once the count is 0, however it was spelled — the single-byte
    // direct form (`first == 0`) isn't the only encoding that can produce it: the 2-byte extended
    // form's `((first - 0x80) << 8) + extra` is also 0 whenever `first == 0x80, extra == 0` (a
    // real fixture upstream exercises exactly this — `zeroSeq_2B`). No Symbol_Compression_Modes
    // byte follows in either case; a previous version only special-cased the single-byte form,
    // so the 2-byte-form zero either read past the end of a minimal block (`truncatedInput`) or,
    // given trailing bytes to misread as a modes byte, silently accepted them instead of
    // rejecting the block as the real decoder does (`zeroSeq_extraneous`). The modes below are
    // placeholders the caller must never act on (there's nothing to build a table for).
    guard numberOfSequences > 0 else {
      return SequencesHeader(
        numberOfSequences: 0, literalLengthsMode: .predefined, offsetsMode: .predefined,
        matchLengthsMode: .predefined
      )
    }

    let modesByte = try reader.readByte()
    guard modesByte & 0x3 == 0 else { throw ZstdError.invalidSequenceStream }
    guard let literalLengthsMode = SequenceSymbolCompressionMode(rawValue: (modesByte >> 6) & 0x3),
      let offsetsMode = SequenceSymbolCompressionMode(rawValue: (modesByte >> 4) & 0x3),
      let matchLengthsMode = SequenceSymbolCompressionMode(rawValue: (modesByte >> 2) & 0x3)
    else {
      throw ZstdError.invalidSequenceStream
    }

    return SequencesHeader(
      numberOfSequences: numberOfSequences,
      literalLengthsMode: literalLengthsMode,
      offsetsMode: offsetsMode,
      matchLengthsMode: matchLengthsMode
    )
  }
}
