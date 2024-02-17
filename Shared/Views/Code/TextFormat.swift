//
//  TextFormat.swift
//  Sort Symphony (iOS)
//
//  Created by Nicholas Hubbard on 6/24/22.
//

import Foundation
import SwiftUI
import Then

/**
 * A structure representing the text formatting to use on a `Text` SwiftUI view.
 */
@frozen public struct TextFormat {
  public var fg: Color = .white
  public var bg: Color = .black
  public var bold: Bool = false
  public var italic: Bool = false
  public var underline: Bool = false
}

/**
 * A builder for TextFormat to make style definitions more readable.
 */
extension TextFormat {
  class Builder {
    private var _bg: Color
    private var _fg: Color = .white
    private var _bold: Bool = false
    private var _italic: Bool = false
    private var _underline: Bool = false

    init(_ bg: Color) {
      _bg = bg
    }

    @discardableResult
    func fg(_ fg: String = "#FFFFFF") -> TextFormat.Builder {
      _fg = Color(fromHex: fg)!
      return self
    }

    @discardableResult
    func fg(_ fg: Color = .white) -> TextFormat.Builder {
      _fg = fg
      return self
    }

    @discardableResult
    func bg(_ bg: String = "#FFFFFF") -> TextFormat.Builder {
      _bg = Color(fromHex: bg)!
      return self
    }

    @discardableResult
    func bg(_ bg: Color = .white) -> TextFormat.Builder {
      _bg = .white
      return self
    }

    @discardableResult
    func bold() -> TextFormat.Builder {
      // SwiftUI limitation: bold and italic is really hard.
      if _italic {
        _italic = false
      }
      _bold = true
      return self
    }

    @discardableResult
    func italic() -> TextFormat.Builder {
      // SwiftUI limitation: bold and italic is really hard.
      if _bold {
        _bold = false
      }
      _italic = true
      return self
    }

    @discardableResult
    func underline() -> TextFormat.Builder {
      _underline = true
      return self
    }

    func build() -> TextFormat {
      TextFormat(fg: _fg, bg: _bg, bold: _bold, italic: _italic, underline: _underline)
    }
  }

  static func getBuilder(bg: Color) -> Builder {
    TextFormat.Builder(bg)
  }

  static func getBuilder(hexBg: String) -> Builder {
    self.getBuilder(bg: Color(fromHex: hexBg)!)
  }
}

extension TextFormat.Builder: Then {
  var final: TextFormat {
    build()
  }
}

private typealias UIAttr = AttributeScopes.SwiftUIAttributes
private typealias UIForeground = UIAttr.ForegroundColorAttribute
private typealias UIBackground = UIAttr.BackgroundColorAttribute
private typealias UIFont = UIAttr.FontAttribute
private typealias UIUnderline = UIAttr.UnderlineStyleAttribute

func applyTextFormat(_ format: TextFormat) -> AttributeContainer {
  let baseFont: Font = .system(size: 12, weight: .regular, design: .monospaced)
  var container = AttributeContainer()
  container[UIForeground.self] = format.fg
  container[UIBackground.self] = format.bg
  if format.bold && !format.italic {
    container[UIFont.self] =
      baseFont.bold()
  } else if !format.bold && format.italic {
    container[UIFont.self] =
      baseFont.italic()
  } else if format.bold && format.italic {
    container[UIFont.self] =
      baseFont.bold().italic()
  } else {
    container[UIFont.self] = baseFont
  }
  if format.underline {
    container[UIUnderline.self] = .single
  }
  return container
}
