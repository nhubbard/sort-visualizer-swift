/// A built FSE decoding table (RFC 8878 §4.1): for each of `1 << accuracyLog` states, the symbol
/// it decodes to, how many bits to read for the next state, and that state's baseline. Shared
/// verbatim between Huffman weight decoding (Milestone B) and LL/OF/ML sequence decoding
/// (Milestone C) — same algorithm, different alphabets.
struct FSEDecodeTable {
  let accuracyLog: Int
  let symbolOf: [UInt8]
  let numberOfBits: [UInt8]
  let baseline: [UInt16]
}

enum FSETableBuilder {
  static let minimumAccuracyLog = 5

  /// Parses the normalized-count table description (RFC 8878 §4.1.1) from a forward, LSB-first
  /// bit reader. Returns the declared accuracy log and one count per symbol from 0...maxSymbol
  /// (a count of `-1` means "less than 1", RFC's low-probability special case).
  static func readNormalizedCounts(
    _ reader: inout ForwardBitReader, maxSymbol: Int, maximumAccuracyLog: Int
  ) throws -> (accuracyLog: Int, counts: [Int]) {
    let accuracyLog = Int(try reader.readBits(4)) + minimumAccuracyLog
    guard accuracyLog >= minimumAccuracyLog, accuracyLog <= maximumAccuracyLog else {
      throw ZstdError.invalidFSETable
    }

    var remaining = (1 << accuracyLog) + 1
    var threshold = 1 << accuracyLog
    var bitsToRead = accuracyLog + 1
    var counts: [Int] = []
    var symbol = 0

    while remaining > 1, symbol <= maxSymbol {
      let maxValue = (2 * threshold - 1) - remaining
      let raw = Int(try reader.readBits(bitsToRead))
      let low = raw & (threshold - 1)
      let value: Int
      if low < maxValue {
        value = low
        reader.rewind(bits: 1)
      } else {
        let wide = raw & (2 * threshold - 1)
        value = wide >= threshold ? wide - maxValue : wide
      }
      let count = value - 1
      counts.append(count)
      symbol += 1
      remaining -= abs(count)
      guard remaining >= 0 else { throw ZstdError.invalidFSETable }
      while remaining < threshold {
        bitsToRead -= 1
        threshold >>= 1
      }

      if count == 0 {
        var zeroRun = 0
        while true {
          let two = Int(try reader.readBits(2))
          if two == 3 {
            zeroRun += 3
            continue
          }
          zeroRun += two
          break
        }
        for _ in 0..<zeroRun {
          guard symbol <= maxSymbol else { throw ZstdError.invalidFSETable }
          counts.append(0)
          symbol += 1
        }
      }
    }
    while symbol <= maxSymbol {
      counts.append(0)
      symbol += 1
    }
    return (accuracyLog, counts)
  }

  /// Builds the decode table from normalized counts via the standard tANS "spread by step, then
  /// assign nbBits/baseline per state" construction (RFC 8878 §4.1.1).
  static func buildDecodeTable(counts: [Int], accuracyLog: Int) throws -> FSEDecodeTable {
    let tableSize = 1 << accuracyLog
    guard tableSize > 0, tableSize <= (1 << 16) else { throw ZstdError.invalidFSETable }

    var symbolOf = [UInt8](repeating: 0, count: tableSize)
    var highThreshold = tableSize - 1
    var symbolNext = counts

    for (symbol, count) in counts.enumerated() where count == -1 {
      guard highThreshold >= 0, symbol <= 255 else { throw ZstdError.invalidFSETable }
      symbolOf[highThreshold] = UInt8(symbol)
      highThreshold -= 1
      symbolNext[symbol] = 1
    }

    let step = (tableSize >> 1) + (tableSize >> 3) + 3
    let mask = tableSize - 1
    var position = 0
    for (symbol, count) in counts.enumerated() where count > 0 {
      guard symbol <= 255 else { throw ZstdError.invalidFSETable }
      for _ in 0..<count {
        guard position >= 0, position < tableSize else { throw ZstdError.invalidFSETable }
        symbolOf[position] = UInt8(symbol)
        position = (position + step) & mask
        while position > highThreshold {
          position = (position + step) & mask
        }
      }
    }
    guard position == 0 else { throw ZstdError.invalidFSETable }

    var numberOfBits = [UInt8](repeating: 0, count: tableSize)
    var baseline = [UInt16](repeating: 0, count: tableSize)
    var nextState = symbolNext
    for state in 0..<tableSize {
      let symbol = Int(symbolOf[state])
      let n = nextState[symbol]
      guard n > 0 else { throw ZstdError.invalidFSETable }
      nextState[symbol] += 1
      let bits = accuracyLog - floorLog2(n)
      guard bits >= 0, bits <= 32 else { throw ZstdError.invalidFSETable }
      numberOfBits[state] = UInt8(bits)
      let newStateBase = (n << bits) - tableSize
      guard let value = UInt16(exactly: newStateBase) else { throw ZstdError.invalidFSETable }
      baseline[state] = value
    }
    return FSEDecodeTable(accuracyLog: accuracyLog, symbolOf: symbolOf, numberOfBits: numberOfBits, baseline: baseline)
  }

  private static func floorLog2(_ value: Int) -> Int {
    Int.bitWidth - 1 - value.leadingZeroBitCount
  }
}
