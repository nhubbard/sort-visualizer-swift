// This file's Huffman weight decoding (including the FSE-compressed weight stream's
// two-interleaved-state loop) and canonical decode-table construction are transcribed from
// the real `zstd` C source (`HUF_readStats`, `HUF_buildDTableX1`), confirmed bit-exact
// against a faithful port of its container-based bitstream semantics. See NOTICE.md.
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

/// A flat decode LUT: `1 << maxBits` entries, each giving the symbol and bit-count for that
/// `maxBits`-bit lookahead window. Built once per `Compressed` literals block and reused verbatim
/// by a following `Treeless` block.
struct HuffmanDecodeTable {
  let maxBits: Int
  let symbolOf: [UInt8]
  let numberOfBits: [UInt8]
}

struct ParsedHuffmanTable {
  let table: HuffmanDecodeTable
  /// Bytes consumed by the table description itself (including its header byte) — the Huffman-
  /// coded symbol bitstream starts immediately after.
  let consumedBytes: Int
}

/// The maximum weight value (RFC 8878 §4.2.1) — Huffman code lengths top out at 11 bits.
private let maximumHuffmanWeight = 11
/// The weight-distribution FSE table's own accuracy-log ceiling — real zstd hardcodes this as a
/// literal `6` at its one call site (`entropy_common.c`'s `FSE_decompress_wksp_bmi2(...,  6, ...)`
/// inside `HUF_readStats_body`), distinct from `HUF_TABLELOG_MAX` (12), which bounds the actual
/// Huffman table built *from* those weights, not the FSE table describing the weights themselves.
/// A previous version of this port conflated the two, using 12 here — validation-only (a real
/// encoder never emits a weight-FSE tableLog anywhere near either bound), so it never produced
/// wrong output, but it would wrongly accept a malformed tableLog in the 7...12 range that real
/// zstd rejects outright.
private let maximumWeightAccuracyLog = 6

enum HuffmanTableBuilder {
  static func parse(_ bytes: ArraySlice<UInt8>) throws -> ParsedHuffmanTable {
    guard let headerByte = bytes.first else { throw ZstdError.invalidHuffmanTable }
    let base = bytes.startIndex
    let weights: [Int]
    let consumedBytes: Int

    if headerByte >= 128 {
      let symbolCount = Int(headerByte) - 127
      let packedByteCount = (symbolCount + 1) / 2
      guard bytes.count >= 1 + packedByteCount else { throw ZstdError.invalidHuffmanTable }
      let packed = bytes[(base + 1)..<(base + 1 + packedByteCount)]
      var explicitWeights: [Int] = []
      explicitWeights.reserveCapacity(symbolCount)
      for byte in packed {
        explicitWeights.append(Int(byte >> 4))
        explicitWeights.append(Int(byte & 0xF))
      }
      weights = try appendingImplicitLastWeight(explicitWeights.prefix(symbolCount).map { $0 })
      consumedBytes = 1 + packedByteCount
    } else {
      let weightSectionLength = Int(headerByte)
      guard bytes.count >= 1 + weightSectionLength else { throw ZstdError.invalidHuffmanTable }
      let weightSection = Array(bytes[(base + 1)..<(base + 1 + weightSectionLength)])
      let explicitWeights = try decodeFSECompressedWeights(weightSection)
      weights = try appendingImplicitLastWeight(explicitWeights)
      consumedBytes = 1 + weightSectionLength
    }

    let table = try buildDecodeTable(weights: weights)
    return ParsedHuffmanTable(table: table, consumedBytes: consumedBytes)
  }

  /// Decodes weight values 0...11 from a dedicated FSE-coded stream. The count of weights isn't
  /// stored: decoding continues (2 interleaved states, per RFC 8878 §4.2.1.3) until the bitstream
  /// is exhausted, and the *last* weight is never transmitted — it's derived so the full weight
  /// set's Kraft sum completes to a power of two.
  private static func decodeFSECompressedWeights(_ weightSection: [UInt8]) throws -> [Int] {
    var forwardReader = ForwardBitReader(weightSection)
    let (accuracyLog, counts) = try FSETableBuilder.readNormalizedCounts(
      &forwardReader, maxSymbol: maximumHuffmanWeight, maximumAccuracyLog: maximumWeightAccuracyLog
    )
    let table = try FSETableBuilder.buildDecodeTable(counts: counts, accuracyLog: accuracyLog)

    let bitstreamStart = forwardReader.consumedBytes
    guard bitstreamStart <= weightSection.count else { throw ZstdError.invalidHuffmanTable }
    var reader = try FSEContainerBitReader(Array(weightSection[bitstreamStart...]))

    var state1 = Int(reader.readBits(accuracyLog))
    var state2 = Int(reader.readBits(accuracyLog))
    // Matches `FSE_decompress_usingDTable_generic`'s own
    // `RETURN_ERROR_IF(BIT_reloadDStream(&bitD)==BIT_DStream_overflow, corruption_detected, "")`,
    // performed once right after initializing both states and before decoding a single symbol —
    // a previous version of this port omitted it and went straight to the tail loop below, so a
    // bitstream too short to even hold two initial states (real fixture: `truncated_huff_state`)
    // decoded zero symbols instead of being rejected as corrupt.
    guard reader.reload() != .overflow else { throw ZstdError.invalidHuffmanTable }
    var weights: [Int] = []

    // Reads the symbol at the state's *current* position, then transitions it — one atomic step,
    // matching `FSE_decodeSymbol` exactly (the lookup uses `numberOfBits`/`baseline` from the
    // state *before* this call updates it).
    func decodeAndAdvance(_ state: inout Int) -> Int {
      let symbol = Int(table.symbolOf[state])
      let bits = Int(table.numberOfBits[state])
      let low = Int(reader.readBits(bits))
      state = Int(table.baseline[state]) + low
      return symbol
    }

    // Mirrors `FSE_decompress_usingDTable_generic`'s tail loop exactly, including its container-
    // based overflow detection (`FSEContainerBitReader.reload`) — a simplified bit-position
    // heuristic was tried here first and produced the wrong symbol count on real multi-KB content
    // (matched one fixture's tail parity by chance, was short by 2 symbols on another); this port
    // replicates the reference decoder's actual termination condition instead of approximating it.
    while true {
      weights.append(decodeAndAdvance(&state1))
      if reader.reload() == .overflow {
        weights.append(decodeAndAdvance(&state2))
        break
      }
      weights.append(decodeAndAdvance(&state2))
      if reader.reload() == .overflow {
        weights.append(decodeAndAdvance(&state1))
        break
      }
    }
    return weights
  }

