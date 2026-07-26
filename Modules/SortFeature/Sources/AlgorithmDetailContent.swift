import DesignSystemKit
import Foundation

/// One algorithm's optional description + per-language code samples, loaded from
/// `App/Resources/AlgorithmDetails/<id>/`. That directory also holds sibling `<name>.bundle/`
/// authoring folders (raw source + the Pygments highlighting pipeline) that Tuist's Copy Files
/// phase does NOT bundle into the app — only the plain `<id>/` folders this type reads. Not
/// every algorithm has this content; missing content loads as `nil`, which
/// `AlgorithmDetailSection` renders as a placeholder rather than a blank/broken view.
struct AlgorithmDetailContent {
  let description: String?
  let codeSamples: [(language: CodeLanguage, source: String)]

  static func load(for algorithmID: String) -> AlgorithmDetailContent? {
    guard let baseURL = Bundle.main.url(forResource: "AlgorithmDetails", withExtension: nil) else {
      return nil
    }
    let algorithmURL = baseURL.appendingPathComponent(algorithmID, isDirectory: true)
    var isDirectory: ObjCBool = false
    guard FileManager.default.fileExists(atPath: algorithmURL.path, isDirectory: &isDirectory),
      isDirectory.boolValue
    else {
      return nil
    }

    let description = try? String(
      contentsOf: algorithmURL.appendingPathComponent("description.md"),
      encoding: .utf8
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
