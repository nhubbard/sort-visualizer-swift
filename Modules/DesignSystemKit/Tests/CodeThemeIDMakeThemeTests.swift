import SettingsKit
import SwiftUI
import Testing

@testable import DesignSystemKit

/// The single highest-leverage test in the module: most of `DesignSystemKit`'s line count is the
/// 49 generated `Themes/*.swift` data files, and each one's `styles` dictionary literal only
/// counts as "covered" once it's actually constructed and read at runtime. Looping over every
/// known theme ID exercises all of them at once, while still asserting a real invariant per theme
/// rather than just "doesn't crash": every theme must provide genuine color differentiation
/// (not every theme styles the base `.token` case directly — most only style specific leaf
/// tokens like `.keyword`/`.string` and rely on `defaultFormat` for everything else — so a
/// theme that's accidentally empty or collapses to one flat color everywhere is the real bug
/// this catches).
@Suite
struct CodeThemeIDMakeThemeTests {
  private struct FormatSignature: Hashable {
    let fg: Color
    let bg: Color
    let bold: Bool
    let italic: Bool
    let underline: Bool

    init(_ format: TextFormat) {
      fg = format.fg
      bg = format.bg
      bold = format.bold
      italic = format.italic
      underline = format.underline
    }
  }

  @Test
  func everyKnownThemeProvidesGenuineStyleDifferentiation() {
    for id in CodeThemeID.knownIDs {
      let theme = id.makeTheme()
      #expect(!theme.styles.isEmpty, "\(id.rawValue) has an empty styles dictionary")
      let signatures = Set(
        theme.styles.values.map(FormatSignature.init) + [FormatSignature(theme.defaultFormat)])
      // A theme like Pygments' "bw" is intentionally monochrome (every color is black-on-white)
      // but still differentiates tokens via bold/italic — fg/bg alone would false-positive here.
      #expect(
        signatures.count > 1,
        "\(id.rawValue) doesn't differentiate any token's style from its own default")
    }
  }

  @Test
  func unknownRawValueFallsBackToMonokai() {
    let theme = CodeThemeID(rawValue: "not-a-real-theme").makeTheme()
    #expect(theme is MonokaiTheme)
  }

  @Test
  func aFewKnownIDsResolveToTheirExpectedConcreteThemeType() {
    #expect(CodeThemeID(rawValue: "monokai").makeTheme() is MonokaiTheme)
    #expect(CodeThemeID(rawValue: "dracula").makeTheme() is DraculaTheme)
    #expect(CodeThemeID(rawValue: "one-dark").makeTheme() is OneDarkTheme)
    #expect(CodeThemeID(rawValue: "xcode").makeTheme() is XcodeTheme)
  }
}