  /// The final symbol's weight is never transmitted; it's whatever value makes
  /// `sum(2^(weight-1))` complete to the next power of two (RFC 8878 §4.2.1.2) -- mirroring real
  /// zstd's `HUF_readStats` exactly: `tableLog = highbit32(total) + 1`, i.e. `fullTotal` is always
  /// the power of two *strictly greater* than the explicit weights' own total, even when that
  /// total already happens to be a power of two itself. A previous version found the smallest
  /// power of two `>=` total instead of `>`, so whenever the explicit weights summed to exactly a
  /// power of two, it wrongly concluded the implicit last symbol had weight 0 (unused) rather than
  /// the real, nonzero weight that actually completes the *next* power of two -- silently mis-
  /// assigning that symbol's Huffman code (and, since decode-table slot layout depends on every
  /// weight, corrupting the whole table) instead of throwing or decoding correctly. Real zstd's
  /// construction guarantees this remainder is never zero, so `lastValue > 0` always holds for a
  /// valid table; kept as a guard (rather than a precondition) since a malformed input could still
  /// reach here with `total` already representing bogus data — e.g., duplicate normalized counts
  /// with the wrong distinct-symbol vs. accuracy-log balance a fuzzer might construct.
  private static func appendingImplicitLastWeight(_ weights: [Int]) throws -> [Int] {
    var total = 0
    for weight in weights {
      guard weight >= 0, weight <= maximumHuffmanWeight else { throw ZstdError.invalidHuffmanTable }
      if weight > 0 { total += 1 << (weight - 1) }
    }
    guard total > 0 else { throw ZstdError.invalidHuffmanTable }
    let tableLog = Int.bitWidth - total.leadingZeroBitCount
    let fullTotal = 1 << tableLog
    let lastValue = fullTotal - total
    guard lastValue > 0, lastValue & (lastValue - 1) == 0 else { throw ZstdError.invalidHuffmanTable }
    let lastWeight = Int.bitWidth - lastValue.leadingZeroBitCount
    var all = weights
    all.append(lastWeight)
    return all
  }

  /// Canonical decode-table construction: LUT slot ranges for each weight are laid out by
  /// iterating weight *ascending* (1...maxBits) — confirmed empirically against real zstd output
  /// during development, since higher weight (shorter code) does not mean "earlier in the LUT."
  private static func buildDecodeTable(weights: [Int]) throws -> HuffmanDecodeTable {
    let total = weights.reduce(0) { $0 + ($1 > 0 ? (1 << ($1 - 1)) : 0) }
    guard total > 0, total & (total - 1) == 0 else { throw ZstdError.invalidHuffmanTable }
    let maxBits = Int.bitWidth - 1 - total.leadingZeroBitCount
    guard maxBits > 0, maxBits <= 16 else { throw ZstdError.invalidHuffmanTable }
    let tableSize = 1 << maxBits

    var rankCount = [Int](repeating: 0, count: maxBits + 2)
    for weight in weights {
      guard weight >= 0, weight <= maxBits + 1 else { throw ZstdError.invalidHuffmanTable }
      rankCount[weight] += 1
    }

    var rankStart = [Int](repeating: 0, count: maxBits + 2)
    var cursor = 0
    for weight in 1...maxBits {
      rankStart[weight] = cursor
      cursor += rankCount[weight] * (1 << (weight - 1))
    }
    guard cursor == tableSize else { throw ZstdError.invalidHuffmanTable }

    var symbolOf = [UInt8](repeating: 0, count: tableSize)
    var numberOfBits = [UInt8](repeating: 0, count: tableSize)
    for (symbol, weight) in weights.enumerated() where weight > 0 {
      guard symbol <= 255 else { throw ZstdError.invalidHuffmanTable }
      let nbBits = maxBits + 1 - weight
      let slotCount = 1 << (weight - 1)
      let start = rankStart[weight]
      guard start >= 0, start + slotCount <= tableSize else { throw ZstdError.invalidHuffmanTable }
      for offset in 0..<slotCount {
        symbolOf[start + offset] = UInt8(symbol)
        numberOfBits[start + offset] = UInt8(nbBits)
      }
      rankStart[weight] += slotCount
    }

    return HuffmanDecodeTable(maxBits: maxBits, symbolOf: symbolOf, numberOfBits: numberOfBits)
  }
}
