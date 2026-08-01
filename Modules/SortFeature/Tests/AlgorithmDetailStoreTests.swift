import DesignSystemKit
import Foundation
import Testing

@testable import SortFeature

private final class StoreTestBundleMarker {}

/// The old `AlgorithmDetailContent.load(for:)` body, verbatim, reading straight from the loose
/// `App/Resources/AlgorithmDetails/<id>/*.md` files on the working tree rather than through
/// `Bundle.main` — this test's oracle, kept only here now that production code delegates to
/// `AlgorithmDetailStore`. `#filePath`-relative walk-up to the repo root mirrors
/// `Modules/BuiltInAlgorithms/Tests/GrowthModelCalibrationTests.swift:746-750`'s exact technique.
private enum LegacyLoader {
  static var algorithmDetailsRoot: URL {
    URL(fileURLWithPath: #filePath)
      .deletingLastPathComponent()  // Tests/
      .deletingLastPathComponent()  // SortFeature/
      .deletingLastPathComponent()  // Modules/
      .deletingLastPathComponent()  // repo root
      .appendingPathComponent("App/Resources/AlgorithmDetails")
  }

  /// Same discovery + exclusion rule `Module.algorithmDetailCopyFiles()` used before it was
  /// deleted: every subdirectory of `AlgorithmDetails/` except the `template`/`__pycache__`
  /// non-algorithm folders.
  static func discoverAlgorithmIDs() throws -> [String] {
    let excluded: Set<String> = ["template", "__pycache__"]
    let entries = try FileManager.default.contentsOfDirectory(
      at: algorithmDetailsRoot, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles]
    )
    return
      entries
      .filter { (try? $0.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true }
      .map(\.lastPathComponent)
      .filter { !excluded.contains($0) }
      .sorted()
  }

  static func load(for algorithmID: String) -> AlgorithmDetailContent? {
    let algorithmURL = algorithmDetailsRoot.appendingPathComponent(algorithmID, isDirectory: true)
    var isDirectory: ObjCBool = false
    guard FileManager.default.fileExists(atPath: algorithmURL.path, isDirectory: &isDirectory),
      isDirectory.boolValue
    else {
      return nil
    }

    let description = try? String(
      contentsOf: algorithmURL.appendingPathComponent("description.md"), encoding: .utf8
    )
    let codeSamples = CodeLanguage.all.compactMap { language -> (language: CodeLanguage, source: String)? in
      let url = algorithmURL.appendingPathComponent("\(language.id).md")
      guard let source = try? String(contentsOf: url, encoding: .utf8) else { return nil }
      return (language: language, source: source)
    }
    guard description != nil || !codeSamples.isEmpty else { return nil }
    return AlgorithmDetailContent(description: description, codeSamples: codeSamples)
  }
}

/// The equivalence proof `COMPRESSION_DESIGN.md` calls for: every algorithm's content, loaded
/// through the archive-backed `AlgorithmDetailStore`, must be byte-for-byte identical to what the
/// old loose-file loader reads directly off disk.
@Suite
struct AlgorithmDetailStoreTests {
  private static var testBundle: Bundle { Bundle(for: StoreTestBundleMarker.self) }

  @Test func everyAlgorithmMatchesTheLegacyLoaderByteForByte() async throws {
    let store = AlgorithmDetailStore(bundle: Self.testBundle)
    let algorithmIDs = try LegacyLoader.discoverAlgorithmIDs()
    #expect(!algorithmIDs.isEmpty)

    for algorithmID in algorithmIDs {
      let legacy = LegacyLoader.load(for: algorithmID)
      let fromStore = await store.content(for: algorithmID)

      #expect(
        fromStore?.description == legacy?.description, "\(algorithmID): description mismatch"
      )
      #expect(
        fromStore?.codeSamples.count == legacy?.codeSamples.count,
        "\(algorithmID): code sample count mismatch"
      )
      let fromStoreSamples = fromStore?.codeSamples ?? []
      let legacySamples = legacy?.codeSamples ?? []
      for (storeSample, legacySample) in zip(fromStoreSamples, legacySamples) {
        #expect(storeSample.language == legacySample.language, "\(algorithmID): language order mismatch")
        #expect(storeSample.source == legacySample.source, "\(algorithmID)/\(storeSample.language.id): source mismatch")
      }
    }
  }

  @Test func unknownAlgorithmIDReturnsNil() async {
    let store = AlgorithmDetailStore(bundle: Self.testBundle)
    let content = await store.content(for: "this-algorithm-does-not-exist")
    #expect(content == nil)
  }
}
