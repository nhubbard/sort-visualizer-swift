//
//  Formatter.swift
//  Sort2 (iOS)
//
//  Created by Nicholas Hubbard on 6/3/22.
//

import Foundation

enum Style: String, CaseIterable {
  case abap = "abap"
  case algol = "algol"
  case algolNu = "algol_nu"
  case arduino = "arduino"
  case autumn = "autumn"
  case borland = "borland"
  case bw = "bw"
  case colorful = "colorful"
  case `default` = "default"
  case dracula = "dracula"
  case emacs = "emacs"
  case friendly = "friendly"
  case friendlyGrayscale = "friendly_grayscale"
  case fruity = "fruity"
  case gruvbox = "gruvbox"
  case igor = "igor"
  case inkpot = "inkpot"
  case lilypond = "lilypond"
  case lovelace = "lovelace"
  case manni = "manni"
  case material = "material"
  case monokai = "monokai"
  case murphy = "murphy"
  case native = "native"
  case onedark = "onedark"
  case paraisoDark = "paraiso_dark"
  case paraisoLight = "paraiso_light"
  case pastie = "pastie"
  case perldoc = "perldoc"
  case rainbowDash = "rainbow_dash"
  case rrt = "rrt"
  case sas = "sas"
  case solarized = "solarized"
  case stataDark = "stata_dark"
  case stataLight = "stata_light"
  case tango = "tango"
  case trac = "trac"
  case vim = "vim"
  case vs = "vs"
  case xcode = "xcode"
  case zenburn = "zenburn"
}

func _lookupStyle(styleName: String) -> Style? {
  for style in Style.allCases {
    if style.rawValue == styleName {
      return style
    }
  }
  return nil
}

/**
 * A Formatter converts a token stream to a specific form of output.
 *
 * Accepts the following options:
 *
 * - Parameter T: The type of output the formatter will produce. Only exists to allow for SwiftUI/AppKit/UIKit views alongside text output.
 * - Parameter name: The primary name of the formatter.
 * - Parameter style: The style to use. Can be a string (which will be looked up) or a `Style` enum case. Defaults to `Style.default`.
 * - Parameter full: Tells the formatter to output a "full" document, essentially a complete, self-contained document. Defaults to `false`.
 * - Parameter title: If `full` is true, the title that should be used to caption the document. Defaults to empty string.
 * - Parameter inputEncoding: If given, this is the encoding used by the tokens. Defaults to `String.Encoding.utf8`.
 * - Parameter outputEncoding: If given, this is the encoding to be used in the output. Defaults to `String.Encoding.utf8`.
 * - Parameter aliases: Other names this formatter goes by. Defaults to empty array.
 * - Parameter filenames: An array of filename match rules. Defaults to empty array. Unknown type; don't use yet!
 */
class Formatter<T : Any> {
  /// The name of the formatter.
  var name: String
  
  /// The style to use by the formatter.
  var style: Style
  
  /// Whether or not to use full formatting.
  var full: Bool
  
  /// The title to use if full formatting is enabled.
  var title: String
  
  /// The encoding to accept as input.
  var inputEncoding: String.Encoding = .utf8
  
  /// The encoding to produce as output.
  var outputEncoding: String.Encoding = .utf8
  
  /// Aliases the formatter goes by.
  var aliases: [String] = []
  
  /// File names that this formatter matches.
  // TODO: Check the return type of this variable.
  var filenames: [Any] = []
  
  init(
    name: String,
    style: Style = .default,
    full: Bool = false,
    title: String = "",
    inputEncoding: String.Encoding = .utf8,
    outputEncoding: String.Encoding = .utf8,
    aliases: [String] = [],
    filenames: [Any] = []
  ) {
    self.name = name
    self.style = style
    self.full = full
    self.title = title
    self.inputEncoding = inputEncoding
    self.outputEncoding = outputEncoding
    self.aliases = aliases
    self.filenames = filenames
  }
  
  // TODO: func getStyleDefs(arg: String = "")
  // TODO: func format(tokenSource: InputStream, output: T)
  // TODO: Other functions?
}
