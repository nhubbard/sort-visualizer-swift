// This file's forward, LSB-first bit reader supports FSE normalized-count table parsing
// (RFC 8878 §4.1.1), matching `zstd`'s own `BIT_initDStream`-forward-direction convention
// used for the same purpose. See NOTICE.md.
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

/// Reads an FSE normalized-count table description — the one part of the entropy-coding sections
/// read forward, LSB-first within each byte (opposite of `BackwardBitReader`, which reads the
/// entropy-coded symbol bitstream that follows it). Bounds-checked: unlike the backward reader,
/// running past the end here means the declared table description is truncated, a real error.
struct ForwardBitReader {
  private let bytes: [UInt8]
  private var bitOffset: Int = 0

  init(_ bytes: [UInt8]) {
    self.bytes = bytes
  }

  mutating func readBits(_ count: Int) throws -> UInt32 {
    guard count >= 0, count <= 32 else { throw ZstdError.invalidFSETable }
    var result: UInt32 = 0
    for index in 0..<count {
      let bit = try bit(at: bitOffset + index)
      result |= UInt32(bit) << index
    }
    bitOffset += count
    return result
  }

  /// Puts back `count` bits — the normalized-count algorithm sometimes over-reads by 1 bit to
  /// check a fast-path condition, then un-reads it once the condition is known to be false.
  mutating func rewind(bits count: Int) {
    bitOffset -= count
  }

  /// Byte offset just past the last bit read, rounded up — where the entropy-coded bitstream that
  /// follows this table description begins.
  var consumedBytes: Int { (bitOffset + 7) / 8 }

  private func bit(at position: Int) throws -> UInt8 {
    let byteIndex = position / 8
    guard byteIndex < bytes.count else { throw ZstdError.invalidFSETable }
    return (bytes[byteIndex] >> (position % 8)) & 1
  }
}
