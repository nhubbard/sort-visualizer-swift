// This file's Symbol_Compression_Modes/Number_of_Sequences header layout and the interleaved
// per-sequence bitstream order mirror `SequencesHeader.swift`/`SequenceStreamDecoder.swift`'s
// decode logic exactly, in reverse. See NOTICE.md.
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

enum SequenceStreamEncoder {
  struct Result {
    let bytes: [UInt8]
    let finalOffsets: EncodeRepeatOffsets
  }

  /// Builds the full Sequences_Section (RFC 8878 §3.1.1.3.2): header (count + modes byte + any
  /// FSE table descriptions), then the interleaved LL/OF/ML bitstream body. `initialRepeatOffsets`
  /// is a *trial* copy — the caller only commits `finalOffsets` back to the real, frame-threaded
  /// state if this candidate is actually chosen (mirroring decode, where `repeatOffsets` is only
  /// ever touched by a block that really has sequences).
  static func encode(sequenceStore: SequenceStore, initialRepeatOffsets: EncodeRepeatOffsets) -> Result? {
    let sequences = sequenceStore.sequences
    guard !sequences.isEmpty else { return nil }

    var repeatOffsets = initialRepeatOffsets
    var llCodes: [Int] = []
    var mlCodes: [Int] = []
    var ofCodes: [Int] = []
    var llExtra: [(bits: UInt32, count: Int)] = []
    var mlExtra: [(bits: UInt32, count: Int)] = []
    var ofExtra: [(bits: UInt32, count: Int)] = []

    for sequence in sequences {
      let llCode = SequenceCodeSelection.code(for: sequence.literalLength, in: .literalLength)
      let mlCode = SequenceCodeSelection.code(for: sequence.matchLength, in: .matchLength)
      let ofCode = repeatOffsets.encode(offset: sequence.offset, literalLengthIsZero: sequence.literalLength == 0)

      llCodes.append(llCode.code)
      mlCodes.append(mlCode.code)
      ofCodes.append(ofCode.code)
      llExtra.append((UInt32(llCode.extraBitsValue), llCode.extraBitsCount))
      mlExtra.append((UInt32(mlCode.extraBitsValue), mlCode.extraBitsCount))
      ofExtra.append((UInt32(ofCode.extraBitsValue), ofCode.extraBitsCount))
    }

    let ll = buildStream(codes: llCodes, kind: .literalLength)
    let of = buildStream(codes: ofCodes, kind: .offset)
    let ml = buildStream(codes: mlCodes, kind: .matchLength)

    var writer = ByteWriter()
    writeSequenceCount(sequences.count, into: &writer)
    let modesByte = UInt8((ll.mode.rawValue << 6) | (of.mode.rawValue << 4) | (ml.mode.rawValue << 2))
    writer.writeByte(modesByte)
    writer.writeBytes(ll.tableDescription)
    writer.writeBytes(of.tableDescription)
    writer.writeBytes(ml.tableDescription)

    // Encode in reverse (last sequence first) — FSE's own LIFO requirement, see
    // `FSEEncodeSession`'s doc comment.
    var llSession = FSEEncodeSession(table: ll.encodeTable)
    var ofSession = FSEEncodeSession(table: of.encodeTable)
    var mlSession = FSEEncodeSession(table: ml.encodeTable)
    for index in stride(from: sequences.count - 1, through: 0, by: -1) {
      llSession.encodeNext(llCodes[index])
      mlSession.encodeNext(mlCodes[index])
      ofSession.encodeNext(ofCodes[index])
    }

    var body = BackwardBitWriter()
    // Initial state reads, in decode's own order: LL, OF, ML.
    body.writeBits(llSession.flushValue.bits, count: llSession.flushValue.count)
    body.writeBits(ofSession.flushValue.bits, count: ofSession.flushValue.count)
    body.writeBits(mlSession.flushValue.bits, count: mlSession.flushValue.count)

    let llAdvances = llSession.advancesInOriginalOrder
    let mlAdvances = mlSession.advancesInOriginalOrder
    let ofAdvances = ofSession.advancesInOriginalOrder

    for index in 0..<sequences.count {
      // Per sequence: offset extra bits, then match-length extra bits, then literal-length extra
      // bits (matching `SequenceStreamDecoder.decode`'s read order exactly), then — skipped for
      // the last sequence — the three state advances in LL, ML, OF order.
      body.writeBits(ofExtra[index].bits, count: ofExtra[index].count)
      body.writeBits(mlExtra[index].bits, count: mlExtra[index].count)
      body.writeBits(llExtra[index].bits, count: llExtra[index].count)
      if index < sequences.count - 1 {
        body.writeBits(llAdvances[index].bits, count: llAdvances[index].count)
        body.writeBits(mlAdvances[index].bits, count: mlAdvances[index].count)
        body.writeBits(ofAdvances[index].bits, count: ofAdvances[index].count)
      }
    }
    writer.writeBytes(body.finish())

    return Result(bytes: writer.bytes, finalOffsets: repeatOffsets)
  }

