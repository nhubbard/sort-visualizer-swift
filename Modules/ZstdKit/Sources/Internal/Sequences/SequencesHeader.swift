/// One symbol type's Symbol_Compression_Mode (RFC 8878 §3.1.1.3.2.2). Numeric values match the
/// real decoder's `SymbolEncodingType_e` (`set_basic`/`set_rle`/`set_compressed`/`set_repeat`).
enum SequenceSymbolCompressionMode: UInt8 {
  case predefined = 0
  case rle = 1
  case fseCompressed = 2
  case repeat_ = 3
}

struct SequencesHeader {
  let numberOfSequences: Int
  let literalLengthsMode: SequenceSymbolCompressionMode
  let offsetsMode: SequenceSymbolCompressionMode
  let matchLengthsMode: SequenceSymbolCompressionMode
}

/// `LONGNBSEQ` — the offset added to the 2-byte extended sequence count.
private let longSequenceCountOffset = 0x7F00

enum SequencesHeaderParser {
  static func parse(_ reader: inout ByteReader) throws -> SequencesHeader {
    let first = try reader.readByte()

    if first == 0 {
      // Section ends immediately — no Symbol_Compression_Modes byte follows. The modes below are
      // placeholders the caller must never act on (there's nothing to build a table for).
      return SequencesHeader(
        numberOfSequences: 0, literalLengthsMode: .predefined, offsetsMode: .predefined,
        matchLengthsMode: .predefined
      )
    }

    let numberOfSequences: Int
    if first < 128 {
      numberOfSequences = Int(first)
    } else if first == 255 {
      numberOfSequences = Int(try reader.readLittleEndianUInt(byteCount: 2)) + longSequenceCountOffset
    } else {
      let extra = try reader.readByte()
      numberOfSequences = ((Int(first) - 0x80) << 8) + Int(extra)
    }

    let modesByte = try reader.readByte()
    guard modesByte & 0x3 == 0 else { throw ZstdError.invalidSequenceStream }
    guard let literalLengthsMode = SequenceSymbolCompressionMode(rawValue: (modesByte >> 6) & 0x3),
      let offsetsMode = SequenceSymbolCompressionMode(rawValue: (modesByte >> 4) & 0x3),
      let matchLengthsMode = SequenceSymbolCompressionMode(rawValue: (modesByte >> 2) & 0x3)
    else {
      throw ZstdError.invalidSequenceStream
    }

    return SequencesHeader(
      numberOfSequences: numberOfSequences,
      literalLengthsMode: literalLengthsMode,
      offsetsMode: offsetsMode,
      matchLengthsMode: matchLengthsMode
    )
  }
}
