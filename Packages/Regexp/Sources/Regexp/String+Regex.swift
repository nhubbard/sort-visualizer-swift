/// Adds Regexp extensions to String.
public extension String {
  /**
   * Creates a regexp using this string as a pattern. Can return `nil` if pattern is invalid.
   */
  var r: Regexp? {
    get {
      return try? Regexp(pattern: self)
    }
  }
  
  /**
   * An inverse alias to `Regexp.split`.
   *
   * - Parameter regex: Regex to split the string with.
   * - Returns: An array. See `Regexp.split` for more details.
   */
  func split(using regex: RegexpProtocol?) -> [String] {
    guard let regex = regex else {
      return [self]
    }
    return regex.split(self)
  }
}

// Regexp operator declarations
infix operator =~ : ComparisonPrecedence
infix operator !~ : ComparisonPrecedence

/**
 * Syntactic sugar for pattern matching. Example: `"ABC" =~ ".*".r`
 *
 * - Parameter source: String to match.
 * - Parameter regex: Regex to match the string with.
 * - Returns: `true` if matches, `false` otherwise.
 *
 * See `Regexp.matches` for more details.
 */
public func =~(source: String, regexp: RegexpProtocol?) -> Bool {
  guard let matches = regexp?.matches(source) else {
    return false
  }
  return matches
}

/**
 * Syntactic sugar for pattern matching. Example: `"ABC" =~ ".*".r`
 *
 * - Parameter source: String to match.
 * - Parameter pattern: Pattern string to match with.
 * - Returns: `true` if matches, `false` otherwise.
 *
 * See `Regexp.matches` for more details.
 */
public func =~(source: String, pattern: String) -> Bool {
  return source =~ pattern.r
}

/**
 * Syntactic sugar for pattern matching. Used as `"ABC" !~ ".*".r`. Negation of the `=~` operator.
 *
 * - Parameter source: String to match
 * - Parameter regex: Regex to match the string with
 * - Returns: `false` if matches, `true` otherwise
 */
public func !~(source: String, regex: RegexpProtocol?) -> Bool {
  return !(source =~ regex)
}

/**
 * Syntactic sugar for pattern matching. Used as `"ABC" !~ ".*".r`. Negation of the `=~` operator.
 *
 * - Parameter source: String to match
 * - Parameter pattern: Pattern string to match the string with
 * - Returns: `false` if matches, `true` otherwise
 */
public func !~(source: String, pattern: String) -> Bool {
  return !(source =~ pattern.r)
}

/**
 * Operator used by `switch` keyword in constructs like the following:
 *
 * ```swift
 * switch str {
 *   case "\\d+".r: print("has digit")
 *   case "[a-z]+".r: print("has letter")
 *   default: print("nothing")
 * }
 * ```
 *
 * Deep integration with Swift.
 * - Returns: `true` if matches, `false` otherwise
 */
public func ~=(regexp: RegexpProtocol?, source: String) -> Bool {
  return source =~ regexp
}
