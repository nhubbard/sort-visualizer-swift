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
protocol BaseLexer {
  /// Name of the lexer.
  var name: String { get }
  
  /// URL of the language specification/definition.
  var url: String { get }
  
  /// Shortcuts for the lexer.
  var aliases: [String] { get }
  
  /// File name globs
  var filenames: [String] { get }
  
  /// Secondary file name globs
  var aliasFilenames: [String] { get }
  
  /// Mime types
  var mimetypes: [String] { get }
  
  /// Priority, should multiple lexers match and no content is provided.
  var priority: Int { get }
  
  /// Should we strip newlines out?
  var stripNewlines: Bool { get }
  
  /// Should we strip all spacing out?
  var stripAll: Bool { get }
  
  /// Should we ensure there are newlines?
  var ensureNewlines: Bool { get }
  
  /// Tab size
  var tabSize: Int { get }
  
  /**
   * Return a float between 0 and 1 indicating the confidence of the lexer in highlighting the text. 0 means 'will not highlight', 1 means 'guaranteed to highlight'.
   */
  func analyzeText(text: String) -> Float
  
  /**
   * Return an `Observable` of (`index`, `tokenType`, `value`) tuples where `index`
   * is the starting position of the token within the input text.
   */
  func getTokensUnprocessed(text: String) -> Observable<UnprocessedToken>
}

extension BaseLexer {
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
    return try await getTokensUnprocessed(text: _text).map { token in
      Token(type: token.1, value: token.2)
    }.toArray().value
  }
}

/**
 * This lexer takes two lexers as arguments. A root lexer and a language lexer. First, everything is scanned using the
 * language lexer, and then all `Other` tokens are lexed using the root lexer.
 *
 * The lexers from the `template` lexer package use this base lexer.
 */
class DelegatingLexer: BaseLexer {
  // Base lexer properties
  var name: String
  var url: String
  var aliases: [String]
  var filenames: [String]
  var aliasFilenames: [String]
  var mimetypes: [String]
  var priority: Int
  var stripNewlines: Bool
  var stripAll: Bool
  var ensureNewlines: Bool
  var tabSize: Int
  
  // Delegating lexer-specific properties
  var rootLexer: BaseLexer
  var languageLexer: BaseLexer
  var needle: Token.TokenType
  var options: [String: Any] = [:]
  
  init(rootLexer: BaseLexer, languageLexer: BaseLexer, needle: Token.TokenType = .other, options: [String: Any] = [:]) {
    // Base lexer properties
    name = "delegating\(languageLexer.name.capitalized)And\(rootLexer.name.capitalized)"
    url = languageLexer.url
    aliases = languageLexer.aliases
    filenames = languageLexer.filenames
    aliasFilenames = languageLexer.aliasFilenames
    mimetypes = languageLexer.mimetypes
    priority = languageLexer.priority
    stripNewlines = languageLexer.stripNewlines
    stripAll = languageLexer.stripAll
    ensureNewlines = languageLexer.ensureNewlines
    tabSize = languageLexer.tabSize
    
    // Delegating lexer-specific properties
    self.rootLexer = rootLexer
    self.languageLexer = languageLexer
    self.needle = needle
    self.options = options
  }
  
  func analyzeText(text: String) -> Float {
    languageLexer.analyzeText(text: text)
  }
  
  func getTokensUnprocessed(text: String) -> Observable<UnprocessedToken> {
    var buffered: String = ""
    var insertions: [(Int, [UnprocessedToken])] = []
    var lngBuffer: [UnprocessedToken] = []
    _ = languageLexer.getTokensUnprocessed(text: text).subscribe { event in
      if let (i, t, v) = event.element {
        if t == self.needle {
          if !lngBuffer.isEmpty {
            insertions.append((buffered.count, lngBuffer))
            lngBuffer = []
          }
          buffered += v
        } else {
          lngBuffer.append((i, t, v))
        }
      }
    }
    if !lngBuffer.isEmpty {
      insertions.append((buffered.count, lngBuffer))
    }
    // TODO: return doInsertions(insertions, self.rootLexer.getTokensUnprocessed(text: buffered))
    return Observable.empty()
  }
}

/// Indicates that a state should include rules from another state.
protocol IncludeProtocol {
  // Replacement for descending from `str` in Python (can't be done in Swift)
  func asString() -> String
}

/// Indicates that a state should inherit from its superclass.
protocol InheritProtocol {}

/// Indicates that a state is combined from multiple states.
protocol CombinedProtocol {}

/// A pseudo-match object constructed from a string.
class PseudoMatch {
  var _text: String
  var _start: Int
  
  init(start: Int, text: String) {
    _text = text
    _start = start
  }
  
  func start(arg: Any? = nil) -> Int {
    _start
  }
  
  func end(arg: Any? = nil) -> Int {
    _start + _text.count
  }
  
  func group(arg: Any? = nil) -> String {
    if arg != nil {
      fatalError("No such group")
    }
    return _text
  }
  
  func groups() -> [String] {
    [_text]
  }
  
  func groupdict() -> [String: String] {
    [:]
  }
}

/**
 * Callback that yields multiple actions for each group in the match.
 */
/*
func byGroups(args: [Int: Any?]) -> (BaseLexer, Match, Any?) -> Observable<Any> {
  func callback(lexer: BaseLexer, match: Match, context: Any? = nil) -> Observable<Any> {
    for (i, action) in args {
      if action == nil {
        continue
      } else if action is Token.TokenType {
        var data = match.group(at: i + 1)
        if data != nil {
          return Observable((match.start, action, data))
        }
      }
    }
  }
}
*/
