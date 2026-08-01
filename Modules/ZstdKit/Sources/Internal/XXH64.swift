// This file is transcribed field-for-field from the reference `xxHash`/`zstd` source
// (`lib/common/xxhash.h`'s `XXH64_endian_align`/`XXH64_finalize`/`XXH64_round`/
// `XXH64_mergeRound`/`XXH64_avalanche`). See NOTICE.md.
//
// Used under the BSD License:
//
// BSD License
//
// For Zstandard software
//
// Copyright (c) Yann Collet - Meta Platforms, Inc. All rights reserved.
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

/// XXH64 (seed 0), the content-checksum algorithm Zstd frames use (RFC 8878 §3.1.1): the frame
/// trailer stores only the low 32 bits of this 64-bit digest, little-endian. Transcribed field-for-
/// field from the reference `xxHash`/`zstd` source (`lib/common/xxhash.h`'s `XXH64_endian_align`/
/// `XXH64_finalize`/`XXH64_round`/`XXH64_mergeRound`/`XXH64_avalanche`), not derived from
/// second-hand descriptions — verified against XXH64's own published test vectors first, then
/// against real Zstd-produced checksummed frames.
enum XXH64 {
  private static let prime1: UInt64 = 0x9E37_79B1_85EB_CA87
  private static let prime2: UInt64 = 0xC2B2_AE3D_27D4_EB4F
  private static let prime3: UInt64 = 0x1656_67B1_9E37_79F9
  private static let prime4: UInt64 = 0x85EB_CA77_C2B2_AE63
  private static let prime5: UInt64 = 0x27D4_EB2F_1656_67C5

  static func digest(_ bytes: [UInt8], seed: UInt64 = 0) -> UInt64 {
    let count = bytes.count
    var index = 0
    var h64: UInt64

    if count >= 32 {
      let limit = count - 32
      var v1 = seed &+ prime1 &+ prime2
      var v2 = seed &+ prime2
      var v3 = seed
      var v4 = seed &- prime1
      repeat {
        v1 = round(v1, readUInt64LE(bytes, index)); index += 8
        v2 = round(v2, readUInt64LE(bytes, index)); index += 8
        v3 = round(v3, readUInt64LE(bytes, index)); index += 8
        v4 = round(v4, readUInt64LE(bytes, index)); index += 8
      } while index <= limit
      h64 = rotl(v1, 1) &+ rotl(v2, 7) &+ rotl(v3, 12) &+ rotl(v4, 18)
      h64 = mergeRound(h64, v1)
      h64 = mergeRound(h64, v2)
      h64 = mergeRound(h64, v3)
      h64 = mergeRound(h64, v4)
    } else {
      h64 = seed &+ prime5
    }

    h64 &+= UInt64(count)

    var remaining = count - index
    while remaining >= 8 {
      let k1 = round(0, readUInt64LE(bytes, index))
      index += 8
      h64 ^= k1
      h64 = rotl(h64, 27) &* prime1 &+ prime4
      remaining -= 8
    }
    if remaining >= 4 {
      h64 ^= UInt64(readUInt32LE(bytes, index)) &* prime1
      index += 4
      h64 = rotl(h64, 23) &* prime2 &+ prime3
      remaining -= 4
    }
    while remaining > 0 {
      h64 ^= UInt64(bytes[index]) &* prime5
      index += 1
      h64 = rotl(h64, 11) &* prime1
      remaining -= 1
    }

    return avalanche(h64)
  }

  /// The low 32 bits of `digest`, as stored in a Zstd frame's checksum trailer (`(U32)
  /// XXH64_digest(...)` on the reference encoder side — a plain truncating cast, i.e. the
  /// low-order 32 bits, not a re-hash).
  static func checksum32(_ bytes: [UInt8], seed: UInt64 = 0) -> UInt32 {
    UInt32(truncatingIfNeeded: digest(bytes, seed: seed))
  }

  private static func round(_ accumulator: UInt64, _ input: UInt64) -> UInt64 {
    var accumulator = accumulator
    accumulator &+= input &* prime2
    accumulator = rotl(accumulator, 31)
    accumulator &*= prime1
    return accumulator
  }

  private static func mergeRound(_ accumulator: UInt64, _ value: UInt64) -> UInt64 {
    let mixed = round(0, value)
    var accumulator = accumulator ^ mixed
    accumulator = accumulator &* prime1 &+ prime4
    return accumulator
  }

  private static func avalanche(_ hash: UInt64) -> UInt64 {
    var hash = hash
    hash ^= hash >> 33
    hash &*= prime2
    hash ^= hash >> 29
    hash &*= prime3
    hash ^= hash >> 32
    return hash
  }

  private static func rotl(_ value: UInt64, _ count: UInt64) -> UInt64 {
    (value << count) | (value >> (64 - count))
  }

  private static func readUInt64LE(_ bytes: [UInt8], _ index: Int) -> UInt64 {
    var result: UInt64 = 0
    for byteIndex in 0..<8 {
      result |= UInt64(bytes[index + byteIndex]) << (8 * byteIndex)
    }
    return result
  }

  private static func readUInt32LE(_ bytes: [UInt8], _ index: Int) -> UInt32 {
    var result: UInt32 = 0
    for byteIndex in 0..<4 {
      result |= UInt32(bytes[index + byteIndex]) << (8 * byteIndex)
    }
    return result
  }
}