  private struct StreamPlan {
    let mode: SequenceSymbolCompressionMode
    let encodeTable: FSEEncodeTableData
    let tableDescription: [UInt8]
  }

  /// RLE whenever every sequence in this block shares the same code for this symbol type
  /// (matching `ZSTD_selectEncodingType`'s cheapest-available check); FSE_Compressed otherwise.
  /// Deliberately never `.predefined`/`.repeat_` — see `COMPRESSION_DESIGN.md`'s scope notes: both
  /// are real compression-ratio opportunities left for later, not correctness gaps (every stream
  /// this produces is validly decodable either way).
  private static func buildStream(codes: [Int], kind: SequenceSymbolKind) -> StreamPlan {
    if let first = codes.first, codes.allSatisfy({ $0 == first }) {
      var counts = [Int](repeating: 0, count: kind.maxSymbol + 1)
      counts[first] = 1
      let table = FSEEncodeTable.build(counts: counts, accuracyLog: 0)
      return StreamPlan(mode: .rle, encodeTable: table, tableDescription: [UInt8(first)])
    }

    var histogram = [Int](repeating: 0, count: kind.maxSymbol + 1)
    for code in codes { histogram[code] += 1 }
    let distinctSymbolCount = histogram.filter { $0 > 0 }.count
    let accuracyLog = FSEEncodeTable.chooseAccuracyLog(
      distinctSymbolCount: distinctSymbolCount,
      minimumAccuracyLog: FSETableBuilder.minimumAccuracyLog,
      maximumAccuracyLog: kind.maximumAccuracyLog
    )
    let normalized = FSEEncodeTable.normalize(counts: histogram, accuracyLog: accuracyLog)
    let table = FSEEncodeTable.build(counts: normalized, accuracyLog: accuracyLog)
    let description = FSEEncodeTable.writeNCount(counts: normalized, accuracyLog: accuracyLog, maxSymbol: kind.maxSymbol)
    return StreamPlan(mode: .fseCompressed, encodeTable: table, tableDescription: description)
  }

  /// Mirrors `SequencesHeaderParser`'s three Number_of_Sequences forms, using the narrowest that
  /// fits: direct (`< 128`), the `128...254`-first-byte extended form (up to 32,511), or the
  /// `255`-prefixed 2-byte form beyond that.
  private static func writeSequenceCount(_ count: Int, into writer: inout ByteWriter) {
    if count < 128 {
      writer.writeByte(UInt8(count))
    } else if count <= 32511 {
      writer.writeByte(UInt8(0x80 + (count >> 8)))
      writer.writeByte(UInt8(count & 0xFF))
    } else {
      writer.writeByte(255)
      writer.writeLittleEndianUInt(UInt64(count - 0x7F00), byteCount: 2)
    }
  }
}
