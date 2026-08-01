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
/// Weight-distribution FSE tables use a generously-capped accuracy log; the reference encoder
/// stays well under this in every fixture this decoder has been tested against.
private let maximumWeightAccuracyLog = 12

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
    var reader = try BackwardBitReader(Array(weightSection[bitstreamStart...]))

    var state1 = Int(reader.readBits(accuracyLog))
    var state2 = Int(reader.readBits(accuracyLog))
    var weights: [Int] = []

    func advance(_ state: inout Int) {
      let bits = Int(table.numberOfBits[state])
      let low = bits > 0 ? Int(reader.readBits(bits)) : 0
      state = Int(table.baseline[state]) + low
    }

    // Mirrors the reference decoder's tail loop (`FSE_decompress_usingDTable_generic`) exactly:
    // each state's symbol is read from its *current* position, then (unless this is the final
    // symbol of the whole stream) the state transitions before the next read. The bug this
    // replaced: giving `state1` a second, spurious transition right before reading the very last
    // symbol of an odd-length stream — invisible on every fixture whose weight stream happened to
    // end at that boundary evenly, until a real multi-KB corpus (restricted-alphabet content, so
    // the implicit last symbol landed exactly on this parity) exposed it. Confirmed bit-exact
    // against a faithful port of `BIT_reloadDStream`'s container semantics, not guessed.
    while true {
      weights.append(Int(table.symbolOf[state1]))
      if !reader.hasBitsRemaining {
        weights.append(Int(table.symbolOf[state2]))
        break
      }
      advance(&state1)
      weights.append(Int(table.symbolOf[state2]))
      if !reader.hasBitsRemaining {
        weights.append(Int(table.symbolOf[state1]))
        break
      }
      advance(&state2)
    }
    return weights
  }

  /// The final symbol's weight is never transmitted; it's whatever value makes
  /// `sum(2^(weight-1))` complete to the next power of two (RFC 8878 §4.2.1.2).
  private static func appendingImplicitLastWeight(_ weights: [Int]) throws -> [Int] {
    var total = 0
    for weight in weights {
      guard weight >= 0, weight <= maximumHuffmanWeight else { throw ZstdError.invalidHuffmanTable }
      if weight > 0 { total += 1 << (weight - 1) }
    }
    guard total > 0 else { throw ZstdError.invalidHuffmanTable }
    var nextPowerOfTwo = 1
    while nextPowerOfTwo < total { nextPowerOfTwo <<= 1 }
    let lastValue = nextPowerOfTwo - total
    // lastValue == 0 is legitimate: the explicit weights already sum exactly to a power of two,
    // so the implicit last symbol simply has weight 0 (unused) — confirmed against a real
    // fixture where this occurs (see SequenceTests's large multi-block corpus).
    guard lastValue >= 0, lastValue & (lastValue - 1) == 0 else { throw ZstdError.invalidHuffmanTable }
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
