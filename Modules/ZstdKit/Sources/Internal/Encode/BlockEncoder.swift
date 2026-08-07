// This file's block-encoding decisions (RLE detection, the minimum-gain check that falls back
// to a raw block) mirror the real `zstd` C source's `ZSTD_isRLE`/`ZSTD_minGain`/
// `ZSTD_noCompressBlock` logic. See NOTICE.md.
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

/// Maximum bytes a single block may cover. The reference caps this at 128 KiB
/// (`1 << ZSTD_BLOCKSIZELOG_MAX`); this encoder uses a smaller 16,000-byte cap instead, chosen to
/// stay comfortably under the 14-bit (16,383-byte) size-field limit `LiteralsEncoder`'s
/// `Size_Format == 2` header form supports — deliberately avoiding the widest 5-byte literals-
/// header form's non-obvious overlapping-bitfield layout for this milestone. No content-based
/// pre-splitting beyond that (that's a ratio-tuning heuristic for large corpora, not a correctness
/// requirement — see `COMPRESSION_DESIGN.md`).
let maximumBlockSize = 16_000

/// Encodes one block's worth of input (`<= maximumBlockSize` bytes) into whichever of raw/RLE/
/// compressed is actually smallest, mirroring the reference's late "did this help" override rather
/// than deciding up front — a block is never allowed to expand incompressible input by more than
/// its own 3-byte header.
enum BlockEncoder {
  /// `repeatOffsets` is frame-scoped under sequential encoding, or chunk-scoped under
  /// `FrameEncoder`'s parallel-chunk path (owned by whichever caller threads it across a run of
  /// `encode` calls) and only ever mutated here if the LZ77-with-sequences candidate is the one
  /// actually chosen — matching decode, where a raw/RLE/zero-sequences block never touches the
  /// repeat-offset state at all (see `SequenceStreamEncoder.encode`'s doc comment). `prefix`
  /// (default empty) is forwarded to `BlockParser.parse` unchanged — see that type's doc comment.
  static func encode(
    _ chunk: [UInt8], prefix: [UInt8] = [], isLastBlock: Bool, options: ZstdEncodingOptions,
    repeatOffsets: inout EncodeRepeatOffsets
  ) -> [UInt8] {
    let candidate = bestCandidate(for: chunk, prefix: prefix, options: options, repeatOffsets: &repeatOffsets)
    var writer = ByteWriter()
    let blockSize: Int
    switch candidate.type {
    case .rle: blockSize = chunk.count
    case .raw, .compressed: blockSize = candidate.payload.count
    }
    let headerValue =
      (isLastBlock ? UInt64(1) : 0) | (UInt64(candidate.type.rawValue) << 1) | (UInt64(blockSize) << 3)
    writer.writeLittleEndianUInt(headerValue, byteCount: 3)
    writer.writeBytes(candidate.payload)
    return writer.bytes
  }

  private struct Candidate {
    let type: BlockType
    /// For `.rle`, this is the single repeated byte (length 1); for `.raw`/`.compressed`, the
    /// full block payload.
    let payload: [UInt8]
  }

  private static func bestCandidate(
    for chunk: [UInt8], prefix: [UInt8], options: ZstdEncodingOptions,
    repeatOffsets: inout EncodeRepeatOffsets
  ) -> Candidate {
    if let first = chunk.first, isRLE(chunk) {
      return Candidate(type: .rle, payload: [first])
    }

    var best = Candidate(type: .raw, payload: chunk)

    // Huffman-only literals with a zero-sequences marker — a real, valid compressed-block shape
    // that needs no match finder (see `COMPRESSION_DESIGN.md`'s milestone breakdown).
    if let literalsSection = LiteralsEncoder.encodeFourStreamHuffman(chunk) {
      var payload = literalsSection
      payload.append(0)  // Number_of_Sequences == 0: section ends immediately.
      if payload.count < best.payload.count {
        best = Candidate(type: .compressed, payload: payload)
      }
    }

    // Full LZ77 + FSE-coded sequences — tried against a *trial* copy of `repeatOffsets` (see
    // `SequenceStreamEncoder.encode`'s doc comment for why committing it back is conditional on
    // this candidate actually winning).
    let sequenceStore = BlockParser.parse(
      chunk, prefix: prefix, initialRepeatOffset: repeatOffsets.offset1, options: options)
    if !sequenceStore.sequences.isEmpty,
      let sequencesResult = SequenceStreamEncoder.encode(
        sequenceStore: sequenceStore, initialRepeatOffsets: repeatOffsets)
    {
      let literalsSection = LiteralsEncoder.encodeLiterals(sequenceStore.literals)
      let payload = literalsSection + sequencesResult.bytes
      if payload.count < best.payload.count {
        best = Candidate(type: .compressed, payload: payload)
        repeatOffsets = sequencesResult.finalOffsets
      }
    }

    return best
  }

  /// Every byte in `chunk` equal to the first — the reference's `ZSTD_isRLE`. Correctness-first
  /// scalar loop; a wide-word variant (the reference's actual technique) is a checked optimization
  /// to layer on later, not a decision this needs up front.
  private static func isRLE(_ chunk: [UInt8]) -> Bool {
    guard let first = chunk.first else { return false }
    return chunk.allSatisfy { $0 == first }
  }
}
