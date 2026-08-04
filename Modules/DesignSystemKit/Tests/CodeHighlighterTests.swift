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
}
