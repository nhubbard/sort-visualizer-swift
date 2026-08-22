import Foundation

/// A closed-form growth function for a Big-O class, evaluated at real array sizes for charting.
/// Deliberately covers only shapes expressible purely in terms of `n` — `AlgorithmMetadata`'s
/// hand-authored complexity strings include several with an extra free variable (radix sort's `d`
/// digit count, bucket sort's `b`/`m` bucket count, counting sort's `k` value range), and those
/// have no single curve to draw without more context than the string itself carries.
public enum BigOShape: Sendable, Equatable {
  case constant
  case logarithmic
  case logarithmicSquared
  case linear
  case linearithmic
  case linearithmicSquared
  case polynomial(Double)
  case superLinearithmic
  case exponential
  case factorial
  /// `n^n` — distinct from `.factorial` (`n!`): both grow super-exponentially and are easy to
  /// mistake for one another from a declared complexity string alone, but `n^n` is the real
  /// measured growth of algorithms like `OptimizedGuessSort` (its odometer enumerates all `n^n`
  /// index sequences), not `n!`.
  case nToTheN

  public func value(n: Double) -> Double {
    switch self {
    case .constant: return 1
    case .logarithmic: return log2(n)
    case .logarithmicSquared: return log2(n) * log2(n)
    case .linear: return n
    case .linearithmic: return n * log2(n)
    case .linearithmicSquared: return n * log2(n) * log2(n)
    case .polynomial(let exponent): return pow(n, exponent)
    case .superLinearithmic: return pow(n, log2(n))
    case .exponential: return pow(2, n)
    case .factorial:
      // `lgamma(n + 1)` is `log(n!)` — avoids overflowing `Double` for the size ranges these
      // charts actually cover, then converts back via `exp` since callers want the raw value.
      return exp(lgamma(n + 1))
    case .nToTheN:
      // Same overflow-avoidance trick as `.factorial`: `log(n^n) = n*log(n)`.
      return exp(n * log(n))
    }
  }

  /// Strips an `AlgorithmMetadata` complexity string down to a bare, order-preserved token — the
  /// shared first step behind both `parse` (matches the result against the pure-`n` shapes below)
  /// and `BigOCorrelation`'s app-specific resolver (matches the same result against templates
  /// like `"d*n"`/`"n+k"`/`"n*m"` that reference another variable `parse` won't touch). Tolerant
  /// of this codebase's inconsistent authoring: `*` vs `\times`, `\log n` vs `\log{n}` vs `log n`,
  /// and `n^2.71` vs `n^{2.71}` all normalize to the same form.
  public static func normalize(_ complexity: String) -> String? {
    guard let openParen = complexity.firstIndex(of: "("),
      let closeParen = complexity.lastIndex(of: ")"),
      openParen < closeParen
    else { return nil }

    var normalized = String(complexity[complexity.index(after: openParen)..<closeParen])
    normalized = normalized.replacingOccurrences(of: "\\times", with: "*")
    normalized = normalized.replacingOccurrences(of: "\\log", with: "log")
    normalized = normalized.replacingOccurrences(of: "{", with: "")
    normalized = normalized.replacingOccurrences(of: "}", with: "")
    // `n^(log n)` and `n^{log n}` are both used across `AlgorithmMetadata` for the same shape —
    // collapsing the wrapping parens here (in addition to the braces above) lets both forms
    // normalize to the same "n^logn" key instead of only recognizing one of them. It also means
    // a grouped multi-variable form like `"d*(n+b)"` normalizes to the flattened `"d*n+b"` —
    // fine here since callers match this as an opaque lookup key, not as an expression to
    // literally evaluate.
    normalized = normalized.replacingOccurrences(of: "(", with: "")
    normalized = normalized.replacingOccurrences(of: ")", with: "")
    normalized = normalized.replacingOccurrences(of: " ", with: "")
    return normalized
  }

  /// Parses one of `AlgorithmMetadata`'s hand-authored complexity strings (e.g. `"O(n^2)"`,
  /// `"O(n \log n)"`, `"O(n^{2.71})"`) into a `BigOShape`, or `nil` when the string isn't a pure
  /// function of `n` (contains another free variable) or isn't one of the recognized shapes.
  public static func parse(_ complexity: String) -> BigOShape? {
    guard let normalized = normalize(complexity) else { return nil }

    switch normalized {
    case "1": return .constant
    case "n": return .linear
    case "logn": return .logarithmic
    case "log^2n": return .logarithmicSquared
    case "nlogn": return .linearithmic
    case "nlog^2n": return .linearithmicSquared
    case "n^logn": return .superLinearithmic
    case "2^n": return .exponential
    case "n!", "n*n!": return .factorial
    case "n^n": return .nToTheN
    default: break
    }

    if normalized.hasPrefix("n^"), let exponent = Double(normalized.dropFirst(2)) {
      return .polynomial(exponent)
    }
    return nil
  }
}
