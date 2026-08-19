#!/usr/bin/env swift
// Bundles the `golden_*`/`decodecorpus_*` loose fixture files (see `GoldenCorpusTests.swift`'s own
// doc comment and `README.md`'s "Golden/decodecorpus fixtures" section) into two compressed
// archives, `golden.fixtures.zbin`/`decodecorpus.fixtures.zbin`, so ~1,619 individual files don't
// need to sit in the repo. Not run by the build — a one-time authoring tool, like `generate.py`.
//
// Uses Apple's `Compression` framework (`NSData.compressed(using: .zlib)`) deliberately, NOT
// `ZstdKit` itself: this bundles *ZstdKit's own test fixtures*, so depending on ZstdKit to unpack
// them would be circular — a compressor bug could make the suite that's supposed to catch it lie
// about passing instead. `.zlib` here is raw DEFLATE (RFC 1951), not RFC 1950 zlib-wrapped --
// confirmed via Apple DTS, see Documentation/docs/reference/compression.md's contingency-plan section. The runtime test
// helper (`Tests/FixtureArchive.swift`) uses the exact same API, so the two sides are guaranteed
// bit-compatible.
//
// Archive format (see `Tests/FixtureArchive.swift` for the decode side):
//   [4 bytes]  magic "ZFX1"
//   [4 bytes]  UInt32 LE entry count N
//   N x        [2 bytes UInt16 LE name length][name UTF8]
//              [8 bytes UInt64 LE offset][8 bytes UInt64 LE length]
//   [8 bytes]  UInt64 LE total uncompressed payload length
//   [rest]     one `.zlib`-compressed blob of every entry's bytes concatenated in manifest order
//
// Usage: swift build_fixture_archives.swift

import Foundation

let fixturesDir = URL(fileURLWithPath: #filePath)
  .deletingLastPathComponent()
  .deletingLastPathComponent()
  .appendingPathComponent("Tests/Fixtures")

struct ArchiveGroup {
  let archiveName: String
  let filePrefix: String
}

let groups = [
  ArchiveGroup(archiveName: "golden.fixtures.zbin", filePrefix: "golden_"),
  ArchiveGroup(archiveName: "decodecorpus.fixtures.zbin", filePrefix: "decodecorpus_"),
]

enum ArchiveError: Error {
  case invalidMagic
  case truncated
}

func writeUInt16(_ value: UInt16, into data: inout Data) {
  data.append(UInt8(value & 0xFF))
  data.append(UInt8((value >> 8) & 0xFF))
}

func writeUInt32(_ value: UInt32, into data: inout Data) {
  for shift in stride(from: 0, to: 32, by: 8) {
    data.append(UInt8((value >> shift) & 0xFF))
  }
}

func writeUInt64(_ value: UInt64, into data: inout Data) {
  for shift in stride(from: 0, to: 64, by: 8) {
    data.append(UInt8((value >> shift) & 0xFF))
  }
}

func readUInt16(_ data: Data, at offset: inout Int) -> UInt16 {
  let value = UInt16(data[data.startIndex + offset]) | (UInt16(data[data.startIndex + offset + 1]) << 8)
  offset += 2
  return value
}

func readUInt32(_ data: Data, at offset: inout Int) -> UInt32 {
  var value: UInt32 = 0
  for shift in stride(from: 0, to: 32, by: 8) {
    value |= UInt32(data[data.startIndex + offset]) << shift
    offset += 1
  }
  return value
}

func readUInt64(_ data: Data, at offset: inout Int) -> UInt64 {
  var value: UInt64 = 0
  for shift in stride(from: 0, to: 64, by: 8) {
    value |= UInt64(data[data.startIndex + offset]) << shift
    offset += 1
  }
  return value
}

struct ManifestEntry {
  let name: String
  let offset: UInt64
  let length: UInt64
}

func decodeArchive(_ archiveData: Data) throws -> (entries: [ManifestEntry], payload: Data) {
  guard archiveData.count >= 8, archiveData.prefix(4).elementsEqual("ZFX1".utf8) else {
    throw ArchiveError.invalidMagic
  }
  var offset = 4
  let entryCount = Int(readUInt32(archiveData, at: &offset))
  var entries: [ManifestEntry] = []
  entries.reserveCapacity(entryCount)
  for _ in 0..<entryCount {
    let nameLength = Int(readUInt16(archiveData, at: &offset))
    let nameStart = archiveData.startIndex + offset
    let nameBytes = archiveData[nameStart..<(nameStart + nameLength)]
    guard let name = String(data: nameBytes, encoding: .utf8) else { throw ArchiveError.truncated }
    offset += nameLength
    let entryOffset = readUInt64(archiveData, at: &offset)
    let entryLength = readUInt64(archiveData, at: &offset)
    entries.append(ManifestEntry(name: name, offset: entryOffset, length: entryLength))
  }
  let totalUncompressedLength = readUInt64(archiveData, at: &offset)
  let compressedPayload = archiveData[(archiveData.startIndex + offset)...]
  let payload = try (compressedPayload as NSData).decompressed(using: .zlib) as Data
  guard payload.count == totalUncompressedLength else { throw ArchiveError.truncated }
  return (entries, payload)
}

for group in groups {
  let files = try FileManager.default.contentsOfDirectory(at: fixturesDir, includingPropertiesForKeys: nil)
    .filter { $0.lastPathComponent.hasPrefix(group.filePrefix) }
    .sorted { $0.lastPathComponent < $1.lastPathComponent }
  guard !files.isEmpty else {
    print("\(group.archiveName): no files matching prefix '\(group.filePrefix)', skipping")
    continue
  }

  var manifest = Data()
  writeUInt32(UInt32(files.count), into: &manifest)
  var payload = Data()
  var originals: [String: Data] = [:]
  for file in files {
    let name = file.lastPathComponent
    let bytes = try Data(contentsOf: file)
    originals[name] = bytes
    let nameBytes = Array(name.utf8)
    writeUInt16(UInt16(nameBytes.count), into: &manifest)
    manifest.append(contentsOf: nameBytes)
    writeUInt64(UInt64(payload.count), into: &manifest)
    writeUInt64(UInt64(bytes.count), into: &manifest)
    payload.append(bytes)
  }
  writeUInt64(UInt64(payload.count), into: &manifest)

  let compressedPayload = try (payload as NSData).compressed(using: .zlib) as Data

  var archive = Data("ZFX1".utf8)
  archive.append(manifest)
  archive.append(compressedPayload)

  let outputURL = fixturesDir.appendingPathComponent(group.archiveName)
  try archive.write(to: outputURL)

  // Self-verify immediately: decode our own output and compare every entry back against the
  // original loose file bytes, exactly the "verify before trusting" convention `generate.py`
  // already uses for its own fixtures.
  let roundTripped = try Data(contentsOf: outputURL)
  let (entries, decodedPayload) = try decodeArchive(roundTripped)
  guard entries.count == files.count else {
    fatalError("\(group.archiveName): entry count mismatch after round-trip")
  }
  for entry in entries {
    let start = decodedPayload.startIndex + Int(entry.offset)
    let end = start + Int(entry.length)
    let extracted = decodedPayload[start..<end]
    guard let original = originals[entry.name], Data(extracted) == original else {
      fatalError("\(group.archiveName): round-trip mismatch for \(entry.name)")
    }
  }

  let originalTotal = originals.values.reduce(0) { $0 + $1.count }
  print(
    "\(group.archiveName): \(files.count) files, \(originalTotal) B original -> "
      + "\(archive.count) B archive (verified byte-for-byte)")
}
