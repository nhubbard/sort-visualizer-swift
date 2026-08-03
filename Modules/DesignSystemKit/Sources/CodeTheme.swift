import SwiftUI

/// A theme declares only the tokens it actually wants to style, sparsely, plus a fallback for
/// everything else — `getFormat(token:)` below walks `token.parent` (`CodeAttributes.swift`)
/// until it finds an explicit entry in `styles`, the same cascade Pygments itself uses to resolve
/// a token's style from its nearest styled ancestor. This replaced a per-theme `switch` over every
/// leaf case (and the `Then`-based builder used to construct each branch) — see
/// `Modules/DesignSystemKit/Sources/Themes/*.swift`.
public protocol CodeTheme: Sendable {
  func getBgColor() -> Color
  var styles: [CodeAttributes.Value: TextFormat] { get }
  var defaultFormat: TextFormat { get }
}

extension CodeTheme {
  public func getFormat(token: CodeAttributes.Value) -> TextFormat {
    var current: CodeAttributes.Value? = token
    while let candidate = current {
      if let format = styles[candidate] { return format }
      current = candidate.parent
    }
    return defaultFormat
  }
}
