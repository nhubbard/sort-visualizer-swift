// This file's normalized-count allocation, encode-table construction (mirroring
// `FSE_buildCTable_wksp`'s "spread by step, assign symbolTT" algorithm), NCount serialization
// (the write-side mirror of `FSETable.swift`'s `readNormalizedCounts`), and the per-symbol
// state-machine encode step (`FSE_encodeSymbol`) are transcribed from the real `zstd` C source
// (`lib/compress/fse_compress.c`, `lib/common/fse.h`). See NOTICE.md.
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

struct FSESymbolTransform {
  let deltaNbBits: Int
  let deltaFindState: Int
}

/// The encode-direction counterpart to `FSEDecodeTable` — structurally different (a per-symbol
/// state-transition table, not a per-state symbol lookup), per `FSE_buildCTable`'s own design.
struct FSEEncodeTableData {
  let accuracyLog: Int
  /// Size `tableSize`; values in `[tableSize, 2*tableSize)` — `FSE_initCState`'s "add tableSize"
  /// convention, which is what makes `deltaNbBits`'s packed-into-one-comparison trick work without
  /// a separate first-call special case.
  let stateTable: [Int]
  let symbolTransforms: [FSESymbolTransform]

  var initialState: Int { 1 << accuracyLog }
}

/// Drives one FSE state machine across a run of symbols, handling the emission-order subtlety
/// `FSEEncodeTable.step` itself deliberately stays silent about.
///
/// FSE's state transitions must be *computed* by walking symbols in reverse (last original symbol
/// first — a LIFO relationship the reference's own docs describe), but the resulting bits must be
/// *committed to the bitstream* in yet another order: the flush value (the state after the very
/// *last* computed step, i.e. after processing original symbol 0) has to be the first thing a
/// decoder reads, since decode extracts the first original symbol directly from that initial state
/// with no advance. Concretely, verified against this module's own decoder (`FSETableBuilder`) via
/// `FSEEncodeTableTests`: walk symbols in reverse calling `encodeNext`, buffering each step's bits;
/// then commit `flushValue` first, followed by `advancesInOriginalOrder` — the buffered steps
/// reversed back into original-symbol order, *dropping* the very first computed step. That dropped
/// step is `FSE_initCState2`'s optimization target (the transition from an arbitrary neutral
/// starting state into the last original symbol's state) — a real decoder never performs that many
/// advances (exactly `symbolCount - 1` advances follow the one initial flush-read, one per adjacent
/// pair of decoded symbols), so those bits would just be silently-unread trailing data. Safe to
/// keep, but no reason to pay for them.
struct FSEEncodeSession {
  private(set) var state: Int
  private var pending: [(bits: UInt32, count: Int)] = []
  let table: FSEEncodeTableData

  init(table: FSEEncodeTableData) {
    self.table = table
    self.state = table.initialState
  }

  mutating func encodeNext(_ symbol: Int) {
    let (nextState, bits, count) = FSEEncodeTable.step(symbol, state: state, table: table)
    pending.append((bits, count))
    state = nextState
  }

  var flushValue: (bits: UInt32, count: Int) {
    (UInt32(state & ((1 << table.accuracyLog) - 1)), table.accuracyLog)
  }

  var advancesInOriginalOrder: [(bits: UInt32, count: Int)] {
    Array(pending.reversed().dropLast())
  }
}

enum FSEEncodeTable {
  /// Encodes a full, self-contained symbol sequence as its own FSE-coded bitstream (the isolated
  /// case — e.g. Huffman weights — where nothing else shares the buffer). Sequence encoding, where
  /// three FSE streams interleave with raw extra-bits fields, drives `FSEEncodeSession` directly
  /// instead (see `SequenceStreamEncoder`).
  static func encodeSymbols(_ symbols: [Int], table: FSEEncodeTableData) -> [UInt8] {
    var session = FSEEncodeSession(table: table)
    for symbol in symbols.reversed() {
      session.encodeNext(symbol)
    }
    var writer = BackwardBitWriter()
    writer.writeBits(session.flushValue.bits, count: session.flushValue.count)
    for pair in session.advancesInOriginalOrder {
      writer.writeBits(pair.bits, count: pair.count)
    }
    return writer.finish()
  }

