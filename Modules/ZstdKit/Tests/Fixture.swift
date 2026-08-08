import Foundation

/// Loads the `<name>.zst`/`<name>.expected` pairs `FixtureGenerator/generate.py` writes into
/// `Tests/Fixtures/`. Two build systems bundle these differently: Tuist's generated
/// `ZstdKitTests.xctest` target (`testResources` in `Project.swift`) copies them straight into the
/// test bundle itself, findable via class-based `Bundle(for:)` lookup; plain SPM's `.testTarget
/// (resources: [.copy("Fixtures")])` (`Package.swift`, for this module's standalone
/// `swift build`/`swift test` use — see `COMPRESSION_DESIGN.md`) instead copies them into a
/// *separate* module-resource bundle only `Bundle.module` (synthesized by SPM, `#if SWIFT_PACKAGE`
/// only) knows how to find — `Bundle(for:)` can't see into it. Both build systems compile this
/// exact same file, so the lookup has to switch, not just the resource declaration.
private final class FixtureBundleMarker {}

enum Fixture {
  enum FixtureError: Error {
    case missing(name: String, extension: String)
  }

  #if SWIFT_PACKAGE
  static let bundle = Bundle.module
  #else
  static let bundle = Bundle(for: FixtureBundleMarker.self)
  #endif

  static func compressed(_ name: String) throws -> Data {
    try load(name, extension: "zst")
  }

  static func expected(_ name: String) throws -> Data {
    try load(name, extension: "expected")
  }

  /// Shared by `load` below and `FixtureArchive` (which locates its own `.zbin` archives the
  /// same way) — the SPM-vs-Tuist subdirectory split is a property of how this module's two build
  /// systems bundle *any* resource, not just the plain `.zst`/`.expected` pairs `load` handles.
  static func url(forResourceNamed name: String, extension fileExtension: String) throws -> URL {
    // SPM's `.copy("Fixtures")` preserves that folder name inside the resource bundle (files land
    // at `<bundle>/Fixtures/name.ext`), unlike Tuist's glob-based `testResources`, which flattens
    // them to the bundle's root — same two-build-systems split as `bundle`'s own definition above.
    #if SWIFT_PACKAGE
    let subdirectory: String? = "Fixtures"
    #else
    let subdirectory: String? = nil
    #endif
    guard
      let url = bundle.url(
        forResource: name, withExtension: fileExtension, subdirectory: subdirectory)
    else {
      throw FixtureError.missing(name: name, extension: fileExtension)
    }
    return url
  }

  /// Fixtures named `golden_*`/`decodecorpus_*` (the real-Zstandard-project-derived corpus, see
  /// `GoldenCorpusTests.swift`) live inside `FixtureArchive`'s compressed `.zbin` bundles rather
  /// than as loose per-fixture resources — ~1,619 individual files was too many to keep in the
  /// repo. Routed here so `compressed`/`expected` (and every existing call site) don't need to
  /// know or care which storage a given fixture actually uses.
  private static func load(_ name: String, extension fileExtension: String) throws -> Data {
    if name.hasPrefix("golden_") {
      return try FixtureArchive.golden.data(named: "\(name).\(fileExtension)")
    }
    if name.hasPrefix("decodecorpus_") {
      return try FixtureArchive.decodecorpus.data(named: "\(name).\(fileExtension)")
    }
    let url = try url(forResourceNamed: name, extension: fileExtension)
    return try Data(contentsOf: url)
  }
}
