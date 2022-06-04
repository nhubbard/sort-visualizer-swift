//
//  Scanner.swift
//  PygmentsKit
//
//  Created by Nicholas Hubbard on 6/3/22.
//

import Foundation

struct EndOfText: Error, CustomStringConvertible {
  public var description: String = "The end of the text has been reached, but the match function was called to continue!"
}

/**
 * A simple Scanner. All method patterns are regular expresison strings.
 */
class Scanner {
  var data: String
  var dataLength: Int
  var startPosition: Int
  var position: Int
  var options: [NSRegularExpression.Options] = []
  var last: NSTextCheckingResult?
  var match: NSTextCheckingResult?
  var _regexCache: [String: NSRegularExpression?]
  
  /**
   * Default initializer.
   *
   * - Parameter text: The text to scan
   * - Parameter options: `NSRegularExpression` flags
   */
  init(text: String, options: [NSRegularExpression.Options] = []) {
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
    return self.position >= self.dataLength
  }
  
  /// Gets an up-to-date `NSRange` for use with the `NSRegularExpression` functions.
  private var currentRange: NSRange {
    return NSRange(String.Index(of: self.position)..<self.data.endIndex, in: self.data)
  }
  
  /// Compile, cache, and return the specified regular expression pattern.
  private func cachePattern(pattern: String) throws -> NSRegularExpression {
    if self._regexCache[pattern] == nil {
      self._regexCache[pattern] = try NSRegularExpression(pattern: pattern, options: self.options)
    }
    return self._regexCache[pattern]!
  }
  
  /// Apply `pattern` on the current position and return the match object. (Doesn't touch `pos`.)
  /// Use this for lookahead.
  func check(pattern: String) throws -> [NSTextCheckingResult] {
    // Ensure we haven't passed the end of the scanner.
    guard !eos else {
      throw EndOfText()
    }
    // Cache the NSRegularExpression object.
    var regexp = try cachePattern(pattern: pattern)
    // Check the data for the pattern.
    return regexp.matches(in: self.data, options: self.options, range: currentRange)
  }
  
  /// Apply a pattern to the current position and check if it matches. Doesn't touch `pos`.
  func test(pattern: String) throws -> Bool {
    return !check(pattern: pattern).isEmpty
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
    // Cache the NSRegularExpression object.
    var regexp = try cachePattern(pattern: pattern)
    // Move current match to last match.
    self.last = self.match
    // Attempt a match.
    var m = regexp.firstMatch(in: self.data, options: self.options, range: currentRange)
    guard m != nil else {
      return false
    }
    // Start moving the ranges up.
    self.startPosition = m.range.lowerBound
    self.position = m.range.upperBound
    // TODO: Not 100% certain if this is the right action; originally `m.group()` in Python.
    self.match = m
    return true
  }
  
  /// Scan exactly one character.
  func getCharacter() throws {
    self.scan(pattern: ".")
  }
}
