import DesignSystemKit
import Foundation

/// One algorithm's optional description + whichever per-language code samples exist —
/// `Legacy/Shared/Resources/<id>.bundle`'s content, reorganized under
/// `App/Resources/AlgorithmDetails/<id>/` (§4.2's "description/complexity/code samples —
/// unchanged resource-bundle loading", minus the `.bundle` packaging). `AlgorithmDetails/` also
/// holds sibling `<name>.bundle/` authoring folders (raw source + the Pygments highlighting
/// pipeline — see that directory's own README) — those are never bundled into the app (Tuist's
/// `copyFiles` Copy Files phase only re-nests the plain `<id>/` folders this type reads), so their
/// presence on disk doesn't affect anything here. Only 13 of the app's 20 ported algorithms have
/// this content — the rest (mostly the Phase 7 ArrayV-original ports) load as `nil`, which
/// `AlgorithmDetailSection` renders as a plain "not available yet" placeholder rather than a blank
/// or broken view.
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
    let codeSamples = CodeLanguage.all.compactMap {
      language -> (language: CodeLanguage, source: String)? in
      let url = algorithmURL.appendingPathComponent("\(language.id).md")
      guard let source = try? String(contentsOf: url, encoding: .utf8) else { return nil }
      return (language: language, source: source)
    }
    guard description != nil || !codeSamples.isEmpty else { return nil }
    return AlgorithmDetailContent(description: description, codeSamples: codeSamples)
  }
}
