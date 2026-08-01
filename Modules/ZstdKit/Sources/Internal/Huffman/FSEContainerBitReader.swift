// This file is a faithful port of the reference `zstd` C source's container-based bitstream
// reader (`lib/common/bitstream.h`'s `BIT_initDStream`/`BIT_reloadDStream`/`BIT_readBits`) and its
// use in `FSE_decompress_usingDTable_generic`'s tail loop (`lib/common/fse_decompress.c`) — needed
// specifically for decoding a Huffman weight stream, where the number of symbols isn't known in
// advance and is instead determined by exactly when the bitstream runs out. A simplified
// bit-position heuristic was tried here first and was wrong: it matched one real fixture's tail
// parity by chance and produced too few symbols on another. This port replicates the real
// decoder's specific "container overflow" detection instead of approximating it. See NOTICE.md.
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

/// Status `reload()` reports, matching `BIT_DStream_status` exactly: `unfinished` (register fully
/// refilled from real bytes), `endOfBuffer` (some real bits remain but a full reload wasn't
/// possible), `completed` (every real bit has now been consumed, exactly), `overflow` (a caller
/// asked for bits beyond that point — the tail loop's actual termination signal).
enum FSEContainerReloadStatus {
  case unfinished
  case endOfBuffer
  case completed
  case overflow
}

/// A direct port of `BIT_DStream_t` — an 8-byte little-endian "container" window over the tail of
/// a byte buffer, refilled by sliding the window backward rather than reading one bit at a time.
/// Unlike `BackwardBitReader` (used everywhere else in `ZstdKit`), this type's `reload()` exposes
/// the reference decoder's exact overflow semantics, which the FSE weight-stream tail loop depends
/// on for correctness — see this file's header comment.
struct FSEContainerBitReader {
  private static let containerBytes = 8
  private static let containerBits = 64

  private let bytes: [UInt8]
  private let start = 0
  private let limitPointer = containerBytes
  private var pointer: Int
  private var bitContainer: UInt64
  private var bitsConsumed: Int

  init(_ bytes: [UInt8]) throws {
    guard let last = bytes.last, last != 0 else { throw ZstdError.invalidBitstream }
    self.bytes = bytes
    let highBit = 7 - last.leadingZeroBitCount
    if bytes.count >= Self.containerBytes {
      pointer = bytes.count - Self.containerBytes
      bitContainer = Self.readLittleEndian64(bytes, at: pointer)
      bitsConsumed = 8 - highBit
    } else {
      pointer = 0
      var container: UInt64 = 0
      for index in 0..<bytes.count {
        container |= UInt64(bytes[index]) << (8 * index)
      }
      bitContainer = container
      bitsConsumed = 8 - highBit + (Self.containerBytes - bytes.count) * 8
    }
  }

  mutating func readBits(_ count: Int) -> UInt64 {
    guard count > 0 else { return 0 }
    let shift = (Self.containerBits - bitsConsumed - count) & 63
    let mask: UInt64 = count >= 64 ? .max : (UInt64(1) << count) - 1
    let value = (bitContainer >> shift) & mask
    bitsConsumed += count
    return value
  }

  /// Matches `BIT_reloadDStream` exactly, including its specific ordering of checks — the tail
  /// loop that calls this only ever branches on `== .overflow`, not on any of the other statuses.
  @discardableResult
  mutating func reload() -> FSEContainerReloadStatus {
    if bitsConsumed > Self.containerBits {
      return .overflow
    }
    if pointer >= limitPointer {
      pointer -= bitsConsumed >> 3
      bitsConsumed &= 7
      bitContainer = Self.readLittleEndian64(bytes, at: pointer)
      return .unfinished
    }
    if pointer == start {
      return bitsConsumed < Self.containerBits ? .endOfBuffer : .completed
    }
    var byteCount = bitsConsumed >> 3
    let status: FSEContainerReloadStatus
    if pointer - byteCount < start {
      byteCount = pointer - start
      status = .endOfBuffer
    } else {
      status = .unfinished
    }
    pointer -= byteCount
    bitsConsumed -= byteCount * 8
    bitContainer = Self.readLittleEndian64(bytes, at: pointer)
    return status
  }

  /// Reads exactly 8 bytes starting at `offset`, little-endian — always in-bounds by this type's
  /// own invariants (`pointer` never goes low enough to need fewer than `containerBytes` real
  /// bytes once past `init`), but a release-mode bounds check regardless per the safety model.
  private static func readLittleEndian64(_ bytes: [UInt8], at offset: Int) -> UInt64 {
    guard offset >= 0, offset + containerBytes <= bytes.count else { return 0 }
    var value: UInt64 = 0
    for index in 0..<containerBytes {
      value |= UInt64(bytes[offset + index]) << (8 * index)
    }
    return value
  }
}
