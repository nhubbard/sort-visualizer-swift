// This file's LZ77 sequence execution (frame-scoped match history, byte-at-a-time overlapping
// copies) mirrors the real `zstd` C source's `ZSTD_execSequence`. See NOTICE.md.
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

/// Combines a block's literals buffer with its decoded `(literal_length, offset, match_length)`
/// sequences, appending the reconstructed bytes onto the frame's *cumulative* output — matches
/// can legitimately reference bytes an earlier block in this same frame wrote (the LZ77 window is
/// frame-scoped, not block-scoped; confirmed the hard way, via a real multi-block fixture whose
/// later blocks reference far enough back to only be satisfiable from a prior block's output).
/// Match bytes are appended via `MatchCopier`'s bulk-copy path (offset-tiled chunks rather than
/// one `append` call per byte), which handles the `offset < matchLength` overlapping case
/// correctly by construction — see that type's doc comment.
enum SequenceExecutor {
  static func execute(
    literals: [UInt8], sequences: [DecodedSequence], into output: inout [UInt8], limits: ZstdDecodingLimits
  ) throws {
    var literalsIndex = 0

    for sequence in sequences {
      guard literalsIndex + sequence.literalLength <= literals.count else {
        throw ZstdError.invalidSequenceStream
      }
      output.append(contentsOf: literals[literalsIndex..<(literalsIndex + sequence.literalLength)])
      literalsIndex += sequence.literalLength

      if sequence.matchLength > 0 {
        guard sequence.offset >= 1, sequence.offset <= output.count else {
          throw ZstdError.invalidMatchOffset
        }
        let matchStart = output.count - sequence.offset
        MatchCopier.copy(
          into: &output, matchStart: matchStart, matchLength: sequence.matchLength, offset: sequence.offset
        )
      }

      guard output.count <= limits.maximumOutputSize else {
        throw ZstdError.outputLimitExceeded(requested: output.count, limit: limits.maximumOutputSize)
      }
    }

    // Any literals left over after the last sequence are copied verbatim (RFC 8878 §3.1.1.3.2).
    if literalsIndex < literals.count {
      output.append(contentsOf: literals[literalsIndex...])
    }
  }
}
