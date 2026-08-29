import Foundation
import Testing

@testable import AlgorithmKit

@Suite
struct OperationGrowthModelTests {
  @Test
  func predictedOperationsEvaluatesTheTaylorPolynomialAroundTheAnchor() {
    // T(x) = 10 + 3x + 2x^2, anchored at n0 = 100 -> T(103) = 10 + 3*3 + 2*9 = 37
    let model = OperationGrowthModel(anchorSize: 100, coefficients: [10, 3, 2])
    #expect(abs(model.predictedOperations(atSize: 103) - 37) < 1e-9)
    #expect(abs(model.predictedOperations(atSize: 100) - 10) < 1e-9)
  }

  @Test
  func maxSafeSizeSolvesAKnownLinearCase() {
    // T(n) = 5*n exactly (anchored at 0), cap = 1000, margin = 0.8 -> T(n) = 800 -> n = 160
    let model = OperationGrowthModel(anchorSize: 0, coefficients: [0, 5])
    #expect(model.maxSafeSize(forOperationCap: 1000) == 160)
  }

  @Test
  func maxSafeSizeSolvesAKnownQuadraticCaseViaRealRoots() {
    // T(n) = n^2 exactly (anchored at 0), cap = 1000, margin = 0.8 -> n = sqrt(800) ~= 28.28
    let model = OperationGrowthModel(anchorSize: 0, coefficients: [0, 0, 1])
    #expect(model.maxSafeSize(forOperationCap: 1000) == 28)
  }

  @Test
  func maxSafeSizeFallsBackToNewtonForOrderFourAndAbove() {
    // T(x) = x^4, anchored at 0. cap = 1_000_000, margin = 0.8 -> x = 800_000^0.25 ~= 29.9
    let model = OperationGrowthModel(anchorSize: 0, coefficients: [0, 0, 0, 0, 1])
    let size = model.maxSafeSize(forOperationCap: 1_000_000)
    #expect(size == 29)
  }

  @Test
  func measuredSafeCeilingClampsBelowWhatTheCurveAloneWouldAllow() {
    // A curve that only reaches the cap at an enormous n, but calibration measured a hang at 50.
    let model = OperationGrowthModel(anchorSize: 0, coefficients: [0, 1e-9], measuredSafeCeiling: 50)
    #expect(model.maxSafeSize(forOperationCap: 1_000_000) == 50)
  }

  @Test
  func returnsZeroWhenEvenSizeOneIsUnsafe() {
    // T(1) = 100, but the cap*margin target is only 4 -- nothing is safe.
    let model = OperationGrowthModel(anchorSize: 0, coefficients: [100, 1])
    #expect(model.maxSafeSize(forOperationCap: 5) == 0)
  }

  @Test
  func unconstrainedNeverBindsBeforeTheOperationCapItself() {
    #expect(OperationGrowthModel.unconstrained.maxSafeSize(forOperationCap: 300_000) == 300_000)
  }

  @Test
  func effectiveSizeRangePreservesLowerBoundAndDegradesUnderAnImpossiblyTinyCap() {
    let metadata = AlgorithmMetadata(
      displayName: "Fake",
      category: .exchange,
      sizeRange: 4...256,
      growthModel: OperationGrowthModel(anchorSize: 0, coefficients: [100, 1]),
      implementationComplexity: 0,
      stable: true,
      timeComplexity: ComplexityBounds(best: "O(1)", average: "O(1)", worst: "O(1)"),
      spaceComplexity: "O(1)",
      iconName: "fake"
    )
    let range = metadata.effectiveSizeRange(operationCap: 1)
    #expect(range == 4...4)
  }
}
