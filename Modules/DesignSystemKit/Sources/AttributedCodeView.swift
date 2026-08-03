import SwiftUI

/// Ported from `Legacy/Shared/Views/Code/AttributedCodeView.swift`'s `AttributedCode` — renamed to
/// avoid colliding with the type named `Code` elsewhere, and taking its theme as an explicit
/// parameter (driven by `AppSettings.codeTheme`) instead of reading `@AppStorage("sortCodeViewTheme")`
/// directly, since `DesignSystemKit` shouldn't own that persistence decision.
public struct AttributedCodeView: View {
  private let attributedString: AttributedString
  private let backgroundColor: Color

  /// Highlights `source` inline — fine for a one-off render, but callers juggling several samples
  /// per render pass (a language picker) should precompute via `CodeHighlighter.highlight(_:theme:)`
  /// and use `init(attributed:backgroundColor:)` instead, so the work happens once per sample
  /// rather than on every SwiftUI body evaluation.
  public init(_ source: String, theme: any CodeTheme) {
    self.init(attributed: CodeHighlighter.highlight(source, theme: theme), backgroundColor: theme.getBgColor())
  }

  public init(attributed: AttributedString, backgroundColor: Color) {
    self.attributedString = attributed
    self.backgroundColor = backgroundColor
  }

  public var body: some View {
    Text(attributedString)
      .padding()
      .fixedSize(horizontal: true, vertical: true)
      .background(backgroundColor)
      .cornerRadius(15)
      .textSelection(.enabled)
  }
}
