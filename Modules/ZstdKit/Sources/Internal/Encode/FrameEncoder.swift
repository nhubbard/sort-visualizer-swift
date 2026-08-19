// This file's frame-header field layout is the write-side mirror of `FrameHeader.swift`'s parse
// logic (RFC 8878 §3.1.1.1) as implemented by the real `zstd` C source. See NOTICE.md.
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

import Foundation

private let zstdMagicNumber: UInt64 = 0xFD2F_B528

/// Orchestrates a full frame encode: header, then the block loop, then an optional checksum
/// trailer — the write-side mirror of `ZstdDecompressor`'s top-level flow.
///
/// Always writes `Single_Segment_flag = 1` (this encoder holds the whole input in memory, so the
/// content size is always known up front) and never sets `Dictionary_ID_flag` (no dictionary
/// support — see Documentation/docs/reference/compression.md), which together mean the window-descriptor byte and
/// dictionary-ID field are always absent, not just narrowed.
enum FrameEncoder {
  static func encode(_ input: [UInt8], options: ZstdEncodingOptions) throws -> [UInt8] {
    guard input.count <= options.maximumInputSize else {
      throw ZstdEncodeError.inputTooLarge(requested: input.count, limit: options.maximumInputSize)
    }

    var writer = ByteWriter()
    writer.writeLittleEndianUInt(zstdMagicNumber, byteCount: 4)

    let (frameContentSizeFlag, fieldByteCount) = frameContentSizeEncoding(for: input.count)
    let descriptor: UInt8 =
      (frameContentSizeFlag << 6) | (1 << 5) | (options.checksum ? 1 << 2 : 0)
    writer.writeByte(descriptor)
    // No window descriptor (single-segment) and no Dictionary_ID field (flag always 0 — see
    // this type's doc comment).

    if fieldByteCount > 0 {
      let wireValue = fieldByteCount == 2 ? UInt64(input.count) - 256 : UInt64(input.count)
      writer.writeLittleEndianUInt(wireValue, byteCount: fieldByteCount)
    }

    writer.writeBytes(encodeBlocks(input, options: options))

    if options.checksum {
      // Runs over the complete buffer in one shot, entirely unaffected by whether blocks were
      // encoded sequentially or across several parallel chunks below — real zstd's multithreaded
      // mode needs an incrementally-fed, job-ordered checksum specifically because it streams
      // (never holds the whole input in memory); this encoder always does, so that whole piece of
      // complexity doesn't apply here.
      writer.writeLittleEndianUInt(UInt64(XXH64.checksum32(input)), byteCount: 4)
    }

    return writer.bytes
  }

