import Foundation

/// Decompresses the `golden.fixtures.zbin`/`decodecorpus.fixtures.zbin` archives
/// `FixtureGenerator/build_fixture_archives.swift` produces (see that file's header comment for
/// the exact binary format and why `Compression`/`NSData`, not `ZstdKit` itself, does the
/// decompression here — unpacking `ZstdKit`'s own test fixtures with `ZstdKit` would be circular).
/// Each archive is extracted once, lazily, into its own temp directory on first access; every
/// extracted directory is removed via `CleanupRegistry` when the test process exits.
final class FixtureArchive: @unchecked Sendable {
  static let golden = FixtureArchive(resourceName: "golden.fixtures")
  static let decodecorpus = FixtureArchive(resourceName: "decodecorpus.fixtures")

  enum ArchiveError: Error {
    case invalidMagic
    case truncated
  }

  private let resourceName: String
  private let lock = NSLock()
  private var extractedDirectory: URL?
  private var extractionError: Error?

  private init(resourceName: String) {
    self.resourceName = resourceName
  }

  /// `name` includes its extension, e.g. `"decodecorpus_042.zst"`.
  func data(named name: String) throws -> Data {
    let directory = try ensureExtracted()
    return try Data(contentsOf: directory.appendingPathComponent(name))
  }

  private func ensureExtracted() throws -> URL {
    lock.lock()
    defer { lock.unlock() }
    if let extractedDirectory { return extractedDirectory }
    if let extractionError { throw extractionError }
    do {
      let directory = try Self.extract(resourceName: resourceName)
      extractedDirectory = directory
      return directory
    } catch {
      extractionError = error
      throw error
    }
  }

  private static func extract(resourceName: String) throws -> URL {
    let archiveURL = try Fixture.url(forResourceNamed: resourceName, extension: "zbin")
    let archiveData = try Data(contentsOf: archiveURL)
    let (entries, payload) = try decode(archiveData)

    let directory = FileManager.default.temporaryDirectory
      .appendingPathComponent("ZstdKitFixtures-\(resourceName)-\(UUID().uuidString)")
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    CleanupRegistry.shared.register(directory)

    for entry in entries {
      let start = payload.startIndex + Int(entry.offset)
      let end = start + Int(entry.length)
      try payload[start..<end].write(to: directory.appendingPathComponent(entry.name))
    }
    return directory
  }

  // MARK: - Archive decoding
  // Must stay in sync with `FixtureGenerator/build_fixture_archives.swift`'s encode side.

  private struct ManifestEntry {
    let name: String
    let offset: UInt64
    let length: UInt64
  }

  private static func readUInt16(_ data: Data, at offset: inout Int) -> UInt16 {
    let value =
      UInt16(data[data.startIndex + offset]) | (UInt16(data[data.startIndex + offset + 1]) << 8)
    offset += 2
    return value
  }

  private static func readUInt32(_ data: Data, at offset: inout Int) -> UInt32 {
    var value: UInt32 = 0
    for shift in stride(from: 0, to: 32, by: 8) {
      value |= UInt32(data[data.startIndex + offset]) << shift
      offset += 1
    }
    return value
  }

  private static func readUInt64(_ data: Data, at offset: inout Int) -> UInt64 {
    var value: UInt64 = 0
    for shift in stride(from: 0, to: 64, by: 8) {
      value |= UInt64(data[data.startIndex + offset]) << shift
      offset += 1
    }
    return value
  }

  private static func decode(_ archiveData: Data) throws -> (entries: [ManifestEntry], payload: Data) {
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
      guard let name = String(data: archiveData[nameStart..<(nameStart + nameLength)], encoding: .utf8)
      else { throw ArchiveError.truncated }
      offset += nameLength
      let entryOffset = readUInt64(archiveData, at: &offset)
      let entryLength = readUInt64(archiveData, at: &offset)
      entries.append(ManifestEntry(name: name, offset: entryOffset, length: entryLength))
    }
    let totalUncompressedLength = readUInt64(archiveData, at: &offset)
    let compressedPayload = archiveData[(archiveData.startIndex + offset)...]
    // Apple's `Compression` framework, not `ZstdKit` -- see this file's header comment. `.zlib`
    // here is raw DEFLATE (RFC 1951), not RFC 1950 zlib-wrapped; both sides of this archive format
    // use the exact same API, so they're guaranteed bit-compatible regardless of that naming trap.
    let payload = try (compressedPayload as NSData).decompressed(using: .zlib) as Data
    guard payload.count == totalUncompressedLength else { throw ArchiveError.truncated }
    return (entries, payload)
  }
}

/// A plain top-level function (not a closure) so it converts unambiguously to the `@convention(c)
/// () -> Void` `atexit(3)` requires — no captured context, just a call into shared singleton state.
private func cleanUpExtractedFixtureArchives() {
  CleanupRegistry.shared.cleanUpAll()
}

/// Tracks every temp directory `FixtureArchive` has extracted into and removes all of them exactly
/// once, when the whole test process exits (`atexit`) -- the only lifecycle hook that fits
/// "decompress once, run every test, delete when complete": Swift Testing instantiates a fresh
/// suite value per test (and per parameterized case), so there's no single `deinit` that reliably
/// fires only after the *last* test finishes.
private final class CleanupRegistry: @unchecked Sendable {
  static let shared = CleanupRegistry()

  private let lock = NSLock()
  private var directories: [String] = []
  private var didRegisterAtExit = false

  func register(_ directory: URL) {
    lock.lock()
    defer { lock.unlock() }
    directories.append(directory.path)
    if !didRegisterAtExit {
      didRegisterAtExit = true
      atexit(cleanUpExtractedFixtureArchives)
    }
  }

  func cleanUpAll() {
    lock.lock()
    let paths = directories
    directories.removeAll()
    lock.unlock()
    for path in paths {
      try? FileManager.default.removeItem(atPath: path)
    }
  }
}
