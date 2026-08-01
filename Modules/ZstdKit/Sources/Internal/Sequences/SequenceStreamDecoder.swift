// This file's read/update order matches the reference decoder's `ZSTD_decodeSequence` exactly
// — confirmed against source, not the RFC prose. See NOTICE.md.
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

struct DecodedSequence {
  let literalLength: Int
  let matchLength: Int
  let offset: Int
}

/// Decodes `count` `(literal_length, offset, match_length)` triples from one interleaved FSE
/// bitstream. Read/update order below matches the reference decoder's `ZSTD_decodeSequence`
/// exactly (confirmed against source, not the RFC prose): per sequence, the three symbols come
/// from the *current* states (no bits consumed yet), then the offset is resolved — reading its
/// extra bits inline — before match-length's extra bits, before literal-length's extra bits, and
/// only then (skipped entirely for the last sequence) do the three states advance, in order
/// literal-length, match-length, offset.
enum SequenceStreamDecoder {
  static func decode(
    _ bytes: ArraySlice<UInt8>,
    count: Int,
    literalLengthTable: FSEDecodeTable,
    offsetTable: FSEDecodeTable,
    matchLengthTable: FSEDecodeTable,
    repeatOffsets: inout RepeatOffsets
  ) throws -> [DecodedSequence] {
    guard count > 0 else { return [] }

    var reader = try BackwardBitReader(Array(bytes))
    var literalLengthState = Int(reader.readBits(literalLengthTable.accuracyLog))
    var offsetState = Int(reader.readBits(offsetTable.accuracyLog))
    var matchLengthState = Int(reader.readBits(matchLengthTable.accuracyLog))

    let literalLengthBase = SequenceTables.literalLengthBase
    let literalLengthExtraBits = SequenceTables.literalLengthExtraBits
    let matchLengthBase = SequenceTables.matchLengthBase
    let matchLengthExtraBits = SequenceTables.matchLengthExtraBits
    let offsetBaseTable = SequenceTables.offsetBase
    let offsetExtraBitsTable = SequenceTables.offsetExtraBits

    var sequences: [DecodedSequence] = []
    sequences.reserveCapacity(count)

    for index in 0..<count {
      guard literalLengthState < literalLengthTable.symbolOf.count,
        offsetState < offsetTable.symbolOf.count,
        matchLengthState < matchLengthTable.symbolOf.count
      else {
        throw ZstdError.invalidSequenceStream
      }

      let llCode = Int(literalLengthTable.symbolOf[literalLengthState])
      let ofCode = Int(offsetTable.symbolOf[offsetState])
      let mlCode = Int(matchLengthTable.symbolOf[matchLengthState])
      guard llCode < literalLengthBase.count, ofCode < offsetBaseTable.count, mlCode < matchLengthBase.count
      else {
        throw ZstdError.invalidSequenceStream
      }

      let llBase = literalLengthBase[llCode]
      let literalLengthIsZero = llBase == 0

      let offset = try repeatOffsets.resolve(
        offsetBase: offsetBaseTable[ofCode],
        offsetExtraBits: offsetExtraBitsTable[ofCode],
        literalLengthIsZero: literalLengthIsZero,
        reader: &reader
      )

      let mlExtra = matchLengthExtraBits[mlCode]
      let matchLength = matchLengthBase[mlCode] + (mlExtra > 0 ? Int(reader.readBits(mlExtra)) : 0)

      let llExtra = literalLengthExtraBits[llCode]
      let literalLength = llBase + (llExtra > 0 ? Int(reader.readBits(llExtra)) : 0)

      sequences.append(DecodedSequence(literalLength: literalLength, matchLength: matchLength, offset: offset))

      if index < count - 1 {
        literalLengthState = advance(literalLengthTable, literalLengthState, &reader)
        matchLengthState = advance(matchLengthTable, matchLengthState, &reader)
        offsetState = advance(offsetTable, offsetState, &reader)
      }
    }

    return sequences
  }

  private static func advance(_ table: FSEDecodeTable, _ state: Int, _ reader: inout BackwardBitReader) -> Int {
    let bits = Int(table.numberOfBits[state])
    let low = bits > 0 ? Int(reader.readBits(bits)) : 0
    return Int(table.baseline[state]) + low
  }
}