  /// Turns a raw frequency histogram into normalized counts summing to `1 << accuracyLog`
  /// (`FSE_normalizeCount`'s job, simplified: proportional allocation, floored, each present
  /// symbol guaranteed at least 1 slot, any rounding leftover dumped onto the most frequent
  /// symbol). Deliberately never emits the `-1` "low probability" sentinel — a plain count of `1`
  /// produces an identical, valid decode table (per `FSETableBuilder.buildDecodeTable`, `-1` and
  /// `1` are handled identically except for *where* in the table they're placed), so this skips a
  /// whole class of bookkeeping the reference's real encoder carries for a compression-ratio
  /// nicety this doesn't need. Safe by construction whenever `distinctSymbolCount <= 1 <<
  /// accuracyLog` (guaranteed by `chooseAccuracyLog`'s caller): see the derivation in this
  /// session's notes — the "leftover dumped on the largest symbol" adjustment can be shown to
  /// always leave that symbol with a count `>= 1` under that precondition.
  static func normalize(counts: [Int], accuracyLog: Int) -> [Int] {
    let tableSize = 1 << accuracyLog
    let total = counts.reduce(0, +)
    var normalized = [Int](repeating: 0, count: counts.count)
    guard total > 0 else { return normalized }

    var remaining = tableSize
    var largestIndex = -1
    var largestCount = -1
    for (index, count) in counts.enumerated() where count > 0 {
      let proba = max(1, Int((Double(count) * Double(tableSize)) / Double(total)))
      normalized[index] = proba
      remaining -= proba
      if count > largestCount {
        largestCount = count
        largestIndex = index
      }
    }
    if largestIndex >= 0 {
      normalized[largestIndex] += remaining
      if normalized[largestIndex] < 1 { normalized[largestIndex] = 1 }
    }
    return normalized
  }

  /// Smallest accuracy log that can give every distinct symbol at least one table slot, never
  /// exceeding `maximumAccuracyLog`.
  static func chooseAccuracyLog(distinctSymbolCount: Int, minimumAccuracyLog: Int, maximumAccuracyLog: Int)
    -> Int {
    var log = minimumAccuracyLog
    while (1 << log) < distinctSymbolCount, log < maximumAccuracyLog {
      log += 1
    }
    return log
  }

  /// Mirrors `FSE_buildCTable_wksp`: spread symbols across the table exactly as
  /// `FSETableBuilder.buildDecodeTable` does (same `step`, same high-threshold placement for `-1`
  /// counts), then build the per-state "next state" table and per-symbol transform constants.
  static func build(counts: [Int], accuracyLog: Int) -> FSEEncodeTableData {
    let tableSize = 1 << accuracyLog
    var tableSymbol = [Int](repeating: 0, count: tableSize)
    var highThreshold = tableSize - 1
    var cumul = [Int](repeating: 0, count: counts.count + 1)

    for symbol in 0..<counts.count {
      let count = counts[symbol]
      if count == -1 {
        cumul[symbol + 1] = cumul[symbol] + 1
        tableSymbol[highThreshold] = symbol
        highThreshold -= 1
      } else {
        cumul[symbol + 1] = cumul[symbol] + count
      }
    }

    let step = (tableSize >> 1) + (tableSize >> 3) + 3
    let mask = tableSize - 1
    var position = 0
    for (symbol, count) in counts.enumerated() where count > 0 {
      for _ in 0..<count {
        tableSymbol[position] = symbol
        position = (position + step) & mask
        while position > highThreshold {
          position = (position + step) & mask
        }
      }
    }

    var stateTable = [Int](repeating: 0, count: tableSize)
    var cursor = cumul
    for u in 0..<tableSize {
      let symbol = tableSymbol[u]
      stateTable[cursor[symbol]] = tableSize + u
      cursor[symbol] += 1
    }

    var transforms = [FSESymbolTransform](
      repeating: FSESymbolTransform(deltaNbBits: 0, deltaFindState: 0), count: counts.count)
    for symbol in 0..<counts.count {
      switch counts[symbol] {
      case 0:
        transforms[symbol] = FSESymbolTransform(
          deltaNbBits: ((accuracyLog + 1) << 16) - tableSize, deltaFindState: 0)
      case -1, 1:
        transforms[symbol] = FSESymbolTransform(
          deltaNbBits: (accuracyLog << 16) - tableSize, deltaFindState: cumul[symbol] - 1)
      default:
        let count = counts[symbol]
        let maxBitsOut = accuracyLog - floorLog2(count - 1)
        let minStatePlus = count << maxBitsOut
        transforms[symbol] = FSESymbolTransform(
          deltaNbBits: (maxBitsOut << 16) - minStatePlus, deltaFindState: cumul[symbol] - count)
      }
    }

    return FSEEncodeTableData(accuracyLog: accuracyLog, stateTable: stateTable, symbolTransforms: transforms)
  }

