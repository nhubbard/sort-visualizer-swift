/// Mirrors `AlgorithmDetailsArchiveError`'s shape and rigor (`Modules/SortFeature/Sources/
/// AlgorithmDetailsArchiveError.swift`) for the tape export/import format — a distinct type
/// because that one is scoped to `SortFeature`, the wrong dependency direction from
/// `SortEngineKit`.
public enum TapeArchiveError: Error, Sendable, Equatable {
  case invalidMagic
  case unsupportedVersion
  case invalidHeader
  case invalidSectionRange
  case hashMismatch
  case invalidUTF8
  case truncatedOperationList
  case unknownOperationTag
}
