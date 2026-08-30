import Foundation
import Testing

@testable import BuiltInAlgorithms

@Suite
struct CurveFittingTests {
  @Test
  func recoversAKnownPowerLaw() {
    // T = 3*n^2, exactly -- should fit powerLaw (and polynomialIntercept) essentially perfectly.
    let samples = [8.0, 16, 32, 64, 128].map { GrowthSample(n: $0, value: 3 * $0 * $0) }
    let fit = CurveFitting.bestFit(samples, declaredShape: nil)
    #expect(fit != nil)
    #expect(fit!.rSquared > 0.999)
    #expect(abs(fit!.predict(n: 256) - 3 * 256 * 256) / (3 * 256 * 256) < 0.01)
  }

  @Test
  func recoversAKnownExponential() {
    // T = 5 * 2^n -- should clearly favor the exponential family over a power law.
    let samples = [4.0, 6, 8, 10, 12].map { GrowthSample(n: $0, value: 5 * pow(2, $0)) }
    let models = CurveFitting.fitAllFamilies(samples)
    let exponential = models.first { $0.family == .exponential }
    #expect(exponential != nil)
    #expect(exponential!.rSquared > 0.999)
    let best = CurveFitting.bestFit(samples, declaredShape: nil)
    #expect(best?.family == .exponential)
  }

  @Test
  func recoversAKnownFactorialShape() {
    // T = 2 * n! -- the factorial family (n*log(n) - n basis) should fit far better than a bare
    // power law or the n^n-like family (which is missing the -n Stirling correction).
    let samples = [4.0, 5, 6, 7, 8].map { n in
      GrowthSample(n: n, value: 2 * exp(lgamma(n + 1)))
    }
    let best = CurveFitting.bestFit(samples, declaredShape: nil)
    #expect(best?.family == .factorial)
    #expect(best!.rSquared > 0.999)
  }

  @Test
  func declaredShapeBreaksNearTies() {
    // T = n^2 exactly fits both `powerLaw` and `polynomialIntercept` (with a=1, b=0, c=0)
    // essentially perfectly, so R^2 alone can't distinguish them -- the declared shape should
    // decide which one wins instead of it being arbitrary based on iteration/insertion order.
    // 5 points (not fewer) so polynomialIntercept's 3-parameter fit still has 2 degrees of
    // freedom -- see `refusesAnOverParameterizedFitWithTooFewPoints` below for what happens when
    // it doesn't.
    let samples = [16.0, 32, 48, 56, 64].map { GrowthSample(n: $0, value: $0 * $0) }
    let best = CurveFitting.bestFit(samples, declaredShape: .polynomial(2))
    #expect(best?.family == .polynomialIntercept)
  }

  @Test
  func declaredCubicPrefersPowerLawNotPolynomialIntercept() {
    // Reproduces the real ShoveSort bug: `family(matching:)` used to map every declared
    // `.polynomial(_)` shape -- degree 3 included -- to the fixed-degree-2 `polynomialIntercept`
    // family, so a correctly-declared `O(n^3)` complexity still tie-broke toward a family that
    // can't structurally represent cubic growth, as long as its R² landed within 0.02 of the true
    // `powerLaw(k≈3)` winner. Over a narrow sampled range (ShoveSort's real calibration data
    // spanned just n=16 to n=38 before its safety ceiling stopped further sampling),
    // `polynomialIntercept` fits pure cubic data almost as well as `powerLaw` does (both score
    // essentially perfect R² here) -- exactly the near-tie that used to matter.
    let samples = [16.0, 17, 18, 19, 38].map { GrowthSample(n: $0, value: pow($0, 3)) }
    let best = CurveFitting.bestFit(samples, declaredShape: .polynomial(3))
    #expect(best?.family == .powerLaw)
  }

  @Test
  func refusesAnOverParameterizedFitWithTooFewPoints() {
    // Reproduces the real bug this guard fixes: `bogosort+heapified`'s actual measured data (4
    // points) let the 3-parameter `polynomialIntercept` family threads the needle through all 4
    // samples (near-perfect raw R²) while producing a curve that predicts ~8.5 million ops at
    // n=1 -- a value nowhere near any measured point. With only 2 degrees of freedom required
    // (parameterCount + 2 = 5), a 4-point sample must exclude `polynomialIntercept` entirely
    // rather than let it win on a technicality of raw R².
    let samples: [GrowthSample] = [
      GrowthSample(n: 4, value: 61), GrowthSample(n: 5, value: 89),
      GrowthSample(n: 6, value: 122), GrowthSample(n: 12, value: 353)
    ]
    let models = CurveFitting.fitAllFamilies(samples)
    #expect(!models.contains { $0.family == .polynomialIntercept })
    let best = CurveFitting.bestFit(samples, declaredShape: nil)
    #expect(best != nil)
    // Whatever wins with only 4 points, it must not predict something absurd at a size smaller
    // than every measured sample -- the exact symptom of the original bug.
    #expect(best!.predict(n: 1) < 10_000)
  }

