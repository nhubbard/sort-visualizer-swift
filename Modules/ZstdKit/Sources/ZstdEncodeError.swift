import Foundation

/// Errors specific to encoding — distinct from `ZstdError` (which models malformed *input* to a
/// decoder; none of those conditions apply when this module is the one producing the bytes).
public enum ZstdEncodeError: Error, Sendable, Equatable {
  /// `input.count` exceeds `ZstdEncodingOptions.maximumInputSize` — a sanity ceiling, not a
  /// fundamental limit, since this encoder holds the whole input in memory at once (no streaming).
  case inputTooLarge(requested: Int, limit: Int)
}
