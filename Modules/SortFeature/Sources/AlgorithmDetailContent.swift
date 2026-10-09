import DesignSystemKit
import Foundation

/// One algorithm's optional description + per-language code samples, loaded from
/// `AlgorithmDetails.algz` via `AlgorithmDetailStore`. Not every algorithm has this content;
/// missing content loads as `nil`, which `AlgorithmDetailSection` renders as a placeholder rather
/// than a blank/broken view.
struct AlgorithmDetailContent: Sendable {
  let description: String?
  let codeSamples: [(language: CodeLanguage, source: String)]
  let localizedDescriptions: [String: String]

  init(
    description: String?, codeSamples: [(language: CodeLanguage, source: String)],
    localizedDescriptions: [String: String] = [:]
  ) {
    self.description = description
    self.codeSamples = codeSamples
    self.localizedDescriptions = localizedDescriptions
  }

  static func load(for algorithmID: String) async -> AlgorithmDetailContent? {
    await AlgorithmDetailStore.shared.content(for: algorithmID)
  }
}
