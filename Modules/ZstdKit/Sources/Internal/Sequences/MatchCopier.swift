// This file's match-copy specialization by offset (offset 1 as a fill, long nonoverlapping
// matches as one bulk copy, other overlapping offsets via periodic pattern expansion) follows the
// wildcopy strategy `COMPRESSION_AND_STRETCH_GOALS_PLAN.md` describes from the real `zstd` C
// source's `ZSTD_wildcopy`, adapted to safe Swift array operations rather than raw pointer chunks.
// See NOTICE.md.
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

/// Appends one LZ77 match's `matchLength` bytes, read starting `offset` bytes behind the current
/// end of `output`, in bulk rather than one byte per call.
///
/// The key fact that makes this correct without a byte-at-a-time loop: for any `offset`, the
/// first `min(offset, matchLength)` bytes of the match are always already-real data (they sit at
/// or before the position the match started from), and for `offset < matchLength` the match is
/// provably just that same `offset`-byte span **tiled** — `output[matchStart + i] ==
/// output[matchStart + i - offset]` recursively collapses to `output[matchStart + (i %
/// offset)]`, exactly the byte-at-a-time loop's own behavior, just computed in `offset`-sized
/// chunks instead of one byte at a time. `scalarCopy` stays byte-at-a-time and is kept as the
/// correctness oracle `MatchCopierTests` checks this against.
enum MatchCopier {
  static func copy(into output: inout [UInt8], matchStart: Int, matchLength: Int, offset: Int) {
    guard matchLength > 0 else { return }
    output.reserveCapacity(output.count + matchLength)

    if offset >= matchLength {
      // Fully nonoverlapping: the whole match is already sitting in `output`, verbatim.
      output.append(contentsOf: output[matchStart..<(matchStart + matchLength)])
      return
    }

    if offset == 1 {
      // The single-byte-period case (e.g. run-length repeats): a plain fill.
      output.append(contentsOf: repeatElement(output[matchStart], count: matchLength))
      return
    }

    var written = 0
    var readIndex = matchStart
    while written + offset <= matchLength {
      output.append(contentsOf: output[readIndex..<(readIndex + offset)])
      readIndex += offset
      written += offset
    }
    if written < matchLength {
      let remainder = matchLength - written
      output.append(contentsOf: output[readIndex..<(readIndex + remainder)])
    }
  }

  /// Byte-at-a-time reference implementation, kept only as a correctness oracle for tests — this
  /// is what `SequenceExecutor` used before the bulk-copy path above replaced it.
  static func scalarCopy(into output: inout [UInt8], matchStart: Int, matchLength: Int, offset: Int) {
    guard matchLength > 0 else { return }
    output.reserveCapacity(output.count + matchLength)
    for i in 0..<matchLength {
      output.append(output[matchStart + i])
    }
  }
}
