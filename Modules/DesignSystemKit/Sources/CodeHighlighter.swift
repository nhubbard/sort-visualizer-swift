import SwiftUI

/// The actual highlighting work `AttributedCodeView.init` used to do inline on every SwiftUI body
/// evaluation — split out so a caller juggling several samples (`AlgorithmDetailSection`'s language
/// picker) can run it once, off the main actor, and cache the result instead of re-parsing and
/// re-styling from scratch on every render.
public enum CodeHighlighter {
  public static func highlight(_ source: String, theme: any CodeTheme) -> AttributedString {
    var attrString = AttributedString(
      localized: String.LocalizationValue(source), including: \.sortSymphonyApp)
    for run in attrString.runs {
      guard let codeMode = run.code else { continue }
      attrString[run.range].mergeAttributes(applyTextFormat(theme.getFormat(token: codeMode)))
    }
    return attrString
  }
}
