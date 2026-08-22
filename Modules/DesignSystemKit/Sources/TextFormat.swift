import SwiftUI

/// The per-token styling every `CodeTheme` produces, applied to an `AttributedString` run via
/// `applyTextFormat(_:)` below. A plain, defaulted struct — themes construct it directly
/// (`TextFormat(fg: keyword, bold: true)`) rather than through a builder.
public struct TextFormat {
  public var fg: Color = .white
  public var bg: Color = .black
  public var bold: Bool = false
  public var italic: Bool = false
  public var underline: Bool = false

  public init(
    fg: Color = .white, bg: Color = .black, bold: Bool = false, italic: Bool = false,
    underline: Bool = false
  ) {
    self.fg = fg
    self.bg = bg
    self.bold = bold
    self.italic = italic
    self.underline = underline
  }
}

private typealias UIAttr = AttributeScopes.SwiftUIAttributes
private typealias UIForeground = UIAttr.ForegroundColorAttribute
private typealias UIBackground = UIAttr.BackgroundColorAttribute
private typealias UIFont = UIAttr.FontAttribute
private typealias UIUnderline = UIAttr.UnderlineStyleAttribute

public func applyTextFormat(_ format: TextFormat) -> AttributeContainer {
  let baseFont: Font = .system(size: 12, weight: .regular, design: .monospaced)
  var container = AttributeContainer()
  container[UIForeground.self] = format.fg
  container[UIBackground.self] = format.bg
  if format.bold && !format.italic {
    container[UIFont.self] = baseFont.bold()
  } else if !format.bold && format.italic {
    container[UIFont.self] = baseFont.italic()
  } else if format.bold && format.italic {
    container[UIFont.self] = baseFont.bold().italic()
  } else {
    container[UIFont.self] = baseFont
  }
  if format.underline {
    container[UIUnderline.self] = .single
  }
  return container
}
