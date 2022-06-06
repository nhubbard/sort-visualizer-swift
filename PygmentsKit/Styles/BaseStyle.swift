//
//  BaseStyle.swift
//  PygmentsKit
//
//  Created by Nicholas Hubbard on 6/3/22.
//

import Foundation
import SwiftUI
import Then

/**
 * Mapping of styles by name.
 */
enum StyleMap: String, CaseIterable {
  case defaultStyle = "default"
  case dracula = "dracula"
  case material = "material"
  case monokai = "monokai"
  case solarizedLight = "solarizedLight"
  case solarizedDark = "solarizedDark"
  
  /**
   * Attempt to get a style by name. If the style does not exist, returns `.defaultStyle`.
   */
  static func getByName(styleName: String) -> StyleMap {
    for style in StyleMap.allCases {
      if style.rawValue == styleName {
        return style
      }
    }
    return .defaultStyle
  }
  
  /**
   * Get the actual style from an enum entry.
   */
  func get() -> BaseStyle {
    switch self {
      case .defaultStyle:
        return DefaultStyle()
      case .dracula:
        return DraculaStyle()
      case .material:
        return MaterialStyle()
      case .monokai:
        return MonokaiStyle()
      case .solarizedLight:
        return SolarizedLightStyle()
      case .solarizedDark:
        return SolarizedDarkStyle()
    }
  }
}

/**
 * A structure representing the text formatting to use on a `Text` SwiftUI view.
 */
struct TextFormat {
  var fg: Color = .white
  var bg: Color = .black
  var border: Color? = nil
  var bold: Bool = false
  var italic: Bool = false
  var underline: Bool = false
}

/**
 * A builder for TextFormat to make style definitions more readable.
 */
extension TextFormat {
  class Builder {
    private var _bg: Color
    private var _fg: Color = .white
    private var _border: Color? = nil
    private var _bold: Bool = false
    private var _italic: Bool = false
    private var _underline: Bool = false
    
    init(_ bg: Color) {
      self._bg = bg
    }
    
    @discardableResult
    func fg(_ fg: UInt = 0xffffff) -> TextFormat.Builder {
      self._fg = Color(hex: fg)
      return self
    }
    
    @discardableResult
    func bg(_ bg: UInt = 0xffffff) -> TextFormat.Builder {
      self._bg = Color(hex: bg)
      return self
    }
    
    @discardableResult
    func border(_ bd: UInt = 0xffffff) -> TextFormat.Builder {
      self._border = Color(hex: bd)
      return self
    }
    
    @discardableResult
    func bold() -> TextFormat.Builder {
      // SwiftUI limitation: bold and italic is really hard.
      if self._italic {
        self._italic = false
      }
      self._bold = true
      return self
    }
    
    @discardableResult
    func italic() -> TextFormat.Builder {
      // SwiftUI limitation: bold and italic is really hard.
      if self._bold {
        self._bold = false
      }
      self._italic = true
      return self
    }
    
    @discardableResult
    func underline() -> TextFormat.Builder {
      self._underline = true
      return self
    }
    
    func build() -> TextFormat {
      return TextFormat(fg: _fg, bg: _bg, border: _border, bold: _bold, italic: _italic, underline: _underline)
    }
  }
  
  static func getBuilder(bg: Color) -> Builder {
    return TextFormat.Builder(bg)
  }
  
  static func getBuilder(hexBg: UInt) -> Builder {
    return self.getBuilder(bg: Color(hex: hexBg))
  }
}

extension TextFormat.Builder: Then {
  var final: TextFormat {
    get {
      return self.build()
    }
  }
}

protocol BaseStyle {
  /// The name of the style.
  var name: String { get }
  
  /// Overall background color, in HTML format
  var backgroundColor: Color { get }
  
  /// Get a `TextFormat` definition for the style of a specific `TokenType`.
  func getStyle(tokenType: Token.TokenType) -> TextFormat
}
