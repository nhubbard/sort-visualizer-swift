// This file's MSB-first, write-from-the-tail bitstream convention is the write-side mirror of
// `BackwardBitReader` — see that file's own doc comment for the empirically-confirmed convention
// this must produce. See NOTICE.md.
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

/// Builds a Zstd entropy bitstream (Huffman or FSE) so that `BackwardBitReader`, reading from the
/// end toward the start, recovers exactly the sequence of `writeBits` calls made here, in the same
/// order and with the same per-field MSB-first bit assembly.
///
/// Construction: every `writeBits` call is buffered (not packed into bytes immediately), because
/// the sentinel's position depends on the *total* real bit count, which isn't known until
/// `finish()`. Real zstd's `BIT_addBits`/`BIT_closeCStream` grow a bit-position counter from 0
/// upward and add the sentinel at whatever position immediately follows the last real bit —
/// wherever that lands within a byte, not necessarily at a byte boundary. Mirroring that in this
/// tail-anchored, per-byte-MSB-first convention means the sentinel must NOT always sit at bit 7 of
/// the final byte: the padding needed to round up to a whole byte has to sit *above* the sentinel,
/// packed into the *same* final byte as real data continuing below it — not, as an earlier version
/// of this file did, off in a separate byte at the opposite end of the buffer. That earlier version
/// packed the sentinel unconditionally at bit 7 first and let any partial-byte padding fall to the
/// low bits of whatever byte was left over at the *other* end — self-consistent against
/// `BackwardBitReader` (so every round-trip test passed), but real zstd's `BIT_endOfDStream` check
/// requires the total consumed-bit count to land exactly on a container-width boundary, which only
/// holds when the padding is adjacent to the sentinel. Confirmed by cross-referencing
/// `~/zstd/lib/common/bitstream.h`'s `BIT_addBits`/`BIT_closeCStream`/`BIT_initDStream` and by
/// building a debug (`DEBUGLEVEL=6`) libzstd to watch `BIT_endOfDStream` fail on the old encoding —
/// see `COMPRESSION_DESIGN.md`.
struct BackwardBitWriter {
  private var pending: [(value: UInt32, count: Int)] = []
  private var totalRealBits = 0

  init() {}

  /// Writes `count` bits (0...32) of `value`, most-significant bit first — the mirror of
  /// `BackwardBitReader.readBits`, which assembles a multi-bit field with the first-consumed bit
  /// as the result's MSB. Buffered, not packed yet — see the type's doc comment.
  mutating func writeBits(_ value: UInt32, count: Int) {
    precondition(count >= 0 && count <= 32)
    guard count > 0 else { return }
    pending.append((value, count))
    totalRealBits += count
  }

  /// Packs the sentinel `1` bit, preceded by however many zero padding bits are needed to round
  /// `1 + totalRealBits` up to a whole byte, followed by every buffered `writeBits` call in order —
  /// all in one pass, MSB-first per byte — then reverses byte order to produce the reader's
  /// tail-anchored layout (sentinel ends up at the top of the *last* byte's real content, with any
  /// padding directly above it in that same byte, exactly where `BIT_closeCStream` would leave it).
  mutating func finish() -> [UInt8] {
    let paddingBits = (8 - (1 + totalRealBits) % 8) % 8
    var bytes: [UInt8] = []
    var currentByte: UInt8 = 0
    var bitsInCurrentByte = 0
    func pushBit(_ bit: UInt8) {
      currentByte |= (bit & 1) << (7 - bitsInCurrentByte)
      bitsInCurrentByte += 1
      if bitsInCurrentByte == 8 {
        bytes.append(currentByte)
        currentByte = 0
        bitsInCurrentByte = 0
      }
    }
    for _ in 0..<paddingBits { pushBit(0) }
    pushBit(1)
    for (value, count) in pending {
      for index in stride(from: count - 1, through: 0, by: -1) {
        pushBit(UInt8((value >> index) & 1))
      }
    }
    if bitsInCurrentByte > 0 {
      bytes.append(currentByte)
    }
    return bytes.reversed()
  }
}
