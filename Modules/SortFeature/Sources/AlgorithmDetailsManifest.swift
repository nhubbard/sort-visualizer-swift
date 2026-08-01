import DesignSystemKit

/// One content entry inside a directory record: `kind` 0 = description, 1...10 = a `CodeLanguage`
/// (index `kind - 1` into `CodeLanguage.all`) — see `COMPRESSION_DESIGN.md`'s
/// content-kind table. `range` is content-section-relative, matching how the format stores it.
struct AlgorithmDetailsContentEntryRecord {
  let kind: UInt16
  let flags: UInt16
  let range: Range<Int>
}

struct AlgorithmDetailsDirectoryRecord {
  let algorithmID: String
  let entries: [AlgorithmDetailsContentEntryRecord]
}

/// The inner `ADTL` manifest (`COMPRESSION_DESIGN.md`'s "Container format" §
/// "Inner payload header"/"Algorithm directory records"/"Content entries"), parsed from the
/// decompressed payload `ZstdKit` produces.
struct AlgorithmDetailsManifest {
  static let magic: [UInt8] = [0x41, 0x44, 0x54, 0x4C, 0x0D, 0x0A, 0x1A, 0x0A]
  static let fixedHeaderSize = 56
  /// Bit 0 of a content entry's own `Entry flags`: "required" — an unrecognized content kind with
  /// this bit set is `.missingRequiredContent` rather than silently skipped.
  private static let requiredEntryFlag: UInt16 = 0x1

  let directoryRecords: [AlgorithmDetailsDirectoryRecord]
  let contentOffset: Int
  let contentLength: Int

  static func parse(_ payload: [UInt8]) throws -> AlgorithmDetailsManifest {
    var reader = ArchiveByteReader(payload)
    let magicBytes = try reader.readBytes(8)
    guard Array(magicBytes) == magic else { throw AlgorithmDetailsArchiveError.invalidMagic }

    let schemaMajor = try reader.readLittleEndianUInt(byteCount: 2)
    _ = try reader.readLittleEndianUInt(byteCount: 2)  // schema minor
    let headerLength = try reader.readLittleEndianUInt(byteCount: 4)
    _ = try reader.readLittleEndianUInt(byteCount: 4)  // flags, reserved in v1
    let algorithmCount = try reader.readLittleEndianUInt(byteCount: 4)
    let directoryOffset = try reader.readLittleEndianUInt(byteCount: 8)
    let directoryLength = try reader.readLittleEndianUInt(byteCount: 8)
    let contentOffset = try reader.readLittleEndianUInt(byteCount: 8)
    let contentLength = try reader.readLittleEndianUInt(byteCount: 8)

    guard let headerLengthInt = Int(exactly: headerLength),
      headerLengthInt >= fixedHeaderSize, headerLengthInt <= payload.count
    else {
      throw AlgorithmDetailsArchiveError.invalidManifest
    }
    guard schemaMajor == 1 else { throw AlgorithmDetailsArchiveError.unsupportedVersion }
    guard let algorithmCountInt = Int(exactly: algorithmCount),
      let directoryOffsetInt = Int(exactly: directoryOffset),
      let directoryLengthInt = Int(exactly: directoryLength),
      let contentOffsetInt = Int(exactly: contentOffset),
      let contentLengthInt = Int(exactly: contentLength)
    else {
      throw AlgorithmDetailsArchiveError.invalidManifest
    }

    guard directoryOffsetInt <= payload.count else { throw AlgorithmDetailsArchiveError.invalidSectionRange }
    guard directoryLengthInt <= payload.count - directoryOffsetInt else {
      throw AlgorithmDetailsArchiveError.invalidSectionRange
    }
    guard contentOffsetInt <= payload.count else { throw AlgorithmDetailsArchiveError.invalidSectionRange }
    guard contentLengthInt <= payload.count - contentOffsetInt else {
      throw AlgorithmDetailsArchiveError.invalidSectionRange
    }
    // "The manifest (payload header + directory) and the content section must not overlap."
    let directoryEnd = directoryOffsetInt + directoryLengthInt
    guard contentOffsetInt >= directoryEnd else { throw AlgorithmDetailsArchiveError.overlappingContent }

    var cursor = directoryOffsetInt
    var records: [AlgorithmDetailsDirectoryRecord] = []
    records.reserveCapacity(algorithmCountInt)
    var seenIDs = Set<String>()
    var allEntryRanges: [Range<Int>] = []

    // Walks exactly `algorithmCountInt` records — never scans to the end of the directory looking
    // for more, per the plan's explicit requirement.
    for _ in 0..<algorithmCountInt {
      guard cursor + 12 <= directoryEnd else { throw AlgorithmDetailsArchiveError.invalidManifest }
      var recordReader = ArchiveByteReader(payload, offset: cursor)
      let recordLength = try recordReader.readLittleEndianUInt(byteCount: 4)
      let idLength = try recordReader.readLittleEndianUInt(byteCount: 2)
      let entryCount = try recordReader.readLittleEndianUInt(byteCount: 2)
      _ = try recordReader.readLittleEndianUInt(byteCount: 4)  // algorithm flags, reserved in v1

      guard let recordLengthInt = Int(exactly: recordLength),
        let idLengthInt = Int(exactly: idLength),
        let entryCountInt = Int(exactly: entryCount)
      else {
        throw AlgorithmDetailsArchiveError.invalidManifest
      }
      let minimumRecordLength = 12 + idLengthInt + entryCountInt * 24
      guard recordLengthInt >= minimumRecordLength else { throw AlgorithmDetailsArchiveError.invalidManifest }
      guard cursor + recordLengthInt <= directoryEnd else { throw AlgorithmDetailsArchiveError.invalidManifest }

      guard idLengthInt > 0 else { throw AlgorithmDetailsArchiveError.invalidManifest }
      let idBytes = try recordReader.readBytes(idLengthInt)
      guard let algorithmID = String(validating: Array(idBytes), as: UTF8.self) else {
        throw AlgorithmDetailsArchiveError.invalidUTF8
      }
      guard seenIDs.insert(algorithmID).inserted else {
        throw AlgorithmDetailsArchiveError.duplicateAlgorithmID
      }

      var entries: [AlgorithmDetailsContentEntryRecord] = []
      entries.reserveCapacity(entryCountInt)
      var seenKinds = Set<UInt16>()
      for _ in 0..<entryCountInt {
        let kind = try recordReader.readLittleEndianUInt(byteCount: 2)
        let entryFlags = try recordReader.readLittleEndianUInt(byteCount: 2)
        let entryOffset = try recordReader.readLittleEndianUInt(byteCount: 8)
        let entryLength = try recordReader.readLittleEndianUInt(byteCount: 8)
        _ = try recordReader.readLittleEndianUInt(byteCount: 4)  // reserved, must be zero in v1

        guard let kindUInt16 = UInt16(exactly: kind), let flagsUInt16 = UInt16(exactly: entryFlags) else {
          throw AlgorithmDetailsArchiveError.invalidManifest
        }
        guard seenKinds.insert(kindUInt16).inserted else {
          throw AlgorithmDetailsArchiveError.duplicateContentKind
        }
        guard let entryOffsetInt = Int(exactly: entryOffset), let entryLengthInt = Int(exactly: entryLength)
        else {
          throw AlgorithmDetailsArchiveError.invalidManifest
        }
        // Content-section-relative bounds, not just archive-wide — a corrupted entry must not be
        // able to "legally" reach into the directory region.
        guard entryOffsetInt <= contentLengthInt else { throw AlgorithmDetailsArchiveError.invalidSectionRange }
        guard entryLengthInt <= contentLengthInt - entryOffsetInt else {
          throw AlgorithmDetailsArchiveError.invalidSectionRange
        }

        let range = entryOffsetInt..<(entryOffsetInt + entryLengthInt)
        allEntryRanges.append(range)
        entries.append(AlgorithmDetailsContentEntryRecord(kind: kindUInt16, flags: flagsUInt16, range: range))
      }

      records.append(AlgorithmDetailsDirectoryRecord(algorithmID: algorithmID, entries: entries))
      cursor += recordLengthInt
    }

    guard cursor == directoryEnd else { throw AlgorithmDetailsArchiveError.invalidManifest }

    // No two content entries may overlap (a gap is wasteful but not unsafe, so gaps are allowed).
    let sortedRanges = allEntryRanges.sorted { $0.lowerBound < $1.lowerBound }
    if sortedRanges.count > 1 {
      for index in 1..<sortedRanges.count where sortedRanges[index].lowerBound < sortedRanges[index - 1].upperBound
      {
        throw AlgorithmDetailsArchiveError.overlappingContent
      }
    }

    return AlgorithmDetailsManifest(
      directoryRecords: records, contentOffset: contentOffsetInt, contentLength: contentLengthInt
    )
  }

