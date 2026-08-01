/// The 3 most-recently-used match offsets (RFC 8878 §3.1.1.3.2.1.2), reset to `{1, 4, 8}` once per
/// frame and threaded through every sequence in every block of that frame — never reset per block.
///
/// This resolves an Offset_Code exactly as the reference decoder's `ZSTD_decodeSequence` does
/// (confirmed against `lib/decompress/zstd_decompress_block.c`, not derived from the RFC prose
/// alone — the RFC's repeat-offset description and the actual bit-level mechanics the reference
/// decoder implements don't line up cleanly enough to transcribe by hand with confidence). The
/// key fact the RFC prose undersells: which case applies is decided by the Offset_Code's *extra
/// bit count* (0, 1, or >1), not by comparing the decoded offset value against 1/2/3.
struct RepeatOffsets {
  var offset1 = 1
  var offset2 = 4
  var offset3 = 8

  /// `offsetBase`/`offsetExtraBits` are `SequenceTables.offsetBase[code]`/`offsetExtraBits[code]`
  /// for the decoded Offset_Code. `literalLengthIsZero` must reflect the *Literal_Length_Code's
  /// baseValue* being zero (equivalently, the final literal length being zero — they coincide
  /// because code 0 is the only Literal_Length_Code with both a zero baseline and zero extra
  /// bits), checked *before* any of this sequence's literal-length extra bits are read.
  mutating func resolve(
    offsetBase: Int, offsetExtraBits: Int, literalLengthIsZero: Bool, reader: inout BackwardBitReader
  ) throws -> Int {
    let offset: Int
    if offsetExtraBits > 1 {
      offset = offsetBase + Int(reader.readBits(offsetExtraBits))
      offset3 = offset2
      offset2 = offset1
      offset1 = offset
    } else if offsetExtraBits == 0 {
      offset = literalLengthIsZero ? offset2 : offset1
      if literalLengthIsZero {
        offset2 = offset1
      }
      offset1 = offset
    } else {
      // offsetExtraBits == 1
      let extraBit = Int(reader.readBits(1))
      let rawValue = offsetBase + (literalLengthIsZero ? 1 : 0) + extraBit  // offsetBase == 1 here
      let resolved: Int
      switch rawValue {
      case 1: resolved = offset2
      case 2: resolved = offset3
      default: resolved = offset1 - 1  // rawValue == 3
      }
      guard resolved > 0 else { throw ZstdError.invalidMatchOffset }
      if rawValue != 1 {
        offset3 = offset2
      }
      offset2 = offset1
      offset1 = resolved
      offset = resolved
    }
    return offset
  }
}
