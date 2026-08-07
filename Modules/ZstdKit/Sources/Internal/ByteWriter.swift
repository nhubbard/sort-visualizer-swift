// This module ports a subset of Zstandard's decoding algorithm (RFC 8878) from the real
// `zstd` C source; this writer's little-endian field assembly is the mirror image of
// `ByteReader`'s bit-shift assembly, used by the encoder side. See NOTICE.md.
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

/// A plain byte-aligned little-endian output cursor — the write-side mirror of `ByteReader`. No
/// bounds checking needed (unlike the reader): a writer only ever grows its own buffer.
struct ByteWriter {
  private(set) var bytes: [UInt8] = []

  mutating func writeByte(_ byte: UInt8) {
    bytes.append(byte)
  }

  mutating func writeBytes<S: Sequence>(_ newBytes: S) where S.Element == UInt8 {
    bytes.append(contentsOf: newBytes)
  }

  /// Writes `byteCount` (0...8) little-endian bytes of `value` — the literal mirror of
  /// `ByteReader.readLittleEndianUInt(byteCount:)`'s bit-shift assembly.
  mutating func writeLittleEndianUInt(_ value: UInt64, byteCount: Int) {
    precondition(byteCount >= 0 && byteCount <= 8)
    for index in 0..<byteCount {
      bytes.append(UInt8(truncatingIfNeeded: value >> (8 * index)))
    }
  }
}