  /// Materializes every content entry's bytes as UTF-8 `String`s, keyed by algorithm ID. `payload`
  /// is the same decompressed buffer `parse(_:)` was given — entry ranges are content-section-
  /// relative, so `contentOffset` gets added back here to reach the absolute position.
  func buildContentDictionary(payload: [UInt8]) throws -> [String: AlgorithmDetailContent] {
    var result: [String: AlgorithmDetailContent] = [:]
    result.reserveCapacity(directoryRecords.count)

    for record in directoryRecords {
      var description: String?
      // Entries appear in the file in ascending content-kind order (the packer emits description
      // first, then languages in `CodeLanguage.all`'s order) — preserved here by iterating in file
      // order rather than re-sorting.
      var codeSamples: [(language: CodeLanguage, source: String)] = []

      for entry in record.entries {
        let languageIndex = Int(entry.kind) - 1
        let isDescription = entry.kind == 0
        let isKnownLanguage = languageIndex >= 0 && languageIndex < CodeLanguage.all.count
        guard isDescription || isKnownLanguage else {
          // Forward-compatible: an unrecognized content kind is skippable unless the entry itself
          // says it's required.
          if entry.flags & Self.requiredEntryFlag != 0 {
            throw AlgorithmDetailsArchiveError.missingRequiredContent
          }
          continue
        }

        let absoluteStart = contentOffset + entry.range.lowerBound
        let absoluteEnd = contentOffset + entry.range.upperBound
        guard absoluteEnd <= payload.count else { throw AlgorithmDetailsArchiveError.invalidSectionRange }
        let text = try Self.decodeUTF8(payload[absoluteStart..<absoluteEnd])

        if isDescription {
          description = text
        } else {
          codeSamples.append((language: CodeLanguage.all[languageIndex], source: text))
        }
      }

      result[record.algorithmID] = AlgorithmDetailContent(description: description, codeSamples: codeSamples)
    }

    return result
  }

  private static func decodeUTF8(_ bytes: ArraySlice<UInt8>) throws -> String {
    guard let text = String(validating: Array(bytes), as: UTF8.self) else {
      throw AlgorithmDetailsArchiveError.invalidUTF8
    }
    return text
  }
}
