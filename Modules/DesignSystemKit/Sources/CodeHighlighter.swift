import SettingsKit
import SwiftUI

/// The actual highlighting work `AttributedCodeView.init` used to do inline on every SwiftUI body
/// evaluation — split out so a caller juggling several samples (`AlgorithmDetailSection`'s language
/// picker) can run it once, off the main actor, and cache the result instead of re-parsing and
/// re-styling from scratch on every render.
public enum CodeHighlighter {
  /// Below this many tokenized runs, splitting into concurrent chunks costs more in `Task`
  /// scheduling overhead than it saves — chunking only pays off past a few hundred runs, per
  /// benchmark.
  private static let minimumChunkSize = 500

  private static let cache = HighlightCache()

  /// Cached wrapper around `highlight(_:theme:)`, keyed by `(source, themeID)` — resolves
  /// `themeID.makeTheme()` itself so callers never need to hold a resolved `any CodeTheme`
  /// instance just to ask "have we already highlighted this."
  ///
  /// This is the fix for the *other* half of what a real Full Sweep profiling run turned up:
  /// `ContentView`'s `.id(...)` includes `SortCoordinator.runToken`, which bumps on every single
  /// `runSort` call — including same-algorithm-different-shuffle-or-visualizer combos — so
  /// `AlgorithmDetailSection` (and its `.task` that highlights every language sample) remounts
  /// from scratch on *every* Full Sweep combo, not just once per algorithm change. Without this
  /// cache, the exact same unchanged source was being re-highlighted roughly once a second for the
  /// entire sweep. `styles`/`defaultFormat` being cheap now (see `highlightRuns`/`Color(rgba:)`)
  /// helps every call; this stops the vast majority of those calls from happening at all.
  public static func highlight(_ source: String, themeID: CodeThemeID) async -> AttributedString {
    let key = HighlightCache.Key(source: source, themeID: themeID)
    if let cached = await cache.value(for: key) { return cached }
    let result = await highlight(source, theme: themeID.makeTheme())
    await cache.store(result, for: key)
    return result
  }

  public static func highlight(_ source: String, theme: any CodeTheme) async -> AttributedString {
    let parsed = AttributedString(
      localized: String.LocalizationValue(source), including: \.sortSymphonyApp)
    let runs = Array(parsed.runs)
    guard runs.count > minimumChunkSize else {
      return highlightRuns(runs, in: parsed, theme: theme)
    }

    let chunkCount = min(
      ProcessInfo.processInfo.activeProcessorCount, max(1, runs.count / minimumChunkSize))
    let chunkSize = (runs.count + chunkCount - 1) / chunkCount
    let chunkBounds = stride(from: 0, to: runs.count, by: chunkSize)
      .map { $0..<min($0 + chunkSize, runs.count) }

    let ordered = await withTaskGroup(of: (Int, AttributedString).self) { group in
      for (index, bounds) in chunkBounds.enumerated() {
        let chunkRuns = Array(runs[bounds])
        group.addTask { (index, highlightRuns(chunkRuns, in: parsed, theme: theme)) }
      }
      var pieces = [AttributedString?](repeating: nil, count: chunkBounds.count)
      for await (index, piece) in group { pieces[index] = piece }
      return pieces.compactMap { $0 }
    }

    var combined = AttributedString()
    for piece in ordered { combined += piece }
    return combined
  }

  /// Copies each already-tokenized run out of `parsed` and re-styles the copy, then
  /// concatenates — never mutates a shared, growing `AttributedString` in place. In-place range
  /// mutation of one Rope-backed `AttributedString`, repeated many times, hits a real Foundation
  /// bug: `_prepareModify`'s path-splitting recurses without bound and reliably stack-overflows
  /// past a few thousand mutations. Concatenation sidesteps it entirely and, as a bonus,
  /// auto-coalesces adjacent runs that resolve to the same `TextFormat`.
  private static func highlightRuns(
    _ runs: some Collection<AttributedString.Runs.Element>, in parsed: AttributedString,
    theme: any CodeTheme
  ) -> AttributedString {
    // `theme.styles`/`theme.defaultFormat` are computed properties, not stored ones — required by
    // `CodeTheme: Sendable` since `TextFormat` wraps `Color`, which isn't `Sendable` (see
    // `CodeThemeTests.StubTheme`'s own doc comment). A generated theme's `styles` rebuilds its
    // whole per-theme dictionary on every access, so calling `theme.getFormat(token:)` once per
    // run — as this used to — re-read (and, before `Color(rgba:)`, re-parsed every hex literal
    // in) that dictionary once per *token*. Fetching both once here, outside the loop, is the
    // other half of the fix a real Full Sweep profiling run's findings pointed at: turns an
    // O(tokens) cost into O(1) per highlight pass regardless of source length.
    let styles = theme.styles
    let defaultFormat = theme.defaultFormat
    var result = AttributedString()
    for run in runs {
      var piece = AttributedString(parsed[run.range])
      if let codeMode = run.code {
        piece.mergeAttributes(
          applyTextFormat(resolvedFormat(for: codeMode, styles: styles, defaultFormat: defaultFormat)))
      }
      result += piece
    }
    return result
  }

  /// The same ancestor-walk `CodeTheme.getFormat(token:)`'s default implementation does —
  /// duplicated here (rather than calling `getFormat` and re-reading `theme.styles` on every
  /// call) so `highlightRuns` can walk a single already-fetched `styles` snapshot for every token
  /// in the source instead of one fresh snapshot per token.
  private static func resolvedFormat(
    for token: CodeAttributes.Value, styles: [CodeAttributes.Value: TextFormat],
    defaultFormat: TextFormat
  ) -> TextFormat {
    var current: CodeAttributes.Value? = token
    while let candidate = current {
      if let format = styles[candidate] { return format }
      current = candidate.parent
    }
    return defaultFormat
  }
}

/// `CodeHighlighter.highlight(_:themeID:)` is called concurrently — `AlgorithmDetailSection`
/// fires one call per language inside a `withTaskGroup` — so the cache backing it needs real
/// synchronization, not a plain `static var`. An `actor` is automatically `Sendable`, so holding
/// one in a `static let` needs no `nonisolated(unsafe)` opt-out.
///
/// Internal rather than `private` so `CodeHighlighterTests` can exercise its get/set semantics
/// directly against a fresh instance, instead of asserting on `CodeHighlighter`'s shared
/// process-lifetime singleton — that singleton accumulates entries from every test that touches
/// `highlight(_:themeID:)`, which under Swift Testing's parallel-by-default execution makes any
/// assertion based on its total size flaky (concurrent unrelated tests add entries between two
/// calls in the same test).
actor HighlightCache {
  struct Key: Hashable {
    let source: String
    let themeID: CodeThemeID
  }

  private var storage: [Key: AttributedString] = [:]

  func value(for key: Key) -> AttributedString? { storage[key] }
  func store(_ value: AttributedString, for key: Key) { storage[key] = value }
}
