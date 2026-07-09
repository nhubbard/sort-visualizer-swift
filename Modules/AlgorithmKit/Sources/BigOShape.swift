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

    public func value(n: Double) -> Double {
        switch self {
        case .constant: return 1
        case .logarithmic: return log2(n)
        case .logarithmicSquared: return log2(n) * log2(n)
        case .linear: return n
        case .linearithmic: return n * log2(n)
        case .linearithmicSquared: return n * log2(n) * log2(n)
        case let .polynomial(exponent): return pow(n, exponent)
        case .superLinearithmic: return pow(n, log2(n))
        case .exponential: return pow(2, n)
        case .factorial:
            // `lgamma(n + 1)` is `log(n!)` — avoids overflowing `Double` for the size ranges these
            // charts actually cover, then converts back via `exp` since callers want the raw value.
            return exp(lgamma(n + 1))
        }
    }

    /// The fixed backdrop drawn on every Big-O correlation chart — every algorithm's real data is
    /// compared against this same family, not just against its own declared complexity, so a chart
    /// stays meaningful even for algorithms whose declared string isn't parseable (see `parse`).
    public static let referenceFamily: [(label: String, shape: BigOShape)] = [
        ("O(1)", .constant),
        ("O(log n)", .logarithmic),
        ("O(n)", .linear),
        ("O(n log n)", .linearithmic),
        ("O(n^2)", .polynomial(2)),
        ("O(n^3)", .polynomial(3)),
    ]

    /// Parses one of `AlgorithmMetadata`'s hand-authored complexity strings (e.g. `"O(n^2)"`,
    /// `"O(n \log n)"`, `"O(n^{2.71})"`) into a `BigOShape`, or `nil` when the string isn't a pure
    /// function of `n` (contains another free variable) or isn't one of the recognized shapes.
    /// Tolerant of this codebase's inconsistent authoring: `*` vs `\times`, `\log n` vs `\log{n}`
    /// vs `log n`, and `n^2.71` vs `n^{2.71}` all normalize to the same form before matching.
    public static func parse(_ complexity: String) -> BigOShape? {
        guard let openParen = complexity.firstIndex(of: "("), let closeParen = complexity.lastIndex(of: ")"),
              openParen < closeParen else { return nil }

        var normalized = String(complexity[complexity.index(after: openParen)..<closeParen])
        normalized = normalized.replacingOccurrences(of: "\\times", with: "*")
        normalized = normalized.replacingOccurrences(of: "\\log", with: "log")
        normalized = normalized.replacingOccurrences(of: "{", with: "")
        normalized = normalized.replacingOccurrences(of: "}", with: "")
        normalized = normalized.replacingOccurrences(of: " ", with: "")

        switch normalized {
        case "1": return .constant
        case "n": return .linear
        case "logn": return .logarithmic
        case "log^2n": return .logarithmicSquared
        case "nlogn": return .linearithmic
        case "nlog^2n": return .linearithmicSquared
        case "n^(logn)": return .superLinearithmic
        case "2^n": return .exponential
        case "n!", "n*n!": return .factorial
        default: break
        }

        if normalized.hasPrefix("n^"), let exponent = Double(normalized.dropFirst(2)) {
            return .polynomial(exponent)
        }
        return nil
    }
}
