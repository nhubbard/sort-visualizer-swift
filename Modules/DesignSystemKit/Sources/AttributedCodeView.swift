import SwiftUI

/// Ported from `Legacy/Shared/Views/Code/AttributedCodeView.swift`'s `AttributedCode` — renamed to
/// avoid colliding with the type named `Code` elsewhere, and taking its theme as an explicit
/// parameter (driven by `AppSettings.codeTheme`) instead of reading `@AppStorage("sortCodeViewTheme")`
/// directly, since `DesignSystemKit` shouldn't own that persistence decision.
public struct AttributedCodeView: View {
  private let attributedString: AttributedString
  private let backgroundColor: Color

  /// Callers should precompute via `CodeHighlighter.highlight(_:theme:)` (now `async`, since large
  /// sources divide-and-conquer across `Task`s) and pass the result here, so the work happens once
  /// per sample rather than on every SwiftUI body evaluation.
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
      .drawingGroup()
      .textSelection(.enabled)
  }
}
