/// Errors `AlgorithmDetailStore` and its parsers throw. Every structural/memory-safety condition
/// the `ALGZ`/`ADTL` container format has to check throws one of these in release builds — see
/// `COMPRESSION_DESIGN.md`'s "Container format"/"Safety model"/"Error model"
/// sections, which this enum is transcribed from directly.
enum AlgorithmDetailsArchiveError: Error, Sendable, Equatable {
  case invalidMagic
  /// Also covers an unsupported `Codec` value — the plan's error model doesn't carve out a
  /// separate case for that, and a codec mismatch is the same "this reader doesn't know how to
  /// handle this format" condition as an unsupported major version.
  case unsupportedVersion
  case unsupportedFlags
  case invalidHeader
  case invalidSectionRange
  case hashMismatch
  case invalidManifest
  case duplicateAlgorithmID
  case duplicateContentKind
  case overlappingContent
  case invalidUTF8
  case missingRequiredContent
  /// Not part of the container-format spec itself: the bundle simply doesn't contain
  /// `AlgorithmDetails.algz` at all. Distinct from every other case here, which all describe a
  /// present-but-malformed archive — this describes a packaging bug.
  case archiveResourceNotFound
}
