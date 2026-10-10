import CryptoKit
import Foundation
import Testing
import ZstdKit

@testable import SortFeature

/// Loads the real `AlgorithmDetails.algz` bundled into `SortFeatureTests` via `testResources` in
/// the root `Project.swift` — mirrors `ZstdKit`'s own `Fixture.bundle = Bundle(for:
/// FixtureBundleMarker.self)` pattern.
private final class ArchiveTestBundleMarker {}

private func loadRealArchiveBytes() throws -> [UInt8] {
  let bundle = Bundle(for: ArchiveTestBundleMarker.self)
  let url = try #require(bundle.url(forResource: "AlgorithmDetails", withExtension: "algz"))
  return [UInt8](try Data(contentsOf: url))
}

/// Envelope/manifest parsing against the real archive, plus malformed-input tests against
/// hand-corrupted copies of its bytes — mirrors `ZstdKit`'s `MalformedInputTests.swift` style.
@Suite
struct AlgorithmDetailsArchiveTests {
  @Test func envelopeParsesRealArchive() throws {
    let bytes = try loadRealArchiveBytes()
    let envelope = try AlgorithmDetailsEnvelope.parse(bytes)
    #expect(envelope.sha256.count == 32)
    #expect(envelope.decompressedLength > 0)
    #expect(!envelope.frameRange.isEmpty)
    #expect(envelope.frameRange.upperBound <= bytes.count)
  }

  @Test func fullPipelineDecodesLosslessly() throws {
    let bytes = try loadRealArchiveBytes()
    let envelope = try AlgorithmDetailsEnvelope.parse(bytes)

    let frameBytes = Array(bytes[envelope.frameRange])
    let decompressed = try Zstd.decompress(Data(frameBytes))
    #expect(decompressed.count == envelope.decompressedLength)

    let digest = SHA256.hash(data: decompressed)
    #expect(Array(digest) == envelope.sha256)

    let payload = [UInt8](decompressed)
    let manifest = try AlgorithmDetailsManifest.parse(payload)
    #expect(manifest.directoryRecords.count > 0)

    let contentByID = try manifest.buildContentDictionary(payload: payload)
    #expect(!contentByID.isEmpty)
    #expect(contentByID.count == manifest.directoryRecords.count)
    let quickSort = try #require(contentByID["quicksort"])
    #expect(quickSort.localizedDescriptions["es"]?.hasPrefix("Quick Sort es") == true)
    #expect(quickSort.description?.hasPrefix("Quick Sort") == true)
    for (algorithmID, content) in contentByID {
      #expect(
        content.localizedDescriptions["es"]?.isEmpty == false,
        "\(algorithmID): missing Spanish description"
      )
    }
  }

  @Test func legacyManifestWithoutTranslationsStillLoads() throws {
    var payload = AlgorithmDetailsManifest.magic
    func append<T: FixedWidthInteger>(_ value: T) {
      let littleEndian = value.littleEndian
      withUnsafeBytes(of: littleEndian) { payload.append(contentsOf: $0) }
    }
    let algorithmID = Array("legacy".utf8)
    let description = Array("English description".utf8)
    let directoryLength = 12 + algorithmID.count + 24
    append(UInt16(1)) // schema major
    append(UInt16(0)) // legacy schema minor
    append(UInt32(56)) // header length
    append(UInt32(0)) // flags
    append(UInt32(1)) // algorithm count
    append(UInt64(56)) // directory offset
    append(UInt64(directoryLength))
    append(UInt64(56 + directoryLength)) // content offset
    append(UInt64(description.count))
    append(UInt32(directoryLength)) // record length
    append(UInt16(algorithmID.count))
    append(UInt16(1)) // entry count
    append(UInt32(0)) // algorithm flags
    payload.append(contentsOf: algorithmID)
    append(UInt16(0)) // English description kind
    append(UInt16(0)) // entry flags
    append(UInt64(0)) // relative offset
    append(UInt64(description.count))
    append(UInt32(0)) // reserved
    payload.append(contentsOf: description)

    let manifest = try AlgorithmDetailsManifest.parse(payload)
    let content = try #require(manifest.buildContentDictionary(payload: payload)["legacy"])
    #expect(content.description == "English description")
    #expect(content.localizedDescriptions.isEmpty)
  }

  @Test func flippedMagicByteThrowsInvalidMagic() throws {
    var bytes = try loadRealArchiveBytes()
    bytes[0] ^= 0xFF
    #expect(throws: AlgorithmDetailsArchiveError.invalidMagic) {
      try AlgorithmDetailsEnvelope.parse(bytes)
    }
  }

  @Test func corruptedFlagsByteThrowsUnsupportedFlags() throws {
    var bytes = try loadRealArchiveBytes()
    // Flags is the 4-byte little-endian field at offset 16 in the 96-byte fixed header.
    bytes[16] ^= 0xFF
    #expect(throws: AlgorithmDetailsArchiveError.unsupportedFlags) {
      try AlgorithmDetailsEnvelope.parse(bytes)
    }
  }

  @Test func flippedSHA256ByteMakesTheDigestMismatch() throws {
    var bytes = try loadRealArchiveBytes()
    // SHA-256 is the last 32 bytes (offsets 64...95) of the 96-byte fixed header — corrupting it
    // doesn't affect structural parsing (still succeeds), only the eventual digest comparison.
    bytes[64] ^= 0xFF
    let envelope = try AlgorithmDetailsEnvelope.parse(bytes)

    let frameBytes = Array(bytes[envelope.frameRange])
    let decompressed = try Zstd.decompress(Data(frameBytes))
    let digest = SHA256.hash(data: decompressed)
    #expect(Array(digest) != envelope.sha256)
  }

  @Test func truncatedArchiveThrows() throws {
    let bytes = try loadRealArchiveBytes()
    let truncated = Array(bytes.prefix(10))
    #expect(throws: AlgorithmDetailsArchiveError.self) {
      try AlgorithmDetailsEnvelope.parse(truncated)
    }
  }

  @Test func emptyArchiveThrows() throws {
    #expect(throws: AlgorithmDetailsArchiveError.self) {
      try AlgorithmDetailsEnvelope.parse([])
    }
  }
}