  @Test
  func rejectsANonMonotonicFitEvenWithEnoughDegreesOfFreedom() {
    // Reproduces `quickbogosort+logslopes`'s real measured data (5 points -- enough for
    // `polynomialIntercept`'s 2 required degrees of freedom) which nonetheless fits a "smiling"
    // parabola that dips down around n=5 before rising -- not possible for a real operation
    // count, and fatal to `solveForN`'s single-crossing assumption (it produced a genuinely
    // non-monotonic result: a 100K op cap solved to a *larger* safe size than a 300K cap).
    let samples: [GrowthSample] = [
      GrowthSample(n: 4, value: 20), GrowthSample(n: 5, value: 15),
      GrowthSample(n: 6, value: 55), GrowthSample(n: 7, value: 480),
      GrowthSample(n: 14, value: 33_000)
    ]
    let models = CurveFitting.fitAllFamilies(samples)
    #expect(!models.contains { $0.family == .polynomialIntercept })
    // Every surviving family must be non-decreasing across a wide range -- not just at the
    // sampled points.
    for model in models {
      var previous = -Double.infinity
      for n in stride(from: 1.0, through: 1400.0, by: 7.0) {
        let value = model.predict(n: n)
        if value.isInfinite { break }
        #expect(value >= previous, "\(model.family) decreased at n=\(n)")
        previous = value
      }
    }
  }

  @Test
  func rejectsANonMonotonicFitWhoseDipIsNarrowRelativeToMaxN() {
    // Reproduces the real `shovesort+sawtooth` calibration data (widened sampling out to n=304
    // once ShoveSort's own O(n^3) complexity was correctly recognized instead of the mis-detected
    // O(n^2)/exponential label): fits a `polynomialIntercept` parabola whose vertex sits at
    // n≈54.7, dipping to *-764,748* before rising again to 44M by n=304. The old single
    // `isMonotonicallyNondecreasing(from: 1, to: maxN * 100)` grid (200 steps across
    // [1, 30_400]) spaces its points ~152 apart -- coarser than the ~55-wide dip itself, so every
    // grid point landed on either side of it without a single sample falling inside. Splitting
    // into a dense `[1, maxN]` grid plus a coarser `[maxN, maxN * 100]` one (this fix) guarantees
    // resolving anything narrower than `maxN / 200` in exactly the region every real dip risk
    // comes from.
    let samples: [GrowthSample] = [
      GrowthSample(n: 16, value: 2355), GrowthSample(n: 17, value: 3030),
      GrowthSample(n: 18, value: 3795), GrowthSample(n: 19, value: 4660),
      GrowthSample(n: 38, value: 58320), GrowthSample(n: 76, value: 585305),
      GrowthSample(n: 152, value: 5_239_545), GrowthSample(n: 304, value: 44_312_475)
    ]
    let models = CurveFitting.fitAllFamilies(samples)
    #expect(!models.contains { $0.family == .polynomialIntercept })
    for model in models {
      var previous = -Double.infinity
      for n in stride(from: 1.0, through: 30_400.0, by: 50.0) {
        let value = model.predict(n: n)
        if value.isInfinite { break }
        #expect(value >= previous, "\(model.family) decreased at n=\(n)")
        previous = value
      }
    }
  }
}

@Suite
struct AdaptiveSamplingTests {
  @Test
  func stopsEarlyForADeterministicMeasurement() {
    let result = AdaptiveSampling.sample(minTrials: 5, maxTrials: 200) { 42.0 }
    #expect(result.convergedByPrecision)
    #expect(result.statistics.count == 5)
    #expect(result.statistics.mean == 42.0)
  }

  @Test
  func convergesForANoisyMeasurement() {
    var generator = SystemRandomNumberGenerator()
    let result = AdaptiveSampling.sample(tolerance: 0.01, minTrials: 5, maxTrials: 200) {
      100.0 + Double.random(in: -2...2, using: &generator)
    }
    #expect(result.convergedByPrecision)
    #expect(abs(result.statistics.mean - 100) < 2)
  }

  @Test
  func givesUpAtMaxTrialsForAnUnstableMeasurement() {
    var generator = SystemRandomNumberGenerator()
    let result = AdaptiveSampling.sample(tolerance: 1e-9, minTrials: 5, maxTrials: 20) {
      Double.random(in: 1...1000, using: &generator)
    }
    #expect(!result.convergedByPrecision)
    #expect(result.statistics.count == 20)
  }
}
