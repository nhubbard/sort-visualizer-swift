// This file's MSB-first, read-from-the-tail bitstream convention (and the sentinel-bit
// handling that locates the true start of a stream) matches `zstd`'s `BIT_initDStream`/
// `BIT_readBits` exactly — confirmed empirically against real zstd fixtures, not derived
// from the RFC prose alone. See NOTICE.md.
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

/// Reads a Zstd entropy bitstream (Huffman or FSE) from its END toward its START — the convention
/// both formats share. The last byte's highest set bit is a padding sentinel (not data); reading
/// proceeds MSB-first from just below it, walking backward through the buffer. Multi-bit reads
/// accumulate with the first-read bit as the result's most-significant bit, matching how the
/// reference decoder's `BIT_lookBits`/`BIT_readBits` extract from the top of a right-aligned
/// window loaded from the tail of the buffer — confirmed empirically against real zstd fixtures
/// during development (see ZstdKit's Huffman/FSE tests), not derived from the spec text alone.
struct BackwardBitReader {
  private let bytes: [UInt8]
  private var bytePosition: Int
  private var bitPosition: Int

  /// Cache for the word-refill fast path in `readBits`: `window` is a big-endian assembly of
  /// `bytes[windowBase-7...windowBase]` (byte `windowBase` in bits 63...56, one byte per 8-bit
  /// lane going down), reused across calls until `bytePosition` drops more than 3 bytes below
  /// `windowBase` (see `readBits`'s comment for why 3, not the full 7-byte span the window
  /// covers). `-1` means "not loaded yet."
  private var window: UInt64 = 0
  private var windowBase: Int = -1

  init(_ bytes: [UInt8]) throws {
    guard let last = bytes.last, last != 0 else {
      throw ZstdError.invalidBitstream
    }
    self.bytes = bytes
    self.bytePosition = bytes.count - 1
    var sentinelBit = 7
    while (last & (1 << sentinelBit)) == 0 { sentinelBit -= 1 }
    self.bitPosition = sentinelBit - 1
  }

  /// `false` once every real bit (everything below the sentinel) has been consumed. Reading past
  /// this point is well-defined (see `readBits`), not a bounds violation — the last lookahead at
  /// the tail of a stream routinely peeks a few bits past the actual data.
  var hasBitsRemaining: Bool {
    bytePosition > 0 || bitPosition >= 0
  }

  /// Reads `count` bits (0...32). Reads that run past the start of the buffer are padded with
  /// zero — every real decoder tolerates this for the final lookahead of a stream, where a fixed
  /// lookahead width can overshoot the last few genuine bits.
  mutating func readBits(_ count: Int) -> UInt32 {
    guard count > 0 else { return 0 }

    // Fast path: with at most 7 unread bits left in the current byte, a 32-bit read needs at most
    // 4 more whole bytes below it (`ceil((32-1)/8)`); requiring 7 full bytes below the current one
    // (`bytePosition >= 7`) keeps this path entirely inside real, already-buffered bytes with
    // margin to spare — no "ran past the start, pad with zero" case to reproduce here at all,
    // unlike the scalar path below. That's what makes it safe to add without touching the tricky
    // near-the-end behavior that a real bug already hid in once (see `HuffmanTable.swift`'s
    // weight-decode history): every case this path handles has an oracle-checked identical twin
    // below, exercised by `BackwardBitReaderTests`'s differential tests, and every case it
    // *doesn't* handle (the last 7 bytes of any stream, or a >32-bit read) still runs the exact
    // original scalar loop, unchanged.
    if bytePosition >= 7, count <= 32 {
      // `window` stays valid (and is reused across calls without reloading) as long as
      // `bytePosition` sits no more than 3 bytes below `windowBase`, the byte it was loaded for —
      // that keeps at least 4 whole bytes of margin below `bytePosition` inside the window, which
      // a worst-case 32-bit read (`bitPosition == 0`) needs. A wider reuse range was tried first
      // and was wrong: once `bytePosition` drops far enough that fewer than 4 bytes remain below
      // it *within the stale window*, the shift below goes negative — caught by
      // `BackwardBitReaderTests` before this ever reached the scalar-path fallback it was meant
      // to avoid.
      if windowBase < 0 || bytePosition < windowBase - 3 {
        loadWindow()
      }
      let topOffset = windowBase - bytePosition
      let shift = 56 - 8 * topOffset + bitPosition - count + 1
      let mask = (UInt64(1) << count) - 1
      let result = (window >> shift) & mask
      let newPosition = bytePosition * 8 + bitPosition - count
      bytePosition = newPosition / 8
      bitPosition = newPosition % 8
      return UInt32(truncatingIfNeeded: result)
    }

    var result: UInt32 = 0
    var remaining = count
    while remaining > 0 {
      if bitPosition < 0 {
        bytePosition -= 1
        guard bytePosition >= 0 else {
          return result << UInt32(remaining)
        }
        bitPosition = 7
      }
      let bit = (bytes[bytePosition] >> bitPosition) & 1
      result = (result << 1) | UInt32(bit)
      bitPosition -= 1
      remaining -= 1
    }
    return result
  }

  /// Reads `count` bits without consuming them — used for Huffman's flat-LUT lookahead, where the
  /// table index must be inspected before the actual per-symbol bit count is known.
  func peekBits(_ count: Int) -> UInt32 {
    var copy = self
    return copy.readBits(count)
  }

  private mutating func loadWindow() {
    // Byte `bytePosition` must land in the top 8 bits (63...56), so it's folded in *first* —
    // each byte folded in afterward shifts everything already there one lane higher.
    var value: UInt64 = 0
    for offset in 0..<8 {
      value = (value << 8) | UInt64(bytes[bytePosition - offset])
    }
    window = value
    windowBase = bytePosition
  }
}
