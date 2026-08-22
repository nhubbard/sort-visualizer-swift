import SwiftUI
import Testing

@testable import DesignSystemKit

/// `TextFormat` isn't `Sendable` (it wraps `Color`), so — matching every real generated
/// `Themes/*.swift` file — `styles`/`defaultFormat` must be computed properties, not stored ones,
/// for this struct to satisfy `CodeTheme: Sendable`. Colors are stored instead and turned into
/// `TextFormat`s on read.
private struct StubTheme: CodeTheme {
  private let fgByToken: [CodeAttributes.Value: Color]
  var styles: [CodeAttributes.Value: TextFormat] {
    fgByToken.mapValues { TextFormat(fg: $0) }
  }
  var defaultFormat: TextFormat { TextFormat(fg: .gray) }

  init(styles: [CodeAttributes.Value: Color]) {
    fgByToken = styles
  }

  func getBgColor() -> Color { .black }
}

@Suite
struct CodeThemeTests {
  @Test
  func exactMatchReturnsItsOwnStyleWithoutWalkingTheParentChain() {
    let theme = StubTheme(styles: [
      .keyword: .red,
      .token: .white
    ])
    #expect(theme.getFormat(token: .keyword).fg == .red)
  }

  @Test
  func unstyledTokenFallsBackToItsNearestStyledAncestor() {
    let theme = StubTheme(styles: [.keyword: .blue])
    // .keywordConstant has no direct style, but its parent .keyword does.
    #expect(theme.getFormat(token: .keywordConstant).fg == .blue)
  }

  @Test
  func fallsAllTheWayToDefaultFormatWhenNoAncestorIsStyled() {
    let theme = StubTheme(styles: [.comment: .green])
    #expect(theme.getFormat(token: .numberIntegerLong).fg == theme.defaultFormat.fg)
  }
}
