import CryptoKit
import Foundation
import os
import ZstdKit

/// Lazily decodes `AlgorithmDetails.algz` once per process and shares the result — replaces
/// `AlgorithmDetailContent.load(for:)`'s old per-algorithm loose-file bundle reads. See
/// `COMPRESSION_AND_STRETCH_GOALS_PLAN.md`'s "Runtime: a lazily-decoded singleton".
///
/// `bundle` defaults to `.main` but is injectable so tests can point this at their own test
/// bundle instead — mirrors `ZstdKit`'s own `Fixture.bundle = Bundle(for: FixtureBundleMarker.self)`
/// pattern.
/// Fire-and-forget: kicks off `AlgorithmDetailStore`'s one-time archive decode as early as
/// possible in the app's lifecycle (e.g. from the app's `init()`), so it has a chance to finish
/// before the user reaches an `AlgorithmDetailSection`. `AlgorithmDetailStore` itself stays
/// module-internal; this is the one entry point the app needs.
public func prewarmAlgorithmDetails() {
  Task { await AlgorithmDetailStore.shared.prewarm() }
}

actor AlgorithmDetailStore {
  static let shared = AlgorithmDetailStore()

  private let bundle: Bundle
  private var loadTask: Task<[String: AlgorithmDetailContent], Error>?

  init(bundle: Bundle = .main) {
    self.bundle = bundle
  }

  /// Kicks off the decode without waiting on a specific algorithm's content — call this as early
  /// as possible (e.g. app launch) so the ~1.5s first-ever decode of the real archive has a chance
  /// to finish before the user reaches an `AlgorithmDetailSection`, instead of only starting when
  /// one first appears.
  func prewarm() {
    _ = Task { try? await load() }
  }

  func content(for algorithmID: String) async -> AlgorithmDetailContent? {
    do {
      let all = try await load()
      return all[algorithmID]
    } catch {
      Self.logger.error(
        "AlgorithmDetailStore failed to load AlgorithmDetails.algz: \(String(describing: error), privacy: .public)"
      )
      return nil
    }
  }

  /// `if let loadTask`/`loadTask = task` both happen before this function's only suspension point
  /// (`await task.value`), so every concurrent caller either starts the one decode or awaits the
  /// same already-in-flight `Task` — never a duplicate decompression.
  private func load() async throws -> [String: AlgorithmDetailContent] {
    if let loadTask { return try await loadTask.value }
    let bundle = self.bundle
    let task = Task { try Self.decodeArchive(bundle: bundle) }
    loadTask = task
    return try await task.value
  }

  private static let logger = Logger(subsystem: "com.nhubbard.Sort2.mobile", category: "AlgorithmDetailStore")

  private static func decodeArchive(bundle: Bundle) throws -> [String: AlgorithmDetailContent] {
    guard let url = bundle.url(forResource: "AlgorithmDetails", withExtension: "algz") else {
      throw AlgorithmDetailsArchiveError.archiveResourceNotFound
    }
    let archiveData = try Data(contentsOf: url)
    let archiveBytes = [UInt8](archiveData)

    let envelope = try AlgorithmDetailsEnvelope.parse(archiveBytes)
    let frameBytes = Array(archiveBytes[envelope.frameRange])
    let decompressed = try Zstd.decompress(Data(frameBytes))
    guard decompressed.count == envelope.decompressedLength else {
      throw AlgorithmDetailsArchiveError.invalidSectionRange
    }

    let digest = SHA256.hash(data: decompressed)
    guard Array(digest) == envelope.sha256 else {
      throw AlgorithmDetailsArchiveError.hashMismatch
    }

    let payloadBytes = [UInt8](decompressed)
    let manifest = try AlgorithmDetailsManifest.parse(payloadBytes)
    return try manifest.buildContentDictionary(payload: payloadBytes)
  }
}
