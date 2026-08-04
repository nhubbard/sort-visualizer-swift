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
    var result = AttributedString()
    for run in runs {
      var piece = AttributedString(parsed[run.range])
      if let codeMode = run.code {
        piece.mergeAttributes(applyTextFormat(theme.getFormat(token: codeMode)))
      }
      result += piece
    }
    return result
  }
}
