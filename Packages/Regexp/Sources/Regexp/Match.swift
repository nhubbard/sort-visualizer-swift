import Foundation

/// Represents groups of pattern matches. Supports subscripts.
public protocol MatchGroupsProtocol {
  /**
   * Takes a subgroup match substring by index.
   *
   * - Parameter index: Index of subgroup to match to. Zero represents the whole match.
   * - Returns: A substring or nil if the supplied subgroup does not exist.
   */
  subscript(index: Int) -> String? { get }
  
  /**
   * Takes a subgroup match substring by name. This will work if you supplied subgroup names while creating the Regexp.
   *
   * - Parameter name: Name of subgroup to match to.
   * - Returns: A substring, or `nil`, if the supplied subgroup does not exist.
   */
  subscript(name: String) -> String? { get }
}

// This will become public when we add a second implementation.
protocol MatchProtocol {
  var source: String { get }
  
  var range: StringRange { get }
  var ranges: [StringRange?] { get }
  
  func range(at index: Int) -> StringRange?
  func range(named name: String) -> StringRange?
  
  var matched: String { get }
  var subgroups: [String?] { get }
  var groups: MatchGroupsProtocol { get }
  
  func group(at index: Int) -> String?
  func group(named name: String) -> String?
}

struct MatchGroups: MatchGroupsProtocol {
  private let match: MatchProtocol
  
  public init(match: MatchProtocol) {
    self.match = match
  }
  
  subscript(index: Int) -> String? {
    return match.group(at: index)
  }
  
  subscript(name: String) -> String? {
    return match.group(named: name)
  }
}

/// Represents a pattern match.
public class Match: MatchProtocol {
  /// The original string supplied to the Regexp for matching.
  public let source: String
  
  let match: CompiledPatternMatch
  let groupNames: [String]
  let nameMap: [String: Int]
  
  init(source: String, match: CompiledPatternMatch, groupNames: [String]) {
    self.source = source
    self.match = match
    self.groupNames = groupNames
    self.nameMap = groupNames.indexHash
  }
  
  func index(of group: String) -> Int? {
    guard let groupIndex = nameMap[group] else {
      return nil
    }
    return groupIndex + 1
  }
  
  /// The matching range.
  public var range: StringRange {
    get {
      // Here it never throws, because otherwise it will not match.
      return try! match.range.asRange(ofString: source)
    }
  }
  
  /// The matching ranges of subgroups.
  public var ranges: [StringRange?] {
    get {
      var result = [StringRange?]()
      for i in 0..<match.numberOfRanges {
        // Subrange can be empty
        let stringRange = try? match.range(at: i).asRange(ofString: source)
        result.append(stringRange)
      }
      return result
    }
  }
  
  /**
   * Takes a subgroup match by index.
   *
   * - Parameter index: Number of subgroup to match to. Zero represents the whole match.
   * - Returns: A range or `nil` if the supplied subgroup does not exist.
   */
  public func range(at index: Int) -> StringRange? {
    guard match.numberOfRanges > index else {
      return nil
    }
    return try? match.range(at: index).asRange(ofString: source)
  }
  
  /**
   * Takes a subgroup match range by name. This will work if you supplied subgroup names while creating Regex.
   *
   * - Parameter name: Name of subgroup to match to.
   * - Returns: A range or `nil` if the supplied subgroup does not exist.
   */
  public func range(named name: String) -> StringRange? {
    guard let groupIndex = index(of: name) else {
      return nil
    }
    // Subrange can be empty
    return try? match.range(at: groupIndex).asRange(ofString: source)
  }
  
  /// The whole matched substring.
  public var matched: String {
    get {
      // Zero group is always there, otherwise there is no match
      return group(at: 0)!
    }
  }
  
  /// Matched subgroups' substrings.
  public var subgroups: [String?] {
    get {
      let subRanges = ranges.suffix(from: 1)
      return subRanges.map { range in
        range.map { range in
          String(source[range])
        }
      }
    }
  }
  
  /// Returns the groups object with subscript support. Zero index represents the whole match.
  public var groups: MatchGroupsProtocol {
    get {
      return MatchGroups(match: self)
    }
  }
  
  /**
   * Takes a subgroup match substring by index.
   *
   * - Parameter name: Index of subgroup to match to. Zero represents the whole match.
   * - Returns: A substring or nil if the supplied subgroup does not exist.
   */
  public func group(at index: Int) -> String? {
    let range = self.range(at: index)
    return range.map { range in
      String(source[range])
    }
  }
  
  /**
   * Takes a subgroup match substring by name. This will work if you supplied subgroup names while creating Regexp.
   *
   * - Parameter name: Name of subgroup to match to.
   * - Returns: A substring or `nil` if the supplied subgroup does not exist.
   */
  public func group(named name: String) -> String? {
    guard let groupIndex = index(of: name) else {
      return nil
    }
    return self.group(at: groupIndex)
  }
}
