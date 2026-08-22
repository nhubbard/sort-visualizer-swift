// This file's canonical-code derivation reuses the exact rankCount/rankStart construction
// `HuffmanTable.swift`'s decode-table builder uses (RFC 8878 §4.2), run in the same order so the
// resulting codewords are guaranteed consistent with that already-verified decode table. See
// NOTICE.md.
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

private let maximumHuffmanWeight = 11

/// One symbol's Huffman codeword: `nbBits` bits, MSB-first, value `code` (code fits in the low
/// `nbBits` bits).
struct HuffmanCode {
  let nbBits: Int
  let code: Int
}

struct HuffmanEncodeTable {
  /// Dense, index = symbol value, size `maxSymbolValue + 1`. `nil` for symbols that don't occur.
  let codes: [HuffmanCode?]
  /// Weight per symbol (RFC 8878 §4.2.1: `weight = maxBits + 1 - nbBits`, `0` for unused), same
  /// indexing as `codes` — what actually gets serialized into the table description.
  let weights: [Int]
  let maxBits: Int
}

enum HuffmanEncodeTableBuilder {
  /// Builds a Huffman table from a byte histogram, or returns `nil` when Huffman literals aren't
  /// usable for this data: fewer than 2 distinct symbols (nothing to gain over RLE), or the
  /// natural code-length spread exceeds what an 11-value weight can represent (`maxBits - minBits
  /// > 10` — real data essentially never hits this; package-merge depth-limiting to force it would
  /// be the fix, deferred rather than needed for the common case).
  static func build(histogram: [Int]) -> HuffmanEncodeTable? {
    let used = histogram.enumerated().filter { $0.element > 0 }
    guard used.count >= 2 else { return nil }

    var lengths = huffmanCodeLengths(counts: used.map { (symbol: $0.offset, count: $0.element) })
    guard let maxBits = lengths.values.max(), let minBits = lengths.values.min() else { return nil }
    guard maxBits - minBits <= maximumHuffmanWeight - 1, maxBits <= 16 else { return nil }

    let maxSymbolValue = used.map(\.offset).max() ?? 0
    var weights = [Int](repeating: 0, count: maxSymbolValue + 1)
    for (symbol, nbBits) in lengths {
      weights[symbol] = maxBits + 1 - nbBits
    }
    lengths.removeAll()  // no longer needed; codes derived from weights below like decode does

    let codes = buildCanonicalCodes(weights: weights, maxBits: maxBits)
    return HuffmanEncodeTable(codes: codes, weights: weights, maxBits: maxBits)
  }

  /// Standard "repeatedly merge the two smallest" Huffman construction. `O(n^2)` in the number of
  /// distinct symbols (at most 256 here) — correctness-first; the reference's `O(n)` pre-sorted
  /// merge trick is a micro-optimization this doesn't need.
  private static func huffmanCodeLengths(counts: [(symbol: Int, count: Int)]) -> [Int: Int] {
    final class Node {
      var count: Int
      let symbol: Int?
      var left: Node?
      var right: Node?
      init(count: Int, symbol: Int?) {
        self.count = count
        self.symbol = symbol
      }
    }

    var queue = counts.map { Node(count: $0.count, symbol: $0.symbol) }
    while queue.count > 1 {
      queue.sort { $0.count < $1.count }
      let a = queue.removeFirst()
      let b = queue.removeFirst()
      let merged = Node(count: a.count + b.count, symbol: nil)
      merged.left = a
      merged.right = b
      queue.append(merged)
    }

    var lengths: [Int: Int] = [:]
    func walk(_ node: Node, depth: Int) {
      if let symbol = node.symbol {
        lengths[symbol] = max(depth, 1)
        return
      }
      if let left = node.left { walk(left, depth: depth + 1) }
      if let right = node.right { walk(right, depth: depth + 1) }
    }
    if let root = queue.first { walk(root, depth: 0) }
    return lengths
  }

  /// Exactly `HuffmanTableBuilder.buildDecodeTable`'s `rankCount`/`rankStart` construction, but
  /// recording a codeword per symbol instead of populating a flat LUT. Running the identical
  /// iteration order guarantees the codewords this produces are the ones that decode table would
  /// actually expect: within a weight class, symbols are assigned consecutive codeword values in
  /// ascending symbol-value order, exactly as `buildDecodeTable` assigns them consecutive LUT
  /// block ranges — a symbol's codeword is that assigned LUT-block start, right-shifted by
  /// `weight - 1` (the block width in bits).
  private static func buildCanonicalCodes(weights: [Int], maxBits: Int) -> [HuffmanCode?] {
    var rankCount = [Int](repeating: 0, count: maxBits + 2)
    for weight in weights {
      rankCount[weight] += 1
    }
    var rankStart = [Int](repeating: 0, count: maxBits + 2)
    var cursor = 0
    for weight in 1...maxBits {
      rankStart[weight] = cursor
      cursor += rankCount[weight] * (1 << (weight - 1))
    }

    var codes = [HuffmanCode?](repeating: nil, count: weights.count)
    for (symbol, weight) in weights.enumerated() where weight > 0 {
      let nbBits = maxBits + 1 - weight
      let slotCount = 1 << (weight - 1)
      let start = rankStart[weight]
      codes[symbol] = HuffmanCode(nbBits: nbBits, code: start >> (weight - 1))
      rankStart[weight] += slotCount
    }
    return codes
  }
}
