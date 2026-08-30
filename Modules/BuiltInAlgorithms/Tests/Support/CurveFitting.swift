import AlgorithmKit
import Foundation

/// One data point from the benchmark: array size and the (adaptively-sampled, stable) mean
/// measured operation count at that size.
struct GrowthSample {
  let n: Double
  let value: Double
}

/// Candidate growth-model shapes the calibration benchmark fits empirically to measured data —
/// see the "Curve-fitting methodology" section of the growth-model calibration plan for the
/// linearizing transform behind each. Deliberately doesn't reuse `BigOShape` directly: these are
/// *fitted* models with their own scale/rate coefficients, where `BigOShape` is a bare shape
/// evaluator with an implicit leading coefficient of 1.
enum GrowthFamily: String, CaseIterable {
  /// `T = a·nᵏ` — coefficients `[a, k]`.
  case powerLaw
  /// `T = a·nᵏ·log n` — coefficients `[a, k]`. The one family with no elementary inverse; solving
  /// `f(n) = C` for this family needs the Taylor/SymPy bridge.
  case powerLog
  /// `T = a·n² + b·n + c` — coefficients `[a, b, c]`.
  case polynomialIntercept
  /// `T = a·bⁿ` — coefficients `[a, b]`.
  case exponential
  /// `T = a·exp(c·n·log n)` (equivalently `a·n^(c·n)`) — coefficients `[a, c]`. Real `n^n`-like
  /// growth (`OptimizedGuessSort`'s odometer, `c ≈ 1`).
  case nToTheNLike
  /// `T = a·exp(c·(n·log n − n))` — coefficients `[a, c]`. Stirling's approximation
  /// (`log(n!) ≈ n·log n − n`) generalized with a free rate `c`, distinct from `nToTheNLike`: the
  /// `−n` correction term is *not* negligible at the array sizes this benchmark can directly
  /// measure (it's ~22% of the leading term even at `n = 100`), so a dataset that's genuinely
  /// factorial-shaped fits this family measurably better than `nToTheNLike`, and vice versa —
  /// worth keeping as its own candidate rather than assuming one subsumes the other.
  case factorial

  /// Free parameters each shape's coefficients array holds — the whole reason this exists is to
  /// gate model selection on degrees of freedom (`usable sample count − parameterCount`), not
  /// just raw R². A model with as many parameters as it has nearby data points can score a
  /// near-perfect R² by threading the needle through those exact points while being nonsense
  /// everywhere else — `polynomialIntercept`'s 3 parameters fit to 4 sparse points from
  /// `bogosort+heapified` produced a "fit" predicting ~8.5 million ops at `n = 1`, a size that
  /// wasn't even in the sample. Never trust a fit with fewer than 2 degrees of freedom.
  var parameterCount: Int {
    self == .polynomialIntercept ? 3 : 2
  }

  func predict(coefficients c: [Double], n: Double) -> Double {
    switch self {
    case .powerLaw: return c[0] * pow(n, c[1])
    case .powerLog: return c[0] * pow(n, c[1]) * log(n)
    case .polynomialIntercept: return c[0] * n * n + c[1] * n + c[2]
    case .exponential: return c[0] * pow(c[1], n)
    case .nToTheNLike: return c[0] * exp(c[1] * n * log(n))
    case .factorial: return c[0] * exp(c[1] * (n * log(n) - n))
    }
  }
}

struct FittedGrowthModel {
  let family: GrowthFamily
  let coefficients: [Double]
  /// Coefficient of determination computed on the *untransformed* scale (real operation counts,
  /// not the log-space the regression itself ran in) — a fit that looks excellent in log-space
  /// can still track the real values poorly right where extrapolation matters most.
  let rSquared: Double
  /// `1 − (1 − R²)·(n − 1)/(n − p − 1)` — `rSquared` penalized for how little slack the fit had
  /// (`n` usable samples against `p` free parameters). This, not raw `rSquared`, is what
  /// `bestFit` actually compares models on: a 3-parameter fit squeezed against 4 points has just
  /// 0 degrees of freedom and is excluded outright (see `GrowthFamily.parameterCount`) rather
  /// than merely penalized, since adjusted R² itself is undefined/unstable right at that boundary.
  let adjustedRSquared: Double

  func predict(n: Double) -> Double {
    family.predict(coefficients: coefficients, n: n)
  }
}

enum CurveFitting {
  /// Fits every family in `GrowthFamily.allCases` that has enough *usable* data points (after
  /// each family's own filtering, e.g. `n > 1`) to leave at least 2 degrees of freedom —
  /// `usableCount >= parameterCount + 2` — returning whichever succeeded. Always at least empty,
  /// never a partial/garbage fit from an over-parameterized model with too little data to
  /// constrain it.
  static func fitAllFamilies(_ samples: [GrowthSample]) -> [FittedGrowthModel] {
    [
      fitPowerLaw(samples), fitPowerLog(samples), fitPolynomialIntercept(samples),
      fitExponential(samples), fitNToTheNLike(samples), fitFactorial(samples)
    ].compactMap { $0 }
  }

