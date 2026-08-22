import Foundation

/// Closed-form real-root solving for the low-degree polynomials the operation-growth calibration
/// pipeline actually produces (a 2nd-order Taylor expansion is a quadratic in `(n - n0)`; a
/// `polynomial + intercept` growth fit is already a quadratic in `n`), plus a fixed-iteration
/// Newton solver for the one family with no elementary inverse at all (`n·log n = K`, the
/// Lambert-*W* case for `n^n`-like/factorial growth).
public enum PolynomialRootSolver {
  /// Real roots of `coefficients[0] + coefficients[1]·x + coefficients[2]·x² + … = 0`, degree 1–3
  /// only (`coefficients.count` 2–4) — every shape this pipeline's Taylor/regression steps
  /// produce. Returns an empty array for an all-zero leading coefficient run shorter than that,
  /// or for a genuinely complex-only cubic root pair (the real root is still returned in that
  /// case). Each returned root gets one Newton polish pass against the exact polynomial, since
  /// Cardano's formula alone can lose a few digits of precision to cancellation.
  public static func realRoots(coefficients: [Double]) -> [Double] {
    let degree = coefficients.count - 1
    let roots: [Double]
    switch degree {
    case 1: roots = linearRoot(coefficients).map { [$0] } ?? []
    case 2: roots = quadraticRoots(coefficients)
    case 3: roots = cubicRoots(coefficients)
    default: roots = []
    }
    return roots.map { polish($0, coefficients: coefficients) }
  }

  private static func linearRoot(_ c: [Double]) -> Double? {
    guard c[1] != 0 else { return nil }
    return -c[0] / c[1]
  }

  private static func quadraticRoots(_ c: [Double]) -> [Double] {
    let (a, b, cc) = (c[2], c[1], c[0])
    guard a != 0 else { return linearRoot([cc, b]).map { [$0] } ?? [] }
    let discriminant = b * b - 4 * a * cc
    guard discriminant >= 0 else { return [] }
    let sqrtDiscriminant = discriminant.squareRoot()
    return [(-b + sqrtDiscriminant) / (2 * a), (-b - sqrtDiscriminant) / (2 * a)]
  }

  /// Standard depressed-cubic method: substitute `x = t - b/(3a)` to eliminate the quadratic
  /// term, giving `t³ + pt + q = 0`, then branch on the discriminant `Δ = -4p³ - 27q²` — three
  /// real roots via the trigonometric form when `Δ > 0`, one real root via Cardano's radical
  /// form when `Δ ≤ 0`.
  private static func cubicRoots(_ c: [Double]) -> [Double] {
    let (a, b, cc, d) = (c[3], c[2], c[1], c[0])
    guard a != 0 else { return quadraticRoots([d, cc, b]) }

    let shift = b / (3 * a)
    let p = cc / a - b * b / (3 * a * a)
    let q = 2 * b * b * b / (27 * a * a * a) - b * cc / (3 * a * a) + d / a

    let discriminant = -4 * p * p * p - 27 * q * q
    var t: [Double] = []
    if discriminant > 0 {
      let magnitude = 2 * (-p / 3).squareRoot()
      let angle = acos(clamping((3 * q) / (2 * p) * (-3 / p).squareRoot(), to: -1...1))
      for k in 0..<3 {
        t.append(magnitude * cos(angle / 3 - 2 * .pi * Double(k) / 3))
      }
    } else {
      let inner = (q * q / 4 + p * p * p / 27).squareRoot()
      let u = cubeRoot(-q / 2 + inner)
      let v = cubeRoot(-q / 2 - inner)
      t.append(u + v)
    }
    return t.map { $0 - shift }
  }

  private static func cubeRoot(_ x: Double) -> Double {
    x < 0 ? -pow(-x, 1.0 / 3.0) : pow(x, 1.0 / 3.0)
  }

  private static func clamping(_ value: Double, to range: ClosedRange<Double>) -> Double {
    min(max(value, range.lowerBound), range.upperBound)
  }

  private static func polish(_ root: Double, coefficients c: [Double]) -> Double {
    let value = c.enumerated().reduce(0.0) { $0 + $1.element * pow(root, Double($1.offset)) }
    let derivative = c.enumerated().dropFirst().reduce(0.0) {
      $0 + $1.element * Double($1.offset) * pow(root, Double($1.offset - 1))
    }
    guard derivative != 0 else { return root }
    return root - value / derivative
  }

  /// A fixed 6-iteration Newton solve for `function(x) = 0` — no elementary inverse exists for
  /// `n·log n = K` (Lambert-*W*), but the function is smooth and monotonic over any realistic
  /// array-size domain, so a handful of iterations converges to full `Double` precision from a
  /// reasonable seed. Still O(1)/deterministic: this is a fixed loop bound, not an
  /// until-convergence one, so it can't hang on a pathological input.
  public static func newton(
    seed: Double, iterations: Int = 6, function: (Double) -> Double,
    derivative: (Double) -> Double
  ) -> Double {
    var x = seed
    for _ in 0..<iterations {
      let derivativeValue = derivative(x)
      guard derivativeValue != 0 else { break }
      x -= function(x) / derivativeValue
    }
    return x
  }
}
