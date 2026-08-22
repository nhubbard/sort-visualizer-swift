// This file's Predefined/RLE/FSE_Compressed/Repeat symbol-table construction mirrors the real
// `zstd` C source's `ZSTD_buildSeqTable`. See NOTICE.md.
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

/// The three sequence-symbol FSE tables currently in effect for a frame — persisted across blocks
/// so a `.repeat_` mode can reuse whichever table (predefined, RLE, or FSE-compressed) the most
/// recent block of that symbol type built. `nil` until the first block sets it; `.repeat_` on an
/// unset table is a real error (RFC 8878: invalid on a frame's first use).
struct SequenceTableSet {
  var literalLengths: FSEDecodeTable?
  var offsets: FSEDecodeTable?
  var matchLengths: FSEDecodeTable?

  func table(for kind: SequenceSymbolKind) -> FSEDecodeTable? {
    switch kind {
    case .literalLength: return literalLengths
    case .offset: return offsets
    case .matchLength: return matchLengths
    }
  }

  mutating func setTable(_ table: FSEDecodeTable, for kind: SequenceSymbolKind) {
    switch kind {
    case .literalLength: literalLengths = table
    case .offset: offsets = table
    case .matchLength: matchLengths = table
    }
  }
}

enum SequenceTableBuilder {
  /// Builds (or reuses) the decode table for one symbol type, advancing `reader` past whatever
  /// bytes this mode consumes (zero for `.predefined`/`.repeat_`, one for `.rle`, a variable
  /// FSE table description for `.fseCompressed`).
  static func buildTable(
    mode: SequenceSymbolCompressionMode,
    kind: SequenceSymbolKind,
    reader: inout ByteReader,
    previousTables: SequenceTableSet
  ) throws -> FSEDecodeTable {
    switch mode {
    case .predefined:
      return try FSETableBuilder.buildDecodeTable(
        counts: kind.defaultNormalizedCounts, accuracyLog: kind.defaultAccuracyLog
      )

    case .rle:
      let symbol = try reader.readByte()
      guard Int(symbol) <= kind.maxSymbol else { throw ZstdError.invalidSequenceStream }
      // A trivial one-state table: always decodes to `symbol`, consumes 0 bits, never changes
      // state — mirrors the reference decoder's `tableLog=0, nbBits=0, nextState=0` RLE table.
      return FSEDecodeTable(accuracyLog: 0, symbolOf: [symbol], numberOfBits: [0], baseline: [0])

    case .repeat_:
      guard let previous = previousTables.table(for: kind) else { throw ZstdError.invalidSequenceStream }
      return previous

    case .fseCompressed:
      var forwardReader = ForwardBitReader(Array(reader.remainingBytes()))
      let (accuracyLog, counts) = try FSETableBuilder.readNormalizedCounts(
        &forwardReader, maxSymbol: kind.maxSymbol, maximumAccuracyLog: kind.maximumAccuracyLog
      )
      let table = try FSETableBuilder.buildDecodeTable(counts: counts, accuracyLog: accuracyLog)
      try reader.skip(forwardReader.consumedBytes)
      return table
    }
  }
}