  /// Sequential when `options.maximumConcurrency <= 1` or `input` isn't large enough to fill more
  /// than one parallel chunk — today's exact behavior, byte-for-byte, is this function's single-
  /// chunk case, not a separately-maintained code path. Above that, splits `input` into
  /// `options.maximumConcurrency` roughly-equal chunks (each still `>= maximumBlockSize`, so a
  /// chunk is never smaller than one real block) and encodes them concurrently via
  /// `DispatchQueue.concurrentPerform` — `TaskGroup` would need `Zstd.compress` to become `async`,
  /// which would force a real redesign of `Tape.archived()`/`RunControlBar`'s already-shipped
  /// Export Tape button (a SwiftUI `View` body-time computed property, which cannot `await`); this
  /// delivers the identical genuine-multi-core value without that ripple (see
  /// Documentation/docs/reference/compression.md). Each chunk gets its own fresh `EncodeRepeatOffsets` (mirroring real
  /// zstd's multithreaded mode's per-job reset) and, past the first chunk, a raw-content "prefix"
  /// (the previous chunk's own tail, capped at `maximumBlockSize`) so a match can still reference
  /// across the boundary even though the cheap repeat-offset optimization can't. Results are
  /// collected into an index-ordered array (never append-as-completed), so the output is
  /// deterministic regardless of which chunk's thread finishes first.
  private static func encodeBlocks(_ input: [UInt8], options: ZstdEncodingOptions) -> [UInt8] {
    let parallelChunkSize = max(maximumBlockSize, input.count / max(1, options.maximumConcurrency))
    guard options.maximumConcurrency > 1, input.count > parallelChunkSize else {
      var writer = ByteWriter()
      // Frame-scoped, reset once here (never per block) — matches decode's own `RepeatOffsets`
      // lifetime exactly (RFC 8878 §3.1.1.3.2.1.2).
      var repeatOffsets = EncodeRepeatOffsets()
      let blocks = chunked(input, into: maximumBlockSize)
      for (index, block) in blocks.enumerated() {
        let isLast = index == blocks.count - 1
        writer.writeBytes(
          BlockEncoder.encode(block, isLastBlock: isLast, options: options, repeatOffsets: &repeatOffsets))
      }
      return writer.bytes
    }

    let parallelChunks = chunked(input, into: parallelChunkSize)
    var offsets: [Int] = []
    var runningOffset = 0
    for chunk in parallelChunks {
      offsets.append(runningOffset)
      runningOffset += chunk.count
    }
    // Frozen into a `let` before the concurrent section starts — every write already happened
    // above, so this capture is genuinely immutable by the time `concurrentPerform`'s closure
    // reads it, silencing the compiler's (otherwise-legitimate) concern about a captured `var` in
    // concurrently-executing code without needing an unsafe escape hatch.
    let chunkStartOffsets = offsets

    // `results`, unlike `chunkStartOffsets`, genuinely is mutated from multiple threads — safe
    // because every access (the write below, and the read once `concurrentPerform` returns) is
    // strictly serialized by `lock`, which the compiler can't see from the closure's shape alone.
    nonisolated(unsafe) var results = [[UInt8]?](repeating: nil, count: parallelChunks.count)
    let lock = NSLock()
    DispatchQueue.concurrentPerform(iterations: parallelChunks.count) { index in
      let chunkStart = chunkStartOffsets[index]
      let prefixLength = min(chunkStart, maximumBlockSize)
      let prefix = prefixLength > 0 ? Array(input[(chunkStart - prefixLength)..<chunkStart]) : []
      let isLastChunk = index == parallelChunks.count - 1
      let encoded = encodeParallelChunk(
        parallelChunks[index], prefix: prefix, isLastChunk: isLastChunk, options: options)
      lock.lock()
      results[index] = encoded
      lock.unlock()
    }

    var writer = ByteWriter()
    for result in results {
      writer.writeBytes(result ?? [])
    }
    return writer.bytes
  }

  /// One parallel chunk's own internal block loop — a fresh `EncodeRepeatOffsets` scoped to just
  /// this chunk (not the whole frame), `prefix` only ever handed to the chunk's own first block
  /// (later blocks within the same chunk already have zero access to *any* of this chunk's own
  /// earlier blocks, a pre-existing limitation this phase doesn't change — see
  /// Documentation/docs/reference/compression.md).
  private static func encodeParallelChunk(
    _ chunk: [UInt8], prefix: [UInt8], isLastChunk: Bool, options: ZstdEncodingOptions
  ) -> [UInt8] {
    var repeatOffsets = EncodeRepeatOffsets()
    var writer = ByteWriter()
    let blocks = chunked(chunk, into: maximumBlockSize)
    for (index, block) in blocks.enumerated() {
      let isLastBlock = isLastChunk && index == blocks.count - 1
      let blockPrefix = index == 0 ? prefix : []
      writer.writeBytes(
        BlockEncoder.encode(
          block, prefix: blockPrefix, isLastBlock: isLastBlock, options: options,
          repeatOffsets: &repeatOffsets))
    }
    return writer.bytes
  }

  /// Mirrors `FrameHeaderParser`'s field-size table exactly: flag 0 is 1 byte, direct value
  /// (0...255); flag 1 is 2 bytes, wire value is `actualSize - 256` (256...65,791); flag 2 is 4
  /// bytes, direct value; flag 3 is 8 bytes, direct value.
  private static func frameContentSizeEncoding(for size: Int) -> (flag: UInt8, byteCount: Int) {
    switch size {
    case 0...255: return (0, 1)
    case 256...65791: return (1, 2)
    case 65792...Int(UInt32.max): return (2, 4)
    default: return (3, 8)
    }
  }

  private static func chunked(_ input: [UInt8], into size: Int) -> [[UInt8]] {
    guard !input.isEmpty else { return [[]] }
    var result: [[UInt8]] = []
    var index = 0
    while index < input.count {
      let end = min(index + size, input.count)
      result.append(Array(input[index..<end]))
      index = end
    }
    return result
  }
}
