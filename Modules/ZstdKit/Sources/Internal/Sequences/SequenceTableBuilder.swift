/// The three sequence-symbol FSE tables currently in effect for a frame — persisted across blocks
/// so a `.repeat_` mode can reuse whichever table (predefined, RLE, or FSE-compressed) the most
/// recent block of that symbol type built. `nil` until the first block sets it; `.repeat_` on an
/// unset table is a real error (RFC 8878: invalid on a frame's first use).
struct SequenceTableSet {
  var literalLengths: FSEDecodeTable?
  var offsets: FSEDecodeTable?
  var matchLengths: FSEDecodeTable?

  func table(for kind: SequenceSymbolKind) -> FSEDecodeTable? {
    switch kind {
    case .literalLength: return literalLengths
    case .offset: return offsets
    case .matchLength: return matchLengths
    }
  }

  mutating func setTable(_ table: FSEDecodeTable, for kind: SequenceSymbolKind) {
    switch kind {
    case .literalLength: literalLengths = table
    case .offset: offsets = table
    case .matchLength: matchLengths = table
    }
  }
}

enum SequenceTableBuilder {
  /// Builds (or reuses) the decode table for one symbol type, advancing `reader` past whatever
  /// bytes this mode consumes (zero for `.predefined`/`.repeat_`, one for `.rle`, a variable
  /// FSE table description for `.fseCompressed`).
  static func buildTable(
    mode: SequenceSymbolCompressionMode,
    kind: SequenceSymbolKind,
    reader: inout ByteReader,
    previousTables: SequenceTableSet
  ) throws -> FSEDecodeTable {
    switch mode {
    case .predefined:
      return try FSETableBuilder.buildDecodeTable(
        counts: kind.defaultNormalizedCounts, accuracyLog: kind.defaultAccuracyLog
      )

    case .rle:
      let symbol = try reader.readByte()
      guard Int(symbol) <= kind.maxSymbol else { throw ZstdError.invalidSequenceStream }
      // A trivial one-state table: always decodes to `symbol`, consumes 0 bits, never changes
      // state — mirrors the reference decoder's `tableLog=0, nbBits=0, nextState=0` RLE table.
      return FSEDecodeTable(accuracyLog: 0, symbolOf: [symbol], numberOfBits: [0], baseline: [0])

    case .repeat_:
      guard let previous = previousTables.table(for: kind) else { throw ZstdError.invalidSequenceStream }
      return previous

    case .fseCompressed:
      var forwardReader = ForwardBitReader(Array(reader.remainingBytes()))
      let (accuracyLog, counts) = try FSETableBuilder.readNormalizedCounts(
        &forwardReader, maxSymbol: kind.maxSymbol, maximumAccuracyLog: kind.maximumAccuracyLog
      )
      let table = try FSETableBuilder.buildDecodeTable(counts: counts, accuracyLog: accuracyLog)
      try reader.skip(forwardReader.consumedBytes)
      return table
    }
  }
}