  /// The best-fitting family by adjusted R² (see `FittedGrowthModel.adjustedRSquared`), with the
  /// algorithm's *declared* complexity used only as a tie-break between near-equally-good fits
  /// (within 0.02 adjusted R²) — never as a hard constraint, since declared complexity can simply
  /// be wrong (that's the entire premise behind needing this benchmark). `declaredShape` comes
  /// from `BigOShape.parse` against `AlgorithmMetadata.timeComplexity.worst`.
  static func bestFit(_ samples: [GrowthSample], declaredShape: BigOShape?) -> FittedGrowthModel? {
    let fits = fitAllFamilies(samples).sorted { $0.adjustedRSquared > $1.adjustedRSquared }
    guard let best = fits.first else { return nil }
    guard let declaredShape, let preferredFamily = family(matching: declaredShape) else {
      return best
    }
    guard
      let preferredFit = fits.first(where: { $0.family == preferredFamily }),
      best.adjustedRSquared - preferredFit.adjustedRSquared < 0.02
    else { return best }
    return preferredFit
  }

  private static func family(matching shape: BigOShape) -> GrowthFamily? {
    switch shape {
    case .constant, .logarithmic, .logarithmicSquared, .linear: return .powerLaw
    // `.polynomialIntercept` is a *fixed*-degree-2 shape (`a*n^2 + b*n + c`) -- a real structural
    // match only for a declared exponent of exactly 2. Any other declared polynomial degree (3,
    // 4, 2.71, ...) needs `.powerLaw`'s free exponent instead; matching every `.polynomial(_)` to
    // `.polynomialIntercept` regardless of its associated exponent (the bug this replaced) meant
    // a declared `O(n^3)` would still tie-break toward a family that can't represent cubic growth
    // at scale, no matter how badly it underfits next to the correct `powerLaw(k≈3)` candidate --
    // exactly what let ShoveSort's mislabeled `O(n^2)` (and, worse, would have kept doing so even
    // after correcting the label to `O(n^3)`) fight off `bestFit`'s own better-scoring pick.
    case .polynomial(let exponent): return exponent == 2 ? .polynomialIntercept : .powerLaw
    case .linearithmic, .linearithmicSquared: return .powerLog
    case .superLinearithmic, .nToTheN: return .nToTheNLike
    case .factorial: return .factorial
    case .exponential: return .exponential
    }
  }

  // MARK: - Per-family fits

  private static func fitPowerLaw(_ samples: [GrowthSample]) -> FittedGrowthModel? {
    let usable = samples.filter { $0.n > 0 && $0.value > 0 }
    guard usable.count >= GrowthFamily.powerLaw.parameterCount + 2 else { return nil }
    let regression = simpleLinearRegression(
      xs: usable.map { log($0.n) }, ys: usable.map { log($0.value) })
    let coefficients = [exp(regression.intercept), regression.slope]
    return makeFit(
      family: .powerLaw, coefficients: coefficients, usable: usable,
      predict: { GrowthFamily.powerLaw.predict(coefficients: coefficients, n: $0) })
  }

  private static func fitPowerLog(_ samples: [GrowthSample]) -> FittedGrowthModel? {
    let usable = samples.filter { $0.n > 1 && $0.value > 0 }
    guard usable.count >= GrowthFamily.powerLog.parameterCount + 2 else { return nil }
    let regression = simpleLinearRegression(
      xs: usable.map { log($0.n) },
      ys: usable.map { log($0.value) - log(log($0.n)) })
    let coefficients = [exp(regression.intercept), regression.slope]
    return makeFit(
      family: .powerLog, coefficients: coefficients, usable: usable,
      predict: { GrowthFamily.powerLog.predict(coefficients: coefficients, n: $0) })
  }

  private static func fitExponential(_ samples: [GrowthSample]) -> FittedGrowthModel? {
    let usable = samples.filter { $0.value > 0 }
    guard usable.count >= GrowthFamily.exponential.parameterCount + 2 else { return nil }
    let regression = simpleLinearRegression(
      xs: usable.map { $0.n }, ys: usable.map { log($0.value) })
    let coefficients = [exp(regression.intercept), exp(regression.slope)]
    return makeFit(
      family: .exponential, coefficients: coefficients, usable: usable,
      predict: { GrowthFamily.exponential.predict(coefficients: coefficients, n: $0) })
  }

