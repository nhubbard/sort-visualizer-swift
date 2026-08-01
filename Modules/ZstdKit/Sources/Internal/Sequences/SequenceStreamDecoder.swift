struct DecodedSequence {
  let literalLength: Int
  let matchLength: Int
  let offset: Int
}

/// Decodes `count` `(literal_length, offset, match_length)` triples from one interleaved FSE
/// bitstream. Read/update order below matches the reference decoder's `ZSTD_decodeSequence`
/// exactly (confirmed against source, not the RFC prose): per sequence, the three symbols come
/// from the *current* states (no bits consumed yet), then the offset is resolved — reading its
/// extra bits inline — before match-length's extra bits, before literal-length's extra bits, and
/// only then (skipped entirely for the last sequence) do the three states advance, in order
/// literal-length, match-length, offset.
enum SequenceStreamDecoder {
  static func decode(
    _ bytes: ArraySlice<UInt8>,
    count: Int,
    literalLengthTable: FSEDecodeTable,
    offsetTable: FSEDecodeTable,
    matchLengthTable: FSEDecodeTable,
    repeatOffsets: inout RepeatOffsets
  ) throws -> [DecodedSequence] {
    guard count > 0 else { return [] }

    var reader = try BackwardBitReader(Array(bytes))
    var literalLengthState = Int(reader.readBits(literalLengthTable.accuracyLog))
    var offsetState = Int(reader.readBits(offsetTable.accuracyLog))
    var matchLengthState = Int(reader.readBits(matchLengthTable.accuracyLog))

    let literalLengthBase = SequenceTables.literalLengthBase
    let literalLengthExtraBits = SequenceTables.literalLengthExtraBits
    let matchLengthBase = SequenceTables.matchLengthBase
    let matchLengthExtraBits = SequenceTables.matchLengthExtraBits
    let offsetBaseTable = SequenceTables.offsetBase
    let offsetExtraBitsTable = SequenceTables.offsetExtraBits

    var sequences: [DecodedSequence] = []
    sequences.reserveCapacity(count)

    for index in 0..<count {
      guard literalLengthState < literalLengthTable.symbolOf.count,
        offsetState < offsetTable.symbolOf.count,
        matchLengthState < matchLengthTable.symbolOf.count
      else {
        throw ZstdError.invalidSequenceStream
      }

      let llCode = Int(literalLengthTable.symbolOf[literalLengthState])
      let ofCode = Int(offsetTable.symbolOf[offsetState])
      let mlCode = Int(matchLengthTable.symbolOf[matchLengthState])
      guard llCode < literalLengthBase.count, ofCode < offsetBaseTable.count, mlCode < matchLengthBase.count
      else {
        throw ZstdError.invalidSequenceStream
      }

      let llBase = literalLengthBase[llCode]
      let literalLengthIsZero = llBase == 0

      let offset = try repeatOffsets.resolve(
        offsetBase: offsetBaseTable[ofCode],
        offsetExtraBits: offsetExtraBitsTable[ofCode],
        literalLengthIsZero: literalLengthIsZero,
        reader: &reader
      )

      let mlExtra = matchLengthExtraBits[mlCode]
      let matchLength = matchLengthBase[mlCode] + (mlExtra > 0 ? Int(reader.readBits(mlExtra)) : 0)

      let llExtra = literalLengthExtraBits[llCode]
      let literalLength = llBase + (llExtra > 0 ? Int(reader.readBits(llExtra)) : 0)

      sequences.append(DecodedSequence(literalLength: literalLength, matchLength: matchLength, offset: offset))

      if index < count - 1 {
        literalLengthState = advance(literalLengthTable, literalLengthState, &reader)
        matchLengthState = advance(matchLengthTable, matchLengthState, &reader)
        offsetState = advance(offsetTable, offsetState, &reader)
      }
    }

    return sequences
  }

  private static func advance(_ table: FSEDecodeTable, _ state: Int, _ reader: inout BackwardBitReader) -> Int {
    let bits = Int(table.numberOfBits[state])
    let low = bits > 0 ? Int(reader.readBits(bits)) : 0
    return Int(table.baseline[state]) + low
  }
}
