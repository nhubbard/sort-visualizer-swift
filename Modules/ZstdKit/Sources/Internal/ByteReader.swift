// This module ports a subset of Zstandard's decoding algorithm (RFC 8878) from the real
// `zstd` C source; this reader's little-endian field assembly matches the byte layout every
// parser in this module relies on. See NOTICE.md.
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

/// A bounds-checked forward cursor over a byte buffer. Every read throws `.truncatedInput` rather
/// than trapping when it would run past the end — this is the safe-Swift parsing layer the plan's
/// safety model requires for anything outside the optimized (later, `Unsafe*`-using) hot path.
struct ByteReader {
  let bytes: [UInt8]
  private(set) var offset: Int

  init(_ bytes: [UInt8], offset: Int = 0) {
    self.bytes = bytes
    self.offset = offset
  }

  var remaining: Int { bytes.count - offset }

  func peekByte() throws -> UInt8 {
    guard offset < bytes.count else { throw ZstdError.truncatedInput }
    return bytes[offset]
  }

  /// Every byte not yet consumed, as a slice sharing storage with the underlying buffer.
  func remainingBytes() -> ArraySlice<UInt8> {
    bytes[offset...]
  }

  mutating func readByte() throws -> UInt8 {
    guard offset < bytes.count else { throw ZstdError.truncatedInput }
    defer { offset += 1 }
    return bytes[offset]
  }

  mutating func readBytes(_ count: Int) throws -> ArraySlice<UInt8> {
    guard count >= 0, count <= remaining else { throw ZstdError.truncatedInput }
    let slice = bytes[offset..<(offset + count)]
    offset += count
    return slice
  }

  /// Reconstructs an unsigned little-endian integer from `byteCount` bytes (0...8) via plain
  /// bit-shift assembly — never an aligned typed load.
  mutating func readLittleEndianUInt(byteCount: Int) throws -> UInt64 {
    guard byteCount >= 0, byteCount <= 8 else { throw ZstdError.invalidFrameHeader }
    let slice = try readBytes(byteCount)
    var value: UInt64 = 0
    for (index, byte) in slice.enumerated() {
      value |= UInt64(byte) << (8 * index)
    }
    return value
  }

  mutating func skip(_ count: Int) throws {
    guard count >= 0, count <= remaining else { throw ZstdError.truncatedInput }
    offset += count
  }
}
