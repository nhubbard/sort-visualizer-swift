import Foundation

/// Loads the `<name>.zst`/`<name>.expected` pairs `FixtureGenerator/generate.py` writes into
/// `Tests/Fixtures/`, bundled into the test target via `testResources` in `Project.swift`.
private final class FixtureBundleMarker {}

enum Fixture {
  enum FixtureError: Error {
    case missing(name: String, extension: String)
  }

  static let bundle = Bundle(for: FixtureBundleMarker.self)

  static func compressed(_ name: String) throws -> Data {
    try load(name, extension: "zst")
  }

  static func expected(_ name: String) throws -> Data {
    try load(name, extension: "expected")
  }

  private static func load(_ name: String, extension fileExtension: String) throws -> Data {
    guard let url = bundle.url(forResource: name, withExtension: fileExtension) else {
      throw FixtureError.missing(name: name, extension: fileExtension)
    }
    return try Data(contentsOf: url)
  }
}
