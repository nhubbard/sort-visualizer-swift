// This file's forward, LSB-first bit writer is the write-side mirror of `ForwardBitReader`,
// supporting FSE normalized-count table serialization (RFC 8878 §4.1.1). See NOTICE.md.
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

/// Writes an FSE normalized-count table description — LSB-first within each byte, exactly
/// mirroring `ForwardBitReader`'s read convention (`bit(at position) = (byte >> (position % 8)) &
/// 1`, position increasing = lower bits of a byte first, then the next byte).
struct ForwardBitWriter {
  private(set) var bytes: [UInt8] = []
  private var bitOffset: Int = 0

  /// Writes `count` bits (0...32) of `value`, least-significant bit first — the mirror of
  /// `ForwardBitReader.readBits`, which assembles `result |= UInt32(bit) << index` for increasing
  /// `index`, i.e. the first bit read becomes the result's LSB.
  mutating func writeBits(_ value: UInt32, count: Int) {
    precondition(count >= 0 && count <= 32)
    for index in 0..<count {
      let bit = UInt8((value >> index) & 1)
      let byteIndex = bitOffset / 8
      let bitIndex = bitOffset % 8
      if byteIndex == bytes.count {
        bytes.append(0)
      }
      bytes[byteIndex] |= bit << bitIndex
      bitOffset += 1
    }
  }

  /// Byte length just past the last bit written, rounded up — matches
  /// `ForwardBitReader.consumedBytes`, the offset where a following entropy-coded bitstream begins.
  var consumedBytes: Int { (bitOffset + 7) / 8 }
}