  /// One state-machine step (`FSE_encodeSymbol`): computes the bits this transition requires and
  /// the new state, *without* writing anything yet — see `FSEEncodeSession`'s doc comment for why
  /// emission has to be deferred and reordered, not written immediately. Always uses the general
  /// `FSE_initCState` (state starts at `tableSize`) rather than the `FSE_initCState2` first-symbol
  /// optimization — a few extra (unread, harmless — see `FSEEncodeSession.finish`) bits in exchange
  /// for one less special case; a correctness-neutral simplification.
  static func step(_ symbol: Int, state: Int, table: FSEEncodeTableData) -> (nextState: Int, bits: UInt32, count: Int) {
    let transform = table.symbolTransforms[symbol]
    let nbBitsOut = (state + transform.deltaNbBits) >> 16
    let mask = nbBitsOut > 0 ? (1 << nbBitsOut) - 1 : 0
    let nextState = table.stateTable[(state >> nbBitsOut) + transform.deltaFindState]
    return (nextState, UInt32(state & mask), nbBitsOut)
  }

  /// The write-side mirror of `FSETableBuilder.readNormalizedCounts` — same adaptive-width scheme
  /// and zero-run-length coding, in reverse. Deliberately returns exactly the tight bit count
  /// (rounded up to a byte), no extra padding byte: both real call sites
  /// (`SequenceTableBuilder.buildTable`'s `.fseCompressed` case and
  /// `HuffmanTableBuilder.decodeFSECompressedWeights`) determine how many bytes to skip past this
  /// description from `ForwardBitReader.consumedBytes` — i.e. from bits *actually read* — not from
  /// a declared length this function would control. An extra trailing byte here would be silently
  /// unaccounted for by that skip, misaligning whatever comes next in the buffer (confirmed the
  /// hard way: this cost a real debugging session, described in `COMPRESSION_DESIGN.md`). The read
  /// side's own "guess wide, rewind 1 bit if narrow" trick can speculatively peek 1 bit past this
  /// description's own last real bit, but that's always safe *without* padding: both call sites
  /// hand `readNormalizedCounts` a buffer that extends well past this description's own bytes
  /// (either the rest of the block, for sequences, or the full declared weight section, which
  /// itself is followed by the Huffman-coded stream within the same literals section) — the peek
  /// harmlessly reads into real, already-present bytes and is immediately rewound.
  static func writeNCount(counts: [Int], accuracyLog: Int, maxSymbol: Int) -> [UInt8] {
    var writer = ForwardBitWriter()
    writer.writeBits(UInt32(accuracyLog - FSETableBuilder.minimumAccuracyLog), count: 4)

    var remaining = (1 << accuracyLog) + 1
    var threshold = 1 << accuracyLog
    var bitsToRead = accuracyLog + 1
    var symbol = 0

    while remaining > 1, symbol <= maxSymbol {
      let count = counts[symbol]
      let value = count + 1
      let maxValue = (2 * threshold - 1) - remaining

      if value < maxValue {
        writer.writeBits(UInt32(value), count: bitsToRead - 1)
      } else {
        let wide = value < threshold ? value : value + maxValue
        writer.writeBits(UInt32(wide), count: bitsToRead)
      }

      remaining -= abs(count)
      symbol += 1
      while remaining < threshold {
        bitsToRead -= 1
        threshold >>= 1
      }

      if count == 0 {
        var zeroRun = 0
        while symbol <= maxSymbol, counts[symbol] == 0 {
          zeroRun += 1
          symbol += 1
        }
        var remainingRun = zeroRun
        while remainingRun >= 3 {
          writer.writeBits(3, count: 2)
          remainingRun -= 3
        }
        writer.writeBits(UInt32(remainingRun), count: 2)
      }
    }

    return writer.bytes
  }

  private static func floorLog2(_ value: Int) -> Int {
    Int.bitWidth - 1 - value.leadingZeroBitCount
  }
}
