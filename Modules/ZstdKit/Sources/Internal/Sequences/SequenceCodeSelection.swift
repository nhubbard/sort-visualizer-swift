// This file's baseline-table code selection is the write-side mirror of the same tables
// `SequenceTables.swift` already exposes for decode, and the offset-code encode direction
// mirrors `RepeatOffsets.swift`'s decode-direction rules (`ZSTD_decodeSequence`/
// `ZSTD_updateRep`) in reverse. See NOTICE.md.
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

struct SequenceCode {
  let code: Int
  let extraBitsCount: Int
  let extraBitsValue: Int
}

enum SequenceCodeSelection {
  /// Largest code whose baseline doesn't exceed `value` — the encode-direction mirror of how
  /// `literalLengthBase`/`matchLengthBase`/`offsetBase` are used on decode. For `.offset`
  /// specifically, this naturally lands on code `>= 2` for any real (`>= 1`) offset: codes 0/1's
  /// bases (0 and 1) are always dominated by code 2's own base+range, so the repeat-code-reserved
  /// codes 0/1 are never accidentally selected here — only `EncodeRepeatOffsets` ever produces
  /// those, deliberately.
  static func code(for value: Int, in kind: SequenceSymbolKind) -> SequenceCode {
    let bases = kind.baseValues
    var code = 0
    while code + 1 < bases.count, bases[code + 1] <= value {
      code += 1
    }
    return SequenceCode(code: code, extraBitsCount: kind.extraBits[code], extraBitsValue: value - bases[code])
  }
}

/// The encode-direction counterpart to `RepeatOffsets` — given a real match offset already chosen
/// by the match finder, decides the cheapest `Offset_Code` that resolves back to that same offset
/// (mirroring `RepeatOffsets.resolve`'s rules exactly, in reverse) and threads the identical
/// rotate-on-use state forward. A fresh `1, 4, 8` instance per frame (never per block), same as
/// decode's `RepeatOffsets`.
struct EncodeRepeatOffsets {
  var offset1 = 1
  var offset2 = 4
  var offset3 = 8

  mutating func encode(offset: Int, literalLengthIsZero: Bool) -> SequenceCode {
    if !literalLengthIsZero {
      if offset == offset1 {
        return SequenceCode(code: 0, extraBitsCount: 0, extraBitsValue: 0)
      } else if offset == offset2 {
        swap(&offset1, &offset2)
        return SequenceCode(code: 1, extraBitsCount: 1, extraBitsValue: 0)
      } else if offset == offset3 {
        let newOffset1 = offset3
        offset3 = offset2
        offset2 = offset1
        offset1 = newOffset1
        return SequenceCode(code: 1, extraBitsCount: 1, extraBitsValue: 1)
      }
    } else {
      if offset == offset2 {
        swap(&offset1, &offset2)
        return SequenceCode(code: 0, extraBitsCount: 0, extraBitsValue: 0)
      } else if offset == offset3 {
        let newOffset1 = offset3
        offset3 = offset2
        offset2 = offset1
        offset1 = newOffset1
        return SequenceCode(code: 1, extraBitsCount: 1, extraBitsValue: 0)
      } else if offset1 > 1, offset == offset1 - 1 {
        offset3 = offset2
        offset2 = offset1
        offset1 = offset
        return SequenceCode(code: 1, extraBitsCount: 1, extraBitsValue: 1)
      }
    }

    let explicit = SequenceCodeSelection.code(for: offset, in: .offset)
    offset3 = offset2
    offset2 = offset1
    offset1 = offset
    return explicit
  }
}
