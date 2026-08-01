/// Baseline/extra-bits tables and predefined default distributions for the three sequence symbol
/// types (RFC 8878 §3.1.1.3.2.1.1). Values transcribed programmatically from the real
/// `lib/common/zstd_internal.h` and `lib/decompress/zstd_decompress_internal.h` (`LL_base`,
/// `LL_bits`, `LL_defaultNorm`, and the `ML_`/`OF_` equivalents) rather than retyped by hand, to
/// eliminate transcription risk in tables this size — each occupancy sum was independently
/// verified to equal its table's declared size (64, 64, and 32 respectively) before use.
enum SequenceSymbolKind {
  case literalLength
  case offset
  case matchLength

  /// Largest symbol value `FSE_readNCount` may declare a nonzero/`-1` count for for this type —
  /// `MaxLL`/`MaxOff`/`MaxML` in the reference source. Note this is the ceiling for
  /// `FSE_Compressed` mode, larger than the predefined table's own symbol range for offsets.
  var maxSymbol: Int {
    switch self {
    case .literalLength: return 35
    case .offset: return 31
    case .matchLength: return 52
    }
  }

  /// `LLFSELog`/`OffFSELog`/`MLFSELog` — the accuracy-log ceiling a `FSE_Compressed` table for
  /// this type must not exceed.
  var maximumAccuracyLog: Int {
    switch self {
    case .literalLength: return 9
    case .offset: return 8
    case .matchLength: return 9
    }
  }

  var baseValues: [Int] {
    switch self {
    case .literalLength: return SequenceTables.literalLengthBase
    case .offset: return SequenceTables.offsetBase
    case .matchLength: return SequenceTables.matchLengthBase
    }
  }

  var extraBits: [Int] {
    switch self {
    case .literalLength: return SequenceTables.literalLengthExtraBits
    case .offset: return SequenceTables.offsetExtraBits
    case .matchLength: return SequenceTables.matchLengthExtraBits
    }
  }

  var defaultNormalizedCounts: [Int] {
    switch self {
    case .literalLength: return SequenceTables.literalLengthDefaultNorm
    case .offset: return SequenceTables.offsetDefaultNorm
    case .matchLength: return SequenceTables.matchLengthDefaultNorm
    }
  }

  var defaultAccuracyLog: Int {
    switch self {
    case .literalLength, .matchLength: return 6
    case .offset: return 5
    }
  }
}

enum SequenceTables {
  // MARK: Literal_Length_Code baseline/extra-bits (`LL_base`/`LL_bits`, 36 entries)

  static let literalLengthBase = [
    0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15,
    16, 18, 20, 22, 24, 28, 32, 40, 48, 64, 0x80, 0x100, 0x200, 0x400, 0x800, 0x1000,
    0x2000, 0x4000, 0x8000, 0x10000,
  ]
  static let literalLengthExtraBits = [
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    1, 1, 1, 1, 2, 2, 3, 3, 4, 6, 7, 8, 9, 10, 11, 12,
    13, 14, 15, 16,
  ]

  // MARK: Match_Length_Code baseline/extra-bits (`ML_base`/`ML_bits`, 53 entries)

  static let matchLengthBase = [
    3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18,
    19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34,
    35, 37, 39, 41, 43, 47, 51, 59, 67, 83, 99, 0x83, 0x103, 0x203, 0x403, 0x803,
    0x1003, 0x2003, 0x4003, 0x8003, 0x10003,
  ]
  static let matchLengthExtraBits = [
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    1, 1, 1, 1, 2, 2, 3, 3, 4, 4, 5, 7, 8, 9, 10, 11,
    12, 13, 14, 15, 16,
  ]

  // MARK: Offset_Code baseline/extra-bits (`OF_base`/`OF_bits`, 32 entries — offset codes go up to
  // `MaxOff`=31 under `FSE_Compressed` mode, wider than the predefined table's 29-symbol range)

  static let offsetBase = [
    0, 1, 1, 5, 0xD, 0x1D, 0x3D, 0x7D, 0xFD, 0x1FD, 0x3FD, 0x7FD, 0xFFD, 0x1FFD, 0x3FFD, 0x7FFD,
    0xFFFD, 0x1FFFD, 0x3FFFD, 0x7FFFD, 0xFFFFD, 0x1FFFFD, 0x3FFFFD, 0x7FFFFD,
    0xFFFFFD, 0x1FFFFFD, 0x3FFFFFD, 0x7FFFFFD, 0xFFFFFFD, 0x1FFFFFFD, 0x3FFFFFFD, 0x7FFFFFFD,
  ]
  static let offsetExtraBits = Array(0...31)

  // MARK: Predefined default distributions (`LL_defaultNorm`/`ML_defaultNorm`/`OF_defaultNorm`)

  static let literalLengthDefaultNorm = [
    4, 3, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 1, 1,
    2, 2, 2, 2, 2, 2, 2, 2, 2, 3, 2, 1, 1, 1, 1, 1,
    -1, -1, -1, -1,
  ]
  static let matchLengthDefaultNorm = [
    1, 4, 3, 2, 2, 2, 2, 2, 2, 1, 1, 1, 1, 1, 1, 1,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, -1, -1,
    -1, -1, -1, -1, -1,
  ]
  static let offsetDefaultNorm = [
    1, 1, 1, 1, 1, 1, 2, 2, 2, 1, 1, 1, 1, 1, 1, 1,
    1, 1, 1, 1, 1, 1, 1, 1, -1, -1, -1, -1, -1,
  ]
}
