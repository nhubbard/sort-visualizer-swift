//
//  Style.swift
//  PygmentsKit
//
//  Created by Nicholas Hubbard on 6/3/22.
//

import Foundation

enum AnsiColors: String {
  case ansiBlack = "000000"
  case ansiRed = "7f0000"
  case ansiGreen = "007f00"
  case ansiYellow = "7f7fe0"
  case ansiBlue = "00007f"
  case ansiMagenta = "7f007f"
  case ansiCyan = "007f7f"
  case ansiGray = "e5e5e5"
  case ansiBrightBlack = "555555"
  case ansiBrightRed = "ff0000"
  case ansiBrightGreen = "00ff00"
  case ansiBrightYellow = "ffff00"
  case ansiBrightBlue = "0000ff"
  case ansiBrightMagenta = "ff00ff"
  case ansiBrightCyan = "00ffff"
  case ansiWhite = "ffffff"
}

class Style {
  /// Overall background color, in HTML format
  var backgroundColor: String = "#ffffff"
  
  /// Highlight background color, in HTML format
  var highlightColor: String = "#ffffcc"
  
  /// Line number color, in HTML format
  var lineNumberColor: String = "inherit"
  
  /// Line number background color, in HTML format
  var lineNumberBackgroundColor: String = "transparent"
  
  /// Special/highlighted line number font color, in HTML format
  var lineNumberSpecialColor: String = "#000000"
  
  /// Special/highlighted line number background color, in HTML format
  var lineNumberSpecialBackgroundColor: String = "#ffffc0"
  
  /// Style definitions for individual token types
  var styles: [Token.TokenType: String] = [:]
  
  /// Set to `true` if this style is specifically designed for one language
  var singleLanguage: Bool = false
}