  private static func fitNToTheNLike(_ samples: [GrowthSample]) -> FittedGrowthModel? {
    let usable = samples.filter { $0.n > 1 && $0.value > 0 }
    guard usable.count >= GrowthFamily.nToTheNLike.parameterCount + 2 else { return nil }
    let regression = simpleLinearRegression(
      xs: usable.map { $0.n * log($0.n) }, ys: usable.map { log($0.value) })
    let coefficients = [exp(regression.intercept), regression.slope]
    return makeFit(
      family: .nToTheNLike, coefficients: coefficients, usable: usable,
      predict: { GrowthFamily.nToTheNLike.predict(coefficients: coefficients, n: $0) })
  }

  private static func fitFactorial(_ samples: [GrowthSample]) -> FittedGrowthModel? {
    let usable = samples.filter { $0.n > 1 && $0.value > 0 }
    guard usable.count >= GrowthFamily.factorial.parameterCount + 2 else { return nil }
    let regression = simpleLinearRegression(
      xs: usable.map { $0.n * log($0.n) - $0.n }, ys: usable.map { log($0.value) })
    let coefficients = [exp(regression.intercept), regression.slope]
    return makeFit(
      family: .factorial, coefficients: coefficients, usable: usable,
      predict: { GrowthFamily.factorial.predict(coefficients: coefficients, n: $0) })
  }

  /// The one family that isn't linearizable by a transform — an ordinary 3-parameter least
  /// squares fit of `T = a·n² + b·n + c`, solved via the 3×3 normal equations.
  private static func fitPolynomialIntercept(_ samples: [GrowthSample]) -> FittedGrowthModel? {
    guard samples.count >= GrowthFamily.polynomialIntercept.parameterCount + 2 else { return nil }

    var m00 = 0.0, m01 = 0.0, m02 = 0.0, m11 = 0.0, m12 = 0.0, m22 = Double(samples.count)
    var v0 = 0.0, v1 = 0.0, v2 = 0.0
    for sample in samples {
      let n = sample.n
      let n2 = n * n
      m00 += n2 * n2
      m01 += n2 * n
      m02 += n2
      m11 += n * n
      m12 += n
      v0 += n2 * sample.value
      v1 += n * sample.value
      v2 += sample.value
    }

    guard
      let coefficients = solve3x3(
        matrix: [[m00, m01, m02], [m01, m11, m12], [m02, m12, m22]], vector: [v0, v1, v2])
    else { return nil }

    return makeFit(
      family: .polynomialIntercept, coefficients: coefficients, usable: samples,
      predict: { GrowthFamily.polynomialIntercept.predict(coefficients: coefficients, n: $0) })
  }

  private static func makeFit(
    family: GrowthFamily, coefficients: [Double], usable: [GrowthSample],
    predict: @escaping (Double) -> Double
  ) -> FittedGrowthModel? {
    // A real operation count can't get cheaper as `n` grows -- a fit that dips down and rises
    // back up (only possible for `polynomialIntercept`'s independent linear+quadratic terms,
    // never for the other families' single-signed-rate constructions) means the model doesn't
    // represent the underlying relationship at all, even if it happens to score a decent R²
    // against a handful of sparse sample points. It's also actively dangerous downstream:
    // `solveForN`'s "smallest positive root" logic assumes a monotonic curve crosses the target
    // cap exactly once; a dip-then-rise shape can cross it twice, and picking the smaller
    // (pre-dip) root as the "safe" size produced a genuinely non-monotonic
    // `quickbogosort+logslopes` result (100K cap → size 1, 300K cap → size 4) before this check
    // existed. Checked across a fine grid from the smallest sample to well past the largest, to
    // catch a dip anywhere in or near the region any solve could land in.
    guard let maxN = usable.map(\.n).max() else { return nil }
    // Starting from `n = 1`, not the smallest *measured* size -- a dip below the sampled range
    // is exactly as dangerous as one inside it (the original `bogosort+heapified` bug was a fit
    // that predicted ~8.5 million ops at n=1, well below its smallest sample of 4).
    //
    // Two separate grids, not one spanning `[1, maxN * 100]` -- a single 200-step grid across
    // that full range spaces its points `maxN / 2` apart, which is *coarser* than `maxN` itself
    // whenever the real dip sits close to the origin relative to `maxN` (a `polynomialIntercept`
    // fit's vertex can land anywhere; ShoveSort's real calibration data, sampled out to n=304,
    // produced a fit whose vertex sat at n≈55 -- entirely inside the grid's very first gap, `[1,
    // 153]`, so the check saw it dip from 1.3M straight to 44M and called that "nondecreasing"
    // while silently skipping straight over a swing down to -764K in between). Checking `[1,
    // maxN]` on its own dense grid guarantees resolving anything narrower than `maxN / 200` in
    // the one region every dip risk actually derives from (a fit's own parameters, shaped by
    // wherever the real samples were); `(maxN, maxN * 100]` only needs enough resolution to catch
    // a curve turning back down somewhere in the pure-extrapolation tail beyond the data.
    guard isMonotonicallyNondecreasing(predict, from: 1, to: maxN),
      isMonotonicallyNondecreasing(predict, from: maxN, to: maxN * 100)
    else {
      return nil
    }

    let rSquared = untransformedRSquared(samples: usable, predict: predict)
    return FittedGrowthModel(
      family: family, coefficients: coefficients, rSquared: rSquared,
      adjustedRSquared: adjustedRSquared(
        rSquared, sampleCount: usable.count, parameterCount: family.parameterCount))
  }

