import Testing

@testable import ZstdKit

@Suite
struct FSEEncodeTableTests {
  @Test
  func writeNCountRoundTripsThroughExistingReader() throws {
    let counts = [5, 0, 0, 3, 2]  // symbol 1,2 are a zero-run in the middle
    let accuracyLog = 5
    let normalized = FSEEncodeTable.normalize(counts: counts, accuracyLog: accuracyLog)
    #expect(normalized.reduce(0) { $0 + ($1 == -1 ? 1 : $1) } == 1 << accuracyLog)

    let bytes = FSEEncodeTable.writeNCount(counts: normalized, accuracyLog: accuracyLog, maxSymbol: 4)
    var reader = ForwardBitReader(bytes)
    let (readAccuracyLog, readCounts) = try FSETableBuilder.readNormalizedCounts(
      &reader, maxSymbol: 4, maximumAccuracyLog: 9)
    #expect(readAccuracyLog == accuracyLog)
    #expect(readCounts == normalized)
  }

  @Test
  func writeNCountRoundTripsWithManySymbolsAndVariedZeroRuns() throws {
    // 20 symbols: a mix of present and absent (including a long zero run and a trailing zero run)
    // to exercise the 2-bit-chunked run-length coding across multiple chunks (run length > 3).
    var counts = [Int](repeating: 0, count: 20)
    counts[0] = 40
    counts[5] = 20
    counts[6] = 10
    counts[19] = 5
    // Zero runs: 1...4 (4 zeros), 7...18 (12 zeros, forcing multiple "3" chunks plus a remainder).
    let accuracyLog = 6
    let normalized = FSEEncodeTable.normalize(counts: counts, accuracyLog: accuracyLog)

    let bytes = FSEEncodeTable.writeNCount(counts: normalized, accuracyLog: accuracyLog, maxSymbol: 19)
    var reader = ForwardBitReader(bytes)
    let (readAccuracyLog, readCounts) = try FSETableBuilder.readNormalizedCounts(
      &reader, maxSymbol: 19, maximumAccuracyLog: 9)
    #expect(readAccuracyLog == accuracyLog)
    #expect(readCounts == normalized)
  }

  /// Decodes an `FSEEncodeTable.encodeSymbols` bitstream using the existing, already-verified
  /// `FSETableBuilder.buildDecodeTable` plus the exact state-advance mechanics
  /// `SequenceStreamDecoder.advance` uses — the load-bearing correctness gate for the entire
  /// FSE-encode direction, independent of anything sequence- or literals-specific.
  private func decode(_ bytes: [UInt8], accuracyLog: Int, count: Int, decodeTable: FSEDecodeTable) throws -> [Int] {
    var reader = try BackwardBitReader(bytes)
    var decodeState = Int(reader.readBits(accuracyLog))
    var decoded: [Int] = []
    for index in 0..<count {
      decoded.append(Int(decodeTable.symbolOf[decodeState]))
      if index < count - 1 {
        let bits = Int(decodeTable.numberOfBits[decodeState])
        let low = bits > 0 ? Int(reader.readBits(bits)) : 0
        decodeState = Int(decodeTable.baseline[decodeState]) + low
      }
    }
    return decoded
  }

  /// Isolates the simplest possible case (every symbol occurring exactly once, so every
  /// transform hits the `count == 1` branch, never the general `count > 1` branch) before testing
  /// the general case — narrows down which branch a failure would be in.
  @Test
  func encodedSymbolsDecodeBackInOriginalOrderAllCountsOne() throws {
    let accuracyLog = 2  // tableSize 4, exactly matching 4 distinct symbols each count 1
    let counts = [1, 1, 1, 1]
    let encodeTable = FSEEncodeTable.build(counts: counts, accuracyLog: accuracyLog)
    let decodeTable = try FSETableBuilder.buildDecodeTable(counts: counts, accuracyLog: accuracyLog)

    let symbols = [0, 1, 2, 3, 0, 1, 2, 3]
    let bytes = FSEEncodeTable.encodeSymbols(symbols, table: encodeTable)
    let decoded = try decode(bytes, accuracyLog: accuracyLog, count: symbols.count, decodeTable: decodeTable)
    #expect(decoded == symbols)
  }

  @Test
  func encodedSymbolsDecodeBackInOriginalOrder() throws {
    let counts = [5, 3, 2]  // symbols 0, 1, 2
    let accuracyLog = 5
    let normalized = FSEEncodeTable.normalize(counts: counts, accuracyLog: accuracyLog)
    let encodeTable = FSEEncodeTable.build(counts: normalized, accuracyLog: accuracyLog)
    let decodeTable = try FSETableBuilder.buildDecodeTable(counts: normalized, accuracyLog: accuracyLog)

    let symbols = [0, 1, 2, 0, 0, 1, 2, 1, 0, 2, 2, 1, 0, 0, 0]
    let bytes = FSEEncodeTable.encodeSymbols(symbols, table: encodeTable)
    let decoded = try decode(bytes, accuracyLog: accuracyLog, count: symbols.count, decodeTable: decodeTable)
    #expect(decoded == symbols)
  }

  /// Same check, but with a much larger/skewed symbol population and a larger accuracy log, to
  /// exercise more of the state-transition table than the tiny 3-symbol case above.
  @Test
  func encodedSymbolsDecodeBackInOriginalOrderWithLargerAlphabet() throws {
    var counts = [Int](repeating: 0, count: 10)
    for symbol in 0..<10 { counts[symbol] = symbol == 0 ? 100 : 10 }
    let accuracyLog = 7
    let normalized = FSEEncodeTable.normalize(counts: counts, accuracyLog: accuracyLog)
    let encodeTable = FSEEncodeTable.build(counts: normalized, accuracyLog: accuracyLog)
    let decodeTable = try FSETableBuilder.buildDecodeTable(counts: normalized, accuracyLog: accuracyLog)

    var symbols: [Int] = []
    for i in 0..<200 { symbols.append(i % 10) }
    let bytes = FSEEncodeTable.encodeSymbols(symbols, table: encodeTable)
    let decoded = try decode(bytes, accuracyLog: accuracyLog, count: symbols.count, decodeTable: decodeTable)
    #expect(decoded == symbols)
  }

  /// A single-occupant table (every symbol count 0 except one, which necessarily gets the whole
  /// table) — an edge case worth its own check since `deltaFindState`/`deltaNbBits`'s "case 1"
  /// branch degenerates in a specific way when `count == tableSize`.
  @Test
  func encodedSymbolsWithASingleDominantSymbolDecodeCorrectly() throws {
    let counts = [1, 31]  // symbol 1 takes the whole table minus symbol 0's single slot
    let accuracyLog = 5
    let encodeTable = FSEEncodeTable.build(counts: counts, accuracyLog: accuracyLog)
    let decodeTable = try FSETableBuilder.buildDecodeTable(counts: counts, accuracyLog: accuracyLog)

    let symbols = [1, 1, 1, 0, 1, 1, 0, 1, 1, 1, 1, 0]
    let bytes = FSEEncodeTable.encodeSymbols(symbols, table: encodeTable)
    let decoded = try decode(bytes, accuracyLog: accuracyLog, count: symbols.count, decodeTable: decodeTable)
    #expect(decoded == symbols)
  }
}
