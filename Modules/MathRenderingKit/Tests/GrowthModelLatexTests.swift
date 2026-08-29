import AlgorithmKit
import Testing

@testable import MathRenderingKit

private func makeMetadata(detectedGrowthModel: DetectedGrowthModel?) -> AlgorithmMetadata {
  AlgorithmMetadata(
    displayName: "Fake",
    category: .exchange,
    sizeRange: 1...1,
    growthModel: OperationGrowthModel(anchorSize: 219, coefficients: [238_710, 2185, 5]),
    detectedGrowthModel: detectedGrowthModel,
    implementationComplexity: 0,
    stable: true,
    timeComplexity: ComplexityBounds(best: "O(1)", average: "O(1)", worst: "O(1)"),
    spaceComplexity: "O(1)",
    iconName: "fake"
  )
}

@Suite
struct GrowthModelLatexTests {
  @Test
  func detectedGrowthModelLatexIsNilWhenNoDetectedModelIsAvailable() {
    let metadata = makeMetadata(detectedGrowthModel: nil)
    #expect(metadata.detectedGrowthModelLatex == nil)
  }

  @Test
  func fittedGrowthModelLatexExpandsThePolynomialAscendingByPower() {
    let metadata = makeMetadata(detectedGrowthModel: nil)
    #expect(metadata.fittedGrowthModelLatex == "238710 + 2185(n - 219) + 5(n - 219)^{2}")
  }

  @Test
  func unconstrainedGrowthModelRendersAsZero() {
    #expect(OperationGrowthModel.unconstrained.latex == "0")
  }

  @Test
  func zeroCoefficientTermsAreDroppedWithoutALeadingSignOrZero() {
    let model = OperationGrowthModel(anchorSize: 0, coefficients: [0, 5])
    #expect(model.latex == "5n")
  }

  @Test
  func powerLawFormula() {
    let model = DetectedGrowthModel(family: .powerLaw, coefficients: [1.2, 1.8], rSquared: 0.99)
    #expect(model.latex == "1.2n^{1.8}")
  }

  @Test
  func powerLogFormula() {
    let model = DetectedGrowthModel(family: .powerLog, coefficients: [1.2, 1.8], rSquared: 0.99)
    #expect(model.latex == "1.2n^{1.8} \\log n")
  }

  @Test
  func polynomialInterceptFormulaReversesToAscendingPowerOrder() {
    // `[a, b, c]` for `a*n^2 + b*n + c` — the model's own descending-power convention, rendered
    // here ascending (matching the Taylor-polynomial rendering above) rather than re-sorted back
    // to conventional descending order.
    let model = DetectedGrowthModel(
      family: .polynomialIntercept, coefficients: [2, 3, 4], rSquared: 0.99)
    #expect(model.latex == "4 + 3n + 2n^{2}")
  }

  @Test
  func exponentialFormulaUsesAnExplicitTimesBetweenTwoBareNumerals() {
    let model = DetectedGrowthModel(family: .exponential, coefficients: [1.2, 1.05], rSquared: 0.99)
    #expect(model.latex == "1.2 \\times 1.05^{n}")
  }

  @Test
  func nToTheNLikeFormula() {
    let model = DetectedGrowthModel(family: .nToTheNLike, coefficients: [1.2, 0.9], rSquared: 0.99)
    #expect(model.latex == "1.2e^{0.9n \\log n}")
  }

  @Test
  func factorialFormula() {
    let model = DetectedGrowthModel(family: .factorial, coefficients: [1.2, 0.9], rSquared: 0.99)
    #expect(model.latex == "1.2e^{0.9(n \\log n - n)}")
  }

  /// Regression guard for the double-escaping bug fixed in commit `24c9393` (see
  /// `GrowthModelLatex.swift`'s doc comment): none of these LaTeX strings may ever contain two
  /// consecutive backslashes, which SwiftMath renders as a line break instead of the intended
  /// command.
  @Test
  func noProducedLatexEverContainsADoubleBackslash() {
    let samples: [String] = DetectedGrowthModel.Family.allCases.map {
      DetectedGrowthModel(family: $0, coefficients: [1.2, 1.8, 0.5], rSquared: 0.9).latex
    } + [OperationGrowthModel(anchorSize: 219, coefficients: [238_710, 2185, 5]).latex]

    for latex in samples {
      #expect(!latex.contains("\\\\"), "\(latex)")
    }
  }
}
