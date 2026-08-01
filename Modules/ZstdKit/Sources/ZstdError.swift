/// Errors a `Zstd.decompress` call can throw. Every structural or memory-safety condition the
/// decoder checks throws one of these in release builds — none of it is gated behind `assert`.
public enum ZstdError: Error, Sendable, Equatable {
  case invalidMagic
  case unsupportedFrameFeature(String)
  case unsupportedWindowSize(requested: Int, limit: Int)
  case frameSizeExceeded(requested: Int, limit: Int)
  case outputLimitExceeded(requested: Int, limit: Int)
  case blockCountExceeded(limit: Int)
  case truncatedInput
  case invalidFrameHeader
  case invalidBlockHeader
  case contentSizeMismatch(expected: Int, actual: Int)
  case invalidLiteralsSection
  case invalidHuffmanTable
  case invalidFSETable
  case invalidBitstream
  case invalidSequenceStream
  case invalidMatchOffset
  case dictionaryRequired(id: UInt32)
  case dictionaryIDMismatch(expected: UInt32, actual: UInt32)
  case checksumMismatch
  case trailingData
}
