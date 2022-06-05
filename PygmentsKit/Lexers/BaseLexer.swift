//
//  BaseLexer.swift
//  PygmentsKit
//
//  Created by Nicholas Hubbard on 6/4/22.
//

import Foundation
import Regex
import RxSwift

typealias UnprocessedToken = (String.Index, Token.TokenType, String)

/**
 * The base lexer for any language.
 *
 * - Parameter name: The name of the lexer. Required.
 * - Parameter url: The URL pointing to the language specification. Defaults to empty string.
 * - Parameter aliases: An array of alias names for the lexer. Defaults to empty array.
 * - Parameter filenames: An array of file name globs to match with this lexer. Required.
 * - Parameter aliasFilenames: An array of alias filenames to match with this lexer. Defaults to empty array.
 * - Parameter mimetypes: An array of MIME types this lexer can lex. Required.
 * - Parameter priority: If multiple lexers match and no content is provided, use this to rank. Defaults to `0`.
 * - Parameter stripNewlines: Whether to strip newlines. Defaults to `true`.
 * - Parameter stripAll: Whether to strip all spacing. Defaults to `false`.
 * - Parameter ensureNewlines: Whether to ensure newlines are present. Defaults to `true`.
 * - Parameter tabSize: The size of tabs to use. Defaults to `2`.
 */
class BaseLexer {
  /// Name of the lexer.
  var name: String = ""
  
  /// URL of the language specification/definition.
  var url: String = ""
  
  /// Shortcuts for the lexer.
  var aliases: [String] = []
  
  /// File name globs
  var filenames: [String] = []
  
  /// Secondary file name globs
  var aliasFilenames: [String] = []
  
  /// Mime types
  var mimetypes: [String] = []
  
  /// Priority, should multiple lexers match and no content is provided.
  var priority: Int = 0
  
  /// Should we strip newlines out?
  var stripNewlines: Bool = true
  
  /// Should we strip all spacing out?
  var stripAll: Bool = false
  
  /// Should we ensure there are newlines?
  var ensureNewlines: Bool = true
  
  /// Tab size
  var tabSize: Int = 2
  
  /**
   * Return a float between 0 and 1 indicating the confidence of the lexer in highlighting the text. 0 means 'will not highlight', 1 means 'guaranteed to highlight'.
   *
   * In subclasses, implementing this function is **required**.
   */
  static func analyzeText(text: String) -> Float {
    preconditionFailure("This function must be implemented by the child class.")
  }
  
  /**
   * Return an iterable of (index, tokentype, value) pairs where "index" is the starting position of the token within the input text.
   * If `unfiltered` is set to true, the filtering mechanism is bypassed even if filters are defined.
   */
  func getTokens(text: String, unfiltered: Bool = false) async throws -> [Token] {
    // Replace CRLF and CR with LF.
    var _text: String = text.replacingOccurrences(of: "\r\n", with: "\n")
    _text = _text.replacingOccurrences(of: "\r", with: "\n")
    // Decide whether to trim whitespace+newlines or just newlines.
    if stripAll {
      _text = _text.trimmingCharacters(in: .whitespacesAndNewlines)
    } else if stripNewlines {
      _text = _text.trimmingCharacters(in: .newlines)
    }
    // Expand tabs if there are any tab characters in the text.
    if tabSize > 0 && _text.contains("\t") {
      _text = _text.replacingOccurrences(of: "\t", with: String(repeating: " ", count: tabSize))
    }
    if ensureNewlines && _text.last != Character("\n") {
      _text += "\n"
    }
    return try await self.getTokensUnprocessed(text: _text).map { token in
      Token(type: token.1, value: token.2)
    }.toArray().value
  }
  
  /**
   * Return an `Observable` of (`index`, `tokenType`, `value`) tuples where `index`
   * is the starting position of the token within the input text.
   *
   * In subclasses, implementing this function is **required**.
   */
  func getTokensUnprocessed(text: String) -> Observable<UnprocessedToken> {
    preconditionFailure("This function must be implemented by the child class.")
  }
}

