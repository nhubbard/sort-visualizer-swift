import Foundation

/// The real growth family `Tools/GrowthModelCalibration` detected for this algorithm, before it
/// gets Taylor-expanded into the generic polynomial the app actually uses for sizing
/// (`OperationGrowthModel`). Shipped purely as display metadata — nothing in the app's own sizing
/// math reads this — so a user can see what the algorithm's real measured complexity looks like
/// alongside the polynomial approximation the size stepper is actually built from.
///
/// Deliberately duplicates `CurveFitting.swift`'s `GrowthFamily.predict` (in
/// `Modules/BuiltInAlgorithms/Tests/Support/`, a test target this shipped module can't import
/// from) rather than sharing code with it. Six small, stable formulas is a cheap duplication;
/// keep the two in sync by hand if a family's formula ever changes.
public struct DetectedGrowthModel: Sendable, Codable, Equatable {
  /// One of `CurveFitting.GrowthFamily`'s six candidate shapes, identified by the same raw
  /// string values so `Tools/GrowthModelCalibration/apply_detected_models.py` can pass
  /// `winningFamily` straight through without a translation table.
  public enum Family: String, Sendable, Codable, CaseIterable {
    /// `T = a·nᵏ` — coefficients `[a, k]`.
    case powerLaw
    /// `T = a·nᵏ·log n` — coefficients `[a, k]`.
    case powerLog
    /// `T = a·n² + b·n + c` — coefficients `[a, b, c]`.
    case polynomialIntercept
    /// `T = a·bⁿ` — coefficients `[a, b]`.
    case exponential
    /// `T = a·exp(c·n·log n)` — coefficients `[a, c]`.
    case nToTheNLike
    /// `T = a·exp(c·(n·log n − n))` — coefficients `[a, c]`.
    case factorial
  }

  public var family: Family
  /// The winning family's own fitted parameters — meaning depends on `family`, see each case's
  /// doc comment above.
  public var coefficients: [Double]
  /// Coefficient of determination of the fit, on the real (untransformed) operation-count scale.
  public var rSquared: Double

  public init(family: Family, coefficients: [Double], rSquared: Double) {
    self.family = family
    self.coefficients = coefficients
    self.rSquared = rSquared
  }

  public func predictedOperations(atSize n: Double) -> Double {
    switch family {
    case .powerLaw: coefficients[0] * pow(n, coefficients[1])
    case .powerLog: coefficients[0] * pow(n, coefficients[1]) * log(n)
    case .polynomialIntercept: coefficients[0] * n * n + coefficients[1] * n + coefficients[2]
    case .exponential: coefficients[0] * pow(coefficients[1], n)
    case .nToTheNLike: coefficients[0] * exp(coefficients[1] * n * log(n))
    case .factorial: coefficients[0] * exp(coefficients[1] * (n * log(n) - n))
    }
  }
}