  private static func isMonotonicallyNondecreasing(
    _ predict: (Double) -> Double, from lowerBound: Double, to upperBound: Double, steps: Int = 200
  ) -> Bool {
    var previous = -Double.infinity
    for step in 0...steps {
      let n = lowerBound + (upperBound - lowerBound) * Double(step) / Double(steps)
      let value = predict(n)
      // `NaN` means the model broke down (e.g. a negative base to a fractional power) and can't
      // be trusted either way. `+infinity`, in contrast, is the *expected* outcome of evaluating
      // a genuinely fast-growing curve (exponential/factorial-like) 100x past its largest sample
      // -- still perfectly consistent with monotonic growth, so it short-circuits to "yes" rather
      // than being rejected the way an actual decrease would be.
      guard !value.isNaN else { return false }
      if value.isInfinite { return true }
      // A tiny tolerance for floating-point noise on an otherwise-flat stretch, not a loophole
      // for a genuine downward slope.
      if value < previous - max(abs(previous), 1) * 1e-9 { return false }
      previous = value
    }
    return true
  }

  // MARK: - Shared numerics

  private struct LinearRegressionResult {
    let slope: Double
    let intercept: Double
  }

  private static func simpleLinearRegression(xs: [Double], ys: [Double]) -> LinearRegressionResult {
    let count = Double(xs.count)
    let xMean = xs.reduce(0, +) / count
    let yMean = ys.reduce(0, +) / count
    var numerator = 0.0
    var denominator = 0.0
    for (x, y) in zip(xs, ys) {
      let dx = x - xMean
      numerator += dx * (y - yMean)
      denominator += dx * dx
    }
    let slope = denominator != 0 ? numerator / denominator : 0
    return LinearRegressionResult(slope: slope, intercept: yMean - slope * xMean)
  }

  /// Cramer's rule — small and fixed-size enough (always exactly 3×3 here) that a general matrix
  /// library would be overkill. Returns `nil` for a singular system (collinear/degenerate input).
  private static func solve3x3(matrix m: [[Double]], vector v: [Double]) -> [Double]? {
    func det3(_ a: [[Double]]) -> Double {
      a[0][0] * (a[1][1] * a[2][2] - a[1][2] * a[2][1])
        - a[0][1] * (a[1][0] * a[2][2] - a[1][2] * a[2][0])
        + a[0][2] * (a[1][0] * a[2][1] - a[1][1] * a[2][0])
    }

    let determinant = det3(m)
    guard abs(determinant) > 1e-12 else { return nil }

    func replacingColumn(_ column: Int) -> [[Double]] {
      (0..<3).map { row in
        (0..<3).map { col in col == column ? v[row] : m[row][col] }
      }
    }

    return (0..<3).map { det3(replacingColumn($0)) / determinant }
  }

  private static func untransformedRSquared(
    samples: [GrowthSample], predict: (Double) -> Double
  ) -> Double {
    let mean = samples.map(\.value).reduce(0, +) / Double(samples.count)
    let totalSumOfSquares = samples.reduce(0.0) { $0 + pow($1.value - mean, 2) }
    guard totalSumOfSquares > 0 else { return 1 }
    let residualSumOfSquares = samples.reduce(0.0) { $0 + pow($1.value - predict($1.n), 2) }
    return 1 - residualSumOfSquares / totalSumOfSquares
  }

  /// `sampleCount - parameterCount - 1` (degrees of freedom) is guaranteed `>= 1` by every fit
  /// function's `usable.count >= parameterCount + 2` guard above, so this is never dividing by
  /// zero — that guard is precisely what makes adjusted R² well-defined here at all.
  private static func adjustedRSquared(_ rSquared: Double, sampleCount: Int, parameterCount: Int)
    -> Double {
    let degreesOfFreedom = Double(sampleCount - parameterCount - 1)
    return 1 - (1 - rSquared) * Double(sampleCount - 1) / degreesOfFreedom
  }
}
