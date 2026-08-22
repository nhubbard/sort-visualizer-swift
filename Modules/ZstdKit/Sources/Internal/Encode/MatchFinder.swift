// This file's hash-chain match finder mirrors the real `zstd` C source's `greedy` strategy
// (`ZSTD_compressBlock_greedy`, `zstd_lazy.c`) — hash4/hash8 multiplicative hashing, separate-
// chaining hash table, and the `ZSTD_count` wide-word matching-byte-length trick. See NOTICE.md.
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

/// A greedy (no lookahead) LZ77 match finder over a single, fully in-memory buffer — no sliding-
/// window eviction, since the whole block already fits in memory (see Documentation/docs/reference/compression.md).
/// Matches are restricted to *within* the buffer it's constructed over (one block at a time,
/// never referencing a previous block) — a deliberate simplification: correct, if conservative,
/// since `SequenceExecutor` never requires cross-block matches, it just allows them.
final class MatchFinder: MatchFinding {
  private let input: [UInt8]
  private let hashLog: Int
  private let hashMask: Int
  private var hashTable: [Int]
  private var chain: [Int]
  private var nextToInsert = 0

  init(input: [UInt8], hashLog: Int) {
    self.input = input
    self.hashLog = hashLog
    self.hashMask = (1 << hashLog) - 1
    self.hashTable = [Int](repeating: -1, count: 1 << hashLog)
    self.chain = [Int](repeating: -1, count: max(input.count, 1))
  }

  /// `ZSTD_hash4Ptr`: a 4-byte little-endian window through a multiplicative/Fibonacci hash.
  private func hash(at position: Int) -> Int {
    let value =
      UInt32(input[position]) | (UInt32(input[position + 1]) << 8) | (UInt32(input[position + 2]) << 16)
      | (UInt32(input[position + 3]) << 24)
    let hashed = (value &* 2_654_435_761) >> (32 - hashLog)
    return Int(hashed) & hashMask
  }

  private func insert(_ position: Int) {
    guard position + 4 <= input.count else { return }
    let h = hash(at: position)
    chain[position] = hashTable[h]
    hashTable[h] = position
  }

  private func insertUpTo(_ position: Int) {
    while nextToInsert < position {
      insert(nextToInsert)
      nextToInsert += 1
    }
  }

  /// Searches for the best (longest) match at `ip` among up to `maxAttempts` chained candidates
  /// sharing its hash, then inserts `ip` itself for future searches. Returns `nil` if nothing
  /// found meeting `minMatch`.
  func findBestMatch(at ip: Int, minMatch: Int, maxAttempts: Int) -> (position: Int, length: Int)? {
    defer {
      insert(ip)
      nextToInsert = max(nextToInsert, ip + 1)
    }
    guard ip + 4 <= input.count else { return nil }
    insertUpTo(ip)

    var candidate = hashTable[hash(at: ip)]
    var attempts = 0
    var bestLength = 0
    var bestPosition = -1
    while candidate >= 0, attempts < maxAttempts {
      let length = wideWordMatchLength(in: input, ip, candidate)
      if length > bestLength {
        bestLength = length
        bestPosition = candidate
      }
      candidate = chain[candidate]
      attempts += 1
    }
    guard bestLength >= minMatch else { return nil }
    return (bestPosition, bestLength)
  }
}
