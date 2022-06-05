//
//  Scanner.swift
//  PygmentsKit
//
//  Created by Nicholas Hubbard on 6/3/22.
//

import Foundation
import Regex

struct EndOfText: Error, CustomStringConvertible {
  public var description: String = "The end of the text has been reached, but the match function was called to continue!"
}

/**
 * A simple scanner. All method patterns are regular expresison strings.
 */
class Scanner {
  var data: String
  var dataLength: Int
  var startPosition: Int
  var position: Int
  var options: RegexOptions = [RegexOptions.default]
  var last: String?
  var match: String?
  var _regexCache: [String: Regex]
  
  /**
   * Default initializer.
   *
   * - Parameter text: The text to scan
   * - Parameter options: `RegexOptions` flags (it's an array but also not, see `OptionSet` for details)
   */
  init(text: String, options: RegexOptions = [RegexOptions.default]) {
    self.data = text
    self.dataLength = text.count
    self.startPosition = 0
    self.position = 0
    self.options = options
    self.last = nil
    self.match = nil
    self._regexCache = [:]
  }
  
  /// `true` if the scanner has reached the end of the text.
  var eos: Bool {
    return position >= dataLength
  }
  
  /// Gets an up-to-date `Range` for use with the `check` and `scan` functions.
  private func currentRange() -> Range<String.Index> {
    return data.index(data.startIndex, offsetBy: position)..<data.endIndex
  }
  
  /// Compile, cache, and return the specified regular expression pattern.
  private func cachePattern(pattern: String, groupNames: [String] = []) throws -> Regex {
    if _regexCache[pattern] == nil {
      _regexCache[pattern] = try Regex(pattern: pattern, options: options, groupNames: groupNames)
    }
    return _regexCache[pattern]!
  }
  
  /// Apply `pattern` on the current position and return the match object. (Doesn't touch `pos`.)
  /// Use this for lookahead.
  func check(pattern: String) throws -> MatchSequence {
    // Ensure we haven't passed the end of the scanner.
    guard !eos else {
      throw EndOfText()
    }
    // Cache the Regex object.
    let regexp = try cachePattern(pattern: pattern)
    // Get the substring.
    let substring = String(data[currentRange()])
    // Check the data for the pattern.
    return regexp.findAll(in: substring)
  }
  
  /// Apply a pattern to the current position and check if it matches. Doesn't touch `pos`.
  func test(pattern: String) throws -> Bool {
    return try !check(pattern: pattern).isEmpty
  }
  
  /// Scan the text for the given pattern and update the `pos` and `match` and related fields.
  /// The return value is a Bool that indicates if the pattern matched.
  /// The matched value is stored on the instance as `match`; the last value is stored as `last`.
  /// `startPosition` is the position of the pointer before the pattern was matched.
  /// `pos` is the end position.
  func scan(pattern: String) throws -> Bool {
    // Ensure we haven't passed the end of the scanner.
    guard !eos else {
      throw EndOfText()
    }
    // Cache the Regex object.
    let regexp = try cachePattern(pattern: pattern)
    // Move current match to last match.
    last = match
    // Attempt a match.
    //var m = regexp.firstMatch(in: self.data, options: self.options, range: currentRange)
    let string = String(data[currentRange()])
    let m = regexp.findFirst(in: string)
    guard m != nil else {
      return false
    }
    // Start moving the ranges up.
    startPosition = m!.range.lowerBound.utf16Offset(in: string)
    position = m!.range.upperBound.utf16Offset(in: string)
    match = m!.group(at: 0)
    return true
  }
  
  /// Scan exactly one character.
  func getCharacter() throws -> Bool {
    return try scan(pattern: ".")
  }
}
