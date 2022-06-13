import Foundation

/**
 * Regular expression protocol.
 * Makes it easier to maintain two implementations.
 */
public protocol RegexpProtocol {
  /**
   * Constructor. Same as main, more lightweight (omits options). Can throw.
   * - Parameter pattern: A pattern to be used.
   * - Parameter groupNames: Group names to be used for matching, specified as array.
   */
  init(pattern: String, groupNames: [String]) throws
  
  /**
   * Constructor. Same as main, more lightweight (omits options).
   * - Parameter pattern: A pattern to be used.
   * - Parameter groupNames: Group names to be used, specified as varargs.
   */
  init(pattern: String, groupNames: String...) throws
  
  /**
   * Main constructor. Can throw.
   *
   * - Parameter pattern: A pattern to be used.
   * - Parameter options: `RegexpOptions` (case sensitivity, etc.)
   * - Parameter groupNames: Group names to be used for matching, specified as an array.
   */
  init(pattern: String, options: RegexpOptions, groupNames: [String]) throws
  
  /**
   * Main constructor. Can throw.
   *
   * - Parameter pattern: A pattern to be used.
   * - Parameter options: `RegexpOptions` (case sensitivity, etc.)
   * - Parameter groupNames: Group names to be used for matching, specified as varargs.
   */
  init(pattern: String, options: RegexpOptions, groupNames: String...) throws
  
  /// Pattern used to create the Regexp
  var pattern: String { get }
  
  /// Group names that will be used for named pattern matching. Supplied in a constructor.
  var groupNames: [String] { get }
  
  /**
   * Checks if the supplied string matches the pattern.
   *
   * - Parameter source: String to be matched to the pattern.
   * - Returns: `true` if the source matches, `false` otherwise.
   */
  func matches(_ source: String) -> Bool
  
  /**
   * Finds all the matches in the supplied string.
   *
   * - Parameter source: String to be matched to the pattern.
   * - Returns: A sequence of matches. Can be empty if nothing was found.
   */
  func findAll(in source: String) -> MatchSequence
  
  /**
   * Returns the first match in the supplied string.
   *
   * - Parameter source: String to be matched to the pattern.
   * - Returns: The match. Can be `Optional.none` if nothing was found.
   */
  func findFirst(in source: String) -> Match?
  
  /**
   * Replaces all occurrences of the pattern using the supplied replacement String.
   *
   * - Parameter source: String to be matched to the pattern.
   * - Parameter replacement: Replacement string. Can use $1, $2, etc. to insert match groups.
   * - Returns: A string, where all the occurrences of the pattern were replaced.
   */
  func replaceAll(in source: String, with replacement: String) -> String
  
  /**
   * Replaces all occurrences of the pattern using the supplied replacer function.
   *
   * - Parameter source: String to be matched to the pattern.
   * - Parameter replacer: Function that takes a match and returns a replacement. If replacement is `nil`, the original match gets inserted instead.
   * - Returns: A string, where all the occurrences of the pattern were replaced.
   */
  func replaceAll(in source: String, using replacer: (Match) -> String?) -> String
  
  /**
   * Replaces first occurrence of the pattern using the supplied replacement String.
   *
   * - Parameter source: String to be matched to the pattern.
   * - Parameter replacement: Replacement string. Can use $1, $2, etc. to insert matched groups.
   * - Returns: A string, where the first occurrence of the pattern was replaced.
   */
  func replaceFirst(in source: String, with replacement: String) -> String
  
  /**
   * Replaces first occurrence of the pattern using the supplied replacer function.
   *
   * - Parameter source: String to be matched to the pattern.
   * - Parameter replacer: Function that takes a match and returns a replacement. If replacement is `nil`, the original match gets inserted instead.
   * - Returns: A string, where the first occurrence of the pattern was replaced.
   */
  func replaceFirst(in source: String, using replacer: (Match) -> String?) -> String
  
  /**
   * Splits the content of the supplied string by the pattern. In case the pattern contains subgroups, they are added to the resulting array as well.
   *
   * - Parameter source: String to be split.
   * - Returns: Array of pieces of the string split with the pattern delimiter.
   */
  func split(_ source: String) -> [String]
}

/// Regular expression
public class Regexp: RegexpProtocol {
  /// Pattern used to create this regexp
  public let pattern: String
  
  /// Group names that will be used for named pattern matching. Supplied in the constructor.
  public let groupNames: [String]
  
  /// Compiled pattern.
  private let compiled: CompiledPattern?
  
  /**
   * Constructor. Same as main, more lightweight (omits options). Can throw.
   * - Parameter pattern: A pattern to be used.
   * - Parameter groupNames: Group names to be used for matching, specified as array.
   */
  public required convenience init(pattern: String, groupNames: [String] = []) throws {
    try self.init(pattern: pattern, options: .`default`, groupNames: groupNames)
  }
  
  /**
   * Constructor. Same as main, more lightweight (omits options).
   * - Parameter pattern: A pattern to be used.
   * - Parameter groupNames: Group names to be used, specified as varargs.
   */
  public required convenience init(pattern: String, groupNames: String...) throws {
    try self.init(pattern: pattern, groupNames: groupNames)
  }
  
  /**
   * Main constructor. Can throw.
   *
   * - Parameter pattern: A pattern to be used.
   * - Parameter options: `RegexpOptions` (case sensitivity, etc.)
   * - Parameter groupNames: Group names to be used for matching, specified as an array.
   */
  public required init(pattern: String, options: RegexpOptions, groupNames: [String] = []) throws {
    self.pattern = pattern
    self.groupNames = groupNames
    self.compiled = try! type(of: self).compile(pattern: pattern, options: options)
  }
  
