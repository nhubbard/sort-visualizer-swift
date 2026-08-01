import Foundation

/// A from-scratch, decode-only Zstandard implementation — no C/C++ interop. Encoding is
/// permanently out of scope; the Python content pipeline (`App/Resources/AlgorithmDetails/manage.py`)
/// is the sole encoder. See `COMPRESSION_AND_STRETCH_GOALS_PLAN.md` for the full design rationale.
public enum Zstd {
  /// Decompresses one standard Zstd frame. Concatenated frames, skippable frames, legacy formats,
  /// and magicless framing are rejected with a specific `ZstdError`, not misclassified as corrupt
  /// data. Dictionary support is not yet part of this API — frames requiring one throw
  /// `.dictionaryRequired`.
  public static func decompress(
    _ frame: Data,
    limits: ZstdDecodingLimits = .default
  ) throws -> Data {
    try ZstdDecompressor.decompress(frame, limits: limits)
  }
}
