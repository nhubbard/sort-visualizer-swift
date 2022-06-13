//
//  PythonLexer.swift
//  PygmentsKit
//
//  Created by Nicholas Hubbard on 6/5/22.
//

import Foundation
import RxSwift
import Regexp

let lineRegex = try? Regexp(pattern: #".*?\n"#, groupNames: [])

class PythonLexer: BaseLexer {
  var name: String = "python"
  var url: String = "https://www.python.org"
  var aliases: [String] = ["python", "py", "sage", "python3", "py"]
  var filenames: [String] = ["*.py", "*.pyw", "*.jy", "*.sage", "*.sc", "SConstruct", "SConscript", "*.bzl", "BUCK", "BUILD", "BUILD.bazel", "WORKSPACE", "*.tac"]
  var aliasFilenames: [String] = []
  var mimetypes: [String] = ["text/x-python", "application/x-python", "text/x-python3", "application/x-python3"]
  var priority: Int = 0
  var stripNewlines: Bool = true
  var stripAll: Bool = false
  var ensureNewlines: Bool = true
  var tabSize: Int = 2
  private var cache: [PythonRegexCacheKey: Regexp] = [:]
  
  private enum PythonRegexCacheKey: String {
    case lineRegex = #".*?\n"#
    // Inner string rules
    case innerStringOldFormat = #"(%(\(\w+\))?[-#0 +]*([0-9]+|[*])?(\.([0-9]+|[*]))?)([hlL]?[E-GXc-giorsaux%])"#
    case innerStringNewFormat = #"(\{)(((\w+)((\.\w+)|(\[[^\]]+\]))*)?)((\![sra])?)((\:(.?[<>=\^])?[-+ ]?#?0?(\d+)?,?(\.\d+)?[E-GXb-gnosx%]?)?)(\})"#
    case innerStringFirstSpecial = #"[^\\\'"%{\n]+"#
    case innerStringSecondSpecial, fStringSecondSpecial = #"[\'"\\]"#
    case innerStringInvalid = #"%|(\{{1,2})"#
    // f-string rules
    case fStringStart = #"\}"#
    case fStringEnd = #"\{"#
    case fStringFirstSpecial = #"[^\\\'"{}\n]+"#
    // fStringSecondSpecial is not unique; merged with innerStringSecondSpecial
  }
  
  private func regexCache(_ key: PythonRegexCacheKey) -> Regexp {
    if !cache.keys.contains(key) {
      cache[key] = key.rawValue.r!
    }
    return cache[key]!
  }
  
  private func innerStringRules(_ tokenType: Token.TokenType) -> [([Regexp], Token.TokenType)] {
    [
      // Matches the older-style '%s' % (...) string formatting. 2 groups.
      ([regexCache(.innerStringOldFormat)], .stringInterpol),
      // Matches the new style '{}'.format(...) string formatting. 5 groups.
      ([regexCache(.innerStringNewFormat)], .stringInterpol),
      // Backslashes, quotes, and formatting signs must be parsed one at a time.
      ([regexCache(.innerStringFirstSpecial)], tokenType),
      ([regexCache(.innerStringSecondSpecial)], tokenType),
      // Unhandled string formatting sign
      ([regexCache(.innerStringInvalid)], tokenType)
      // Newlines are an error (uses 'nl' state)
    ]
  }
  
  private func fStringRules(_ tokenType: Token.TokenType) -> [([Regexp], Token.TokenType)] {
    [
      // Assuming that a '}' is the closing brace after the format specifier. We can't detect syntax errors this way.
      ([regexCache(.fStringStart)], .stringInterpol),
      ([regexCache(.fStringEnd)], .stringInterpol),
      // Backslashes, quotes, and formatting signs must be parsed one at a time.
      ([regexCache(.fStringFirstSpecial)], tokenType),
      ([regexCache(.fStringSecondSpecial)], tokenType)
    ]
  }
  
  // TODO: Hacky as fuck. I couldn't stand attempting to port the shebang analysis function, so I skipped it. I can live with just explicitly specifying the lexer every time I use it.
  func analyzeText(text: String) -> Float {
    Float(1.0)
  }
  
  func getTokensUnprocessed(text: String) -> Observable<UnprocessedToken> {
    Observable.empty()
  }
}