  /**
   * Main constructor. Can throw.
   *
   * - Parameter pattern: A pattern to be used.
   * - Parameter options: `RegexpOptions` (case sensitivity, etc.)
   * - Parameter groupNames: Group names to be used for matching, specified as varargs.
   */
  public required convenience init(pattern: String, options: RegexpOptions, groupNames: String...) throws {
    try self.init(pattern: pattern, options: options, groupNames: groupNames)
  }
  
  /// Compile a pattern into a NSRegularExpression.
  private static func compile(pattern: String, options: RegexpOptions) throws -> CompiledPattern {
    try NSRegularExpression(pattern: pattern, options: options.ns)
  }
  
  private func replaceMatches<T : Sequence>(in source: String, matches: T, using replacer: (Match) -> String?) -> String where T.Iterator.Element : Match {
    var result = ""
    var lastRange: StringRange = source.startIndex..<source.startIndex
    for match in matches {
      result += source[lastRange.upperBound..<match.range.lowerBound]
      if let replacement = replacer(match) {
        result += replacement
      } else {
        result += source[match.range]
      }
      lastRange = match.range
    }
    result += source[lastRange.upperBound...]
    return result
  }
  
  /**
   * Checks if the supplied string matches the pattern.
   *
   * - Parameter source: String to be matched to the pattern.
   * - Returns: `true` if the source matches, `false` otherwise.
   */
  public func matches(_ source: String) -> Bool {
    guard let _ = findFirst(in: source) else {
      return false
    }
    return true
  }
  
  /**
   * Finds all the matches in the supplied string.
   *
   * - Parameter source: String to be matched to the pattern.
   * - Returns: A sequence of matches. Can be empty if nothing was found.
   */
  public func findAll(in source: String) -> MatchSequence {
    let options = NSRegularExpression.MatchingOptions(rawValue: 0)
    let range = GroupRange(location: 0, length: source.utf16.count)
    let context = compiled?.matches(in: source, options: options, range: range)
    // Hard unwrap of context, because the instance would not exist without it.
    return MatchSequence(source: source, context: context!, groupNames: groupNames)
  }
  
  /**
   * Returns the first match in the supplied string.
   *
   * - Parameter source: String to be matched to the pattern.
   * - Returns: The match. Can be `Optional.none` if nothing was found.
   */
  public func findFirst(in source: String) -> Match? {
    let options = NSRegularExpression.MatchingOptions(rawValue: 0)
    let range = GroupRange(location: 0, length: source.utf16.count)
    let match = compiled?.firstMatch(in: source, options: options, range: range)
    return match.map { match in
      Match(source: source, match: match, groupNames: groupNames)
    }
  }
  
  /**
   * Replaces all occurrences of the pattern using the supplied replacement String.
   *
   * - Parameter source: String to be matched to the pattern.
   * - Parameter replacement: Replacement string. Can use $1, $2, etc. to insert match groups.
   * - Returns: A string, where all the occurrences of the pattern were replaced.
   */
  public func replaceAll(in source: String, with replacement: String) -> String {
    let options = NSRegularExpression.MatchingOptions(rawValue: 0)
    let range = GroupRange(location: 0, length: source.utf16.count)
    return compiled!.stringByReplacingMatches(in: source, options: options, range: range, withTemplate: replacement)
  }
  
  /**
   * Replaces all occurrences of the pattern using the supplied replacer function.
   *
   * - Parameter source: String to be matched to the pattern.
   * - Parameter replacer: Function that takes a match and returns a replacement. If replacement is `nil`, the original match gets inserted instead.
   * - Returns: A string, where all the occurrences of the pattern were replaced.
   */
  public func replaceAll(in source: String, using replacer: (Match) -> String?) -> String {
    let matches = findAll(in: source)
    return replaceMatches(in: source, matches: matches, using: replacer)
  }
  
  /**
   * Replaces first occurrence of the pattern using the supplied replacement String.
   *
   * - Parameter source: String to be matched to the pattern.
   * - Parameter replacement: Replacement string. Can use $1, $2, etc. to insert matched groups.
   * - Returns: A string, where the first occurrence of the pattern was replaced.
   */
  public func replaceFirst(in source: String, with replacement: String) -> String {
    return replaceFirst(in: source) { match in
      return self.compiled!.replacementString(for: match.match, in: source, offset: 0, template: replacement)
    }
  }
  
  /**
   * Replaces first occurrence of the pattern using the supplied replacer function.
   *
   * - Parameter source: String to be matched to the pattern.
   * - Parameter replacer: Function that takes a match and returns a replacement. If replacement is `nil`, the original match gets inserted instead.
   * - Returns: A string, where the first occurrence of the pattern was replaced.
   */
  public func replaceFirst(in source: String, using replacer: (Match) -> String?) -> String {
    var matches = [Match]()
    if let match = findFirst(in: source) {
      matches.append(match)
    }
    return replaceMatches(in: source, matches: matches, using: replacer)
  }
  
  /**
   * Splits the content of the supplied string by the pattern. In case the pattern contains subgroups, they are added to the resulting array as well.
   *
   * - Parameter source: String to be split.
   * - Returns: Array of pieces of the string split with the pattern delimiter.
   */
  public func split(_ source: String) -> [String] {
    var result = [String]()
    let matches = findAll(in: source)
    var lastRange: StringRange = source.startIndex..<source.startIndex
    for match in matches {
      // Extract the piece before the match
      let range = lastRange.upperBound..<match.range.lowerBound
      let piece = String(source[range])
      result.append(piece)
      lastRange = match.range
      let subgroups = match.subgroups.filter { subgroup in
        subgroup != nil
      }.map { subgroup in
        subgroup!
      }
      // Add subgroups
      result.append(contentsOf: subgroups)
    }
    let rest = String(source[lastRange.upperBound...])
    result.append(rest)
    return result
  }
}
