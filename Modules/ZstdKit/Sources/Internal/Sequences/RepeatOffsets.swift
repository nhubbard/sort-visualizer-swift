// This file resolves an Offset_Code exactly as the reference decoder's `ZSTD_decodeSequence`
// does — confirmed against `lib/decompress/zstd_decompress_block.c`, not derived from the
// RFC prose alone. See NOTICE.md.
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

/// The 3 most-recently-used match offsets (RFC 8878 §3.1.1.3.2.1.2), reset to `{1, 4, 8}` once per
/// frame and threaded through every sequence in every block of that frame — never reset per block.
///
/// This resolves an Offset_Code exactly as the reference decoder's `ZSTD_decodeSequence` does
/// (confirmed against `lib/decompress/zstd_decompress_block.c`, not derived from the RFC prose
/// alone — the RFC's repeat-offset description and the actual bit-level mechanics the reference
/// decoder implements don't line up cleanly enough to transcribe by hand with confidence). The
/// key fact the RFC prose undersells: which case applies is decided by the Offset_Code's *extra
/// bit count* (0, 1, or >1), not by comparing the decoded offset value against 1/2/3.
struct RepeatOffsets {
  var offset1 = 1
  var offset2 = 4
  var offset3 = 8

  /// `offsetBase`/`offsetExtraBits` are `SequenceTables.offsetBase[code]`/`offsetExtraBits[code]`
  /// for the decoded Offset_Code. `literalLengthIsZero` must reflect the *Literal_Length_Code's
  /// baseValue* being zero (equivalently, the final literal length being zero — they coincide
  /// because code 0 is the only Literal_Length_Code with both a zero baseline and zero extra
  /// bits), checked *before* any of this sequence's literal-length extra bits are read.
  mutating func resolve(
    offsetBase: Int, offsetExtraBits: Int, literalLengthIsZero: Bool, reader: inout BackwardBitReader
  ) throws -> Int {
    let offset: Int
    if offsetExtraBits > 1 {
      offset = offsetBase + Int(reader.readBits(offsetExtraBits))
      offset3 = offset2
      offset2 = offset1
      offset1 = offset
    } else if offsetExtraBits == 0 {
      offset = literalLengthIsZero ? offset2 : offset1
      if literalLengthIsZero {
        offset2 = offset1
      }
      offset1 = offset
    } else {
      // offsetExtraBits == 1
      let extraBit = Int(reader.readBits(1))
      let rawValue = offsetBase + (literalLengthIsZero ? 1 : 0) + extraBit  // offsetBase == 1 here
      let resolved: Int
      switch rawValue {
      case 1: resolved = offset2
      case 2: resolved = offset3
      default: resolved = offset1 - 1  // rawValue == 3
      }
      guard resolved > 0 else { throw ZstdError.invalidMatchOffset }
      if rawValue != 1 {
        offset3 = offset2
      }
      offset2 = offset1
      offset1 = resolved
      offset = resolved
    }
    return offset
  }
}
