import Foundation

/// Options that can be used to modify the default Regexp behavior.
public struct RegexpOptions : OptionSet {
  /// Required by OptionSet protocol. Can be used to obtain integer value of a flag set.
  public let rawValue: UInt
  
  /// Required by OptionSet protocol. Can be used for construction of OptionSet from integer-based flags.
  public init(rawValue: UInt) {
    self.rawValue = rawValue
  }
  
  /// Match letters in the pattern independent of case.
  public static let caseInsensitive = RegexpOptions(rawValue: 1)
  
  /// Ignore whitespace and #-prefixed comments in the pattern.
  public static let allowCommentsAndWhitespace = RegexpOptions(rawValue: 2)
  
  /// Treat the entire pattern as a literal string.
  public static let ignoreMetacharacters = RegexpOptions(rawValue: 4)
  
  /// Allow `.` to match any character, including line separators.
  public static let dotMatchesLineSeparators = RegexpOptions(rawValue: 8)
  
  /// Allow `^` and `$` to match the start and end of lines.
  public static let anchorsMatchLines = RegexpOptions(rawValue: 16)
  
  /// Treat only `\n` as a line separator. Without this flag, all standard line separators are used.
  public static let useUnixLineSeparators = RegexpOptions(rawValue: 32)
  
  /// Use Unicode TR29 to specify word boundaries; otherwise, traditional regular expression word boundaries are used.
  public static let useUnicodeWordBoundaries = RegexpOptions(rawValue: 64)
  
  /// Options used by default by RegexpOptions.
  public static let `default`: RegexpOptions = [caseInsensitive]
}

/// Internal implementation that can't be hidden. Skip it.
extension NSRegularExpression.Options: Hashable {
  /// Internal implementation that can't be hidden. Skip it.
  public var hashValue: Int {
    get {
      return Int(rawValue)
    }
  }
}

/// Allows RegexpOptions to be used as keys for dictionaries. Required for internal implementation.
extension RegexpOptions: Hashable {
  /// Required by Hashable protocol.
  public var hashValue: Int {
    get {
      return Int(rawValue)
    }
  }
}

/// Mapping of `NSRegularExpression` options to `RegexpOption` equivalents.
private let nsToRegexpOptionsMap: [NSRegularExpression.Options: RegexpOptions] = [
  .caseInsensitive: .caseInsensitive,
  .allowCommentsAndWhitespace: .allowCommentsAndWhitespace,
  .ignoreMetacharacters: .ignoreMetacharacters,
  .dotMatchesLineSeparators: .dotMatchesLineSeparators,
  .anchorsMatchLines: .anchorsMatchLines,
  .useUnixLineSeparators: .useUnixLineSeparators,
  .useUnicodeWordBoundaries: .useUnicodeWordBoundaries
]

/// The reverse of `nsToRegexpOptionsMap`.
private let regexpToNSOptionsMap: [RegexpOptions: NSRegularExpression.Options] = nsToRegexpOptionsMap.reduce([:]) { (dict, kv) in
  var dict = dict
  dict[kv.value] = kv.key
  return dict
}

/// Extension to convert `RegexpOptions` to `NSRegularExpression.Options`.
extension RegexpOptions {
  var ns: NSRegularExpression.Options {
    get {
      let nsSeq = regexpToNSOptionsMap.filter { (regexp, _) in
        self.contains(regexp)
      }.map { (_, ns) in
        ns
      }
      return NSRegularExpression.Options(nsSeq)
    }
  }
}

/// Extension to convert `NSRegularExpression.Options` to `RegexpOptions`.
extension NSRegularExpression.Options {
  var regexp: RegexpOptions {
    get {
      let regexpSeq = nsToRegexpOptionsMap.filter { (ns, _) in
        self.contains(ns)
      }.map { (_, regexp) in
        regexp
      }
      return RegexpOptions(regexpSeq)
    }
  }
}
