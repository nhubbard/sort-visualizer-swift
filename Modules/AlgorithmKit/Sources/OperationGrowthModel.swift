import Foundation

/// A Taylor-polynomial approximation of one algorithm's real, measured operation-count growth
/// curve, expanded around `anchorSize` -- the array size that solves the real fitted curve for a
/// 300,000-operation cap (`Tools/GrowthModelCalibration`'s default reference cap). Every
/// algorithm, regardless of its real growth family (power law, exponential, factorial, ...), is
/// represented by this same general form:
///
///     predictedOperations(n) = Σ coefficients[i] * (n - anchorSize)^i
///
/// Only `anchorSize` and `coefficients` differ per algorithm -- `apply_growth_models.py` picks the
/// lowest polynomial order that stays within tolerance of the real fitted curve across the app's
/// full `recordingOperationCap` range (50,000...5,000,000), so most algorithms end up with 2-3
/// coefficients (a line or a parabola), but nothing here assumes a fixed order: a genuinely linear
/// or constant-growth algorithm just gets a shorter array, and a sharply curved one a longer one.
public struct OperationGrowthModel: Sendable, Codable, Equatable {
  public var anchorSize: Double
  /// `coefficients[i]` is the coefficient of `(n - anchorSize)^i`.
  public var coefficients: [Double]
  /// A hard ceiling from calibration's own hang/erratic-jump detection, independent of the curve
  /// math -- nil when calibration measured this algorithm cleanly all the way through.
  public var measuredSafeCeiling: Int?

  public init(anchorSize: Double, coefficients: [Double], measuredSafeCeiling: Int? = nil) {
    self.anchorSize = anchorSize
    self.coefficients = coefficients
    self.measuredSafeCeiling = measuredSafeCeiling
  }

  public func predictedOperations(atSize n: Double) -> Double {
    let x = n - anchorSize
    return coefficients.enumerated().reduce(0.0) { $0 + $1.element * pow(x, Double($1.offset)) }
  }

  /// Solves `predictedOperations(n) == cap * safetyMargin` for the largest safe `n`, then clamps
  /// to `measuredSafeCeiling` if present. Returns 0 if even `n = 1` isn't safe under this cap.
  public func maxSafeSize(forOperationCap cap: Int, safetyMargin: Double = 0.8) -> Int {
    let target = Double(cap) * safetyMargin
    guard predictedOperations(atSize: 1) <= target else { return 0 }

    var shifted = coefficients
    shifted[0] -= target
    guard let size = Self.solve(shifted, anchorSize: anchorSize) else {
      // No real crossing -- either the curve never reaches this cap (e.g. `.unconstrained`) or a
      // higher-order fit failed to converge. Falling back to `cap` itself (rather than something
      // unbounded like `Int.max`) keeps this safe to feed into `steppedValues(by:)` regardless.
      return measuredSafeCeiling ?? cap
    }
    let clamped = measuredSafeCeiling.map { Swift.min(size, Double($0)) } ?? size
    return Swift.max(0, Int(clamped.rounded(.down)))
  }

  /// The real root of `shifted[0] + shifted[1]*x + shifted[2]*x^2 + ... = 0` closest to `x = 0`
  /// (i.e. closest to `anchorSize`, where the Taylor expansion is most trustworthy), converted
  /// back to an array size. The curve this pipeline fits is monotonically increasing, so that's
  /// the one meaningful crossing -- farther roots (a cubic can have three) are artifacts of the
  /// polynomial's shape away from where it was actually fit.
  private static func solve(_ shifted: [Double], anchorSize: Double) -> Double? {
    let candidates: [Double]
    switch shifted.count {
    case 2...4:
      candidates = PolynomialRootSolver.realRoots(coefficients: shifted)
    case let count where count > 4:
      func evaluate(_ x: Double) -> Double {
        shifted.enumerated().reduce(0.0) { $0 + $1.element * pow(x, Double($1.offset)) }
      }
      func derivative(_ x: Double) -> Double {
        shifted.enumerated().dropFirst().reduce(0.0) {
          $0 + $1.element * Double($1.offset) * pow(x, Double($1.offset - 1))
        }
      }
      // Seed from the leading term's own order of magnitude, not x = 0 -- a pure high-order term
      // (no linear component) has a zero derivative at the origin, which would stall Newton on
      // its very first step.
      let degree = shifted.count - 1
      let leadingCoefficient = shifted[degree]
      let seed =
        leadingCoefficient != 0
        ? pow(abs(shifted[0] / leadingCoefficient), 1.0 / Double(degree)) : 1.0
      let root = PolynomialRootSolver.newton(
        seed: seed, iterations: 30, function: evaluate, derivative: derivative)
      let residualScale = Swift.max(1, abs(shifted[0]))
      candidates = root.isFinite && abs(evaluate(root)) < residualScale * 1e-4 ? [root] : []
    default:
      candidates = []
    }
    let reachable = candidates.filter { $0.isFinite && anchorSize + $0 >= 1 }
    guard let closestToAnchor = reachable.min(by: { abs($0) < abs($1) }) else { return nil }
    return anchorSize + closestToAnchor
  }

  /// A flat curve (`predictedOperations` is always 0) that never binds before any cap, so
  /// `AlgorithmMetadata.effectiveSizeRange` falls back to the raw operation cap -- for test
  /// fixtures that don't care about growth-model sizing.
  public static let unconstrained = OperationGrowthModel(anchorSize: 1, coefficients: [0])
}
