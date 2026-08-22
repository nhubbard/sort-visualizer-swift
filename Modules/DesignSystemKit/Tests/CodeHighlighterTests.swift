import SettingsKit
import SwiftUI
import Testing

@testable import DesignSystemKit

/// Guards against a real Foundation bug: repeatedly calling `mergeAttributes` on subranges of one
/// growing `AttributedString` (the old implementation) recurses without bound in the Rope-backed
/// storage's `_prepareModify` and reliably stack-overflows past a few thousand mutations — a count
/// a large algorithm's per-token-styled source (e.g. the PDQ family) plausibly reaches. The fix
/// (build via concatenation, chunked across `Task`s past `CodeHighlighter`'s internal threshold)
/// is what these tests exercise.
@Suite
struct CodeHighlighterTests {
  private func makeSource(tokenCount: Int) -> String {
    (0..<tokenCount).map { index in
      let tokenType = index.isMultiple(of: 2) ? "Token.Keyword" : "Token.Literal.String"
      return "^[tok\(index)](code: '\(tokenType)') "
    }.joined()
  }

  @Test
  func largeSourceHighlightsWithoutCrashingAndPreservesText() async {
    let tokenCount = 4000
    let source = makeSource(tokenCount: tokenCount)
    let result = await CodeHighlighter.highlight(source, theme: MonokaiTheme())
    let expectedPlainText = (0..<tokenCount).map { "tok\($0) " }.joined()
    #expect(String(result.characters) == expectedPlainText)
    #expect(result.runs.count > 0)
  }

  @Test
  func smallSourceAppliesThemeColorsPerToken() async throws {
    let source = makeSource(tokenCount: 10)
    let theme = MonokaiTheme()
    let result = await CodeHighlighter.highlight(source, theme: theme)

    #expect(String(result.characters) == (0..<10).map { "tok\($0) " }.joined())

    let codedRuns = result.runs.filter { $0.code != nil }
    #expect(codedRuns.isEmpty == false)
    for run in codedRuns {
      let token = try #require(run.code)
      let expectedColor = theme.getFormat(token: token).fg
      let actualColor = run.attributes[AttributeScopes.SwiftUIAttributes.ForegroundColorAttribute.self]
      #expect(actualColor == expectedColor)
    }
  }

  @Test
  func chunkedAndSingleChunkPathsAgreeOnSharedPrefix() async {
    let smallCount = 20
    let largeCount = 4000
    let theme = MonokaiTheme()

    let smallResult = await CodeHighlighter.highlight(makeSource(tokenCount: smallCount), theme: theme)
    let largeResult = await CodeHighlighter.highlight(makeSource(tokenCount: largeCount), theme: theme)

    let smallPlain = String(smallResult.characters)
    let largePrefix = String(largeResult.characters.prefix(smallPlain.count))
    #expect(smallPlain == largePrefix)

    let smallTokens = smallResult.runs.compactMap(\.code)
    let largeTokens = largeResult.runs.compactMap(\.code).prefix(smallTokens.count)
    #expect(smallTokens == Array(largeTokens))
  }

  /// `HighlightCache` is the actual mechanism `highlight(_:themeID:)` relies on to skip
  /// recomputation — tested directly against a fresh instance (not `CodeHighlighter`'s shared
  /// process-lifetime singleton, which accumulates entries from every other test touching
  /// `highlight(_:themeID:)` and would make a size-based assertion flaky under Swift Testing's
  /// parallel-by-default execution).
  @Test
  func highlightCacheStoresAndReturnsByExactKey() async {
    let cache = HighlightCache()
    let key = HighlightCache.Key(source: "let x = 1", themeID: CodeThemeID(rawValue: "monokai"))
    let otherSourceKey = HighlightCache.Key(
      source: "let x = 2", themeID: CodeThemeID(rawValue: "monokai"))
    let otherThemeKey = HighlightCache.Key(source: "let x = 1", themeID: CodeThemeID(rawValue: "dracula"))

    #expect(await cache.value(for: key) == nil)

    let value = AttributedString("styled")
    await cache.store(value, for: key)

    #expect(await cache.value(for: key) == value)
    #expect(await cache.value(for: otherSourceKey) == nil)
    #expect(await cache.value(for: otherThemeKey) == nil)
  }

  /// Regression guard for the Full Sweep finding: `AlgorithmDetailSection` remounts (and
  /// re-highlights every language sample) on every combo, not just every algorithm change.
  /// `highlight(_:themeID:)` itself just needs to keep producing a correct, cache-consistent
  /// result for a repeated `(source, themeID)` pair — the cache-hit mechanics themselves are
  /// covered directly above.
  @Test
  func repeatedThemeIDCallWithTheSameSourceProducesTheSameResult() async {
    let source = makeSource(tokenCount: 10)
    let themeID = CodeThemeID(rawValue: "monokai-cache-test-\(UUID().uuidString)")

    let first = await CodeHighlighter.highlight(source, themeID: themeID)
    let second = await CodeHighlighter.highlight(source, themeID: themeID)

    #expect(String(first.characters) == String(second.characters))
  }

  @Test
  func differentThemeIDsForTheSameSourceCacheSeparately() async {
    let source = makeSource(tokenCount: 10)
    let monokai = CodeThemeID(rawValue: "monokai")
    let dracula = CodeThemeID(rawValue: "dracula")

    let monokaiResult = await CodeHighlighter.highlight(source, themeID: monokai)
    let draculaResult = await CodeHighlighter.highlight(source, themeID: dracula)

    let monokaiColors = Set(monokaiResult.runs.compactMap {
      $0.attributes[AttributeScopes.SwiftUIAttributes.ForegroundColorAttribute.self]
    })
    let draculaColors = Set(draculaResult.runs.compactMap {
      $0.attributes[AttributeScopes.SwiftUIAttributes.ForegroundColorAttribute.self]
    })
    #expect(monokaiColors != draculaColors)
  }

  @Test
  func themeIDOverloadResolvesToTheSameStylingAsTheResolvedThemeOverload() async {
    let source = makeSource(tokenCount: 10)
    let themeID = CodeThemeID(rawValue: "monokai")

    let viaThemeID = await CodeHighlighter.highlight(source, themeID: themeID)
    let viaResolvedTheme = await CodeHighlighter.highlight(source, theme: MonokaiTheme())

    #expect(String(viaThemeID.characters) == String(viaResolvedTheme.characters))
    let idColors = viaThemeID.runs.compactMap {
      $0.attributes[AttributeScopes.SwiftUIAttributes.ForegroundColorAttribute.self]
    }
    let resolvedColors = viaResolvedTheme.runs.compactMap {
      $0.attributes[AttributeScopes.SwiftUIAttributes.ForegroundColorAttribute.self]
    }
    #expect(idColors == resolvedColors)
  }
}
