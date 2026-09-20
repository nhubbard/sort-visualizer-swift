import Testing

@testable import AlgorithmKit

@Suite
struct AlgorithmMetadataTests {
  private func metadata(sizeRange: ClosedRange<Int>) -> AlgorithmMetadata {
    AlgorithmMetadata(
      displayName: "Fake",
      category: .exchange,
      sizeRange: sizeRange,
      growthModel: .unconstrained,
      implementationComplexity: 0,
      stable: true,
      timeComplexity: ComplexityBounds(best: "O(1)", average: "O(1)", worst: "O(1)"),
      spaceComplexity: "O(1)",
      iconName: "fake"
    )
  }

  @Test
  func sizeStepIsSixteenForAWideRange() {
    #expect(metadata(sizeRange: 16...512).sizeStep == 16)
  }

  @Test
  func sizeStepIsTheFullRangeWidthForANarrowRange() {
    #expect(metadata(sizeRange: 4...7).sizeStep == 3)
  }

  @Test
  func sizeStepIsAtLeastOneForASingleValueRange() {
    #expect(metadata(sizeRange: 10...10).sizeStep == 1)
  }

  private func metadata(
    sizeRange: ClosedRange<Int>, growthModel: OperationGrowthModel,
    detectedGrowthModel: DetectedGrowthModel?
  ) -> AlgorithmMetadata {
    AlgorithmMetadata(
      displayName: "Fake",
      category: .exchange,
      sizeRange: sizeRange,
      growthModel: growthModel,
      detectedGrowthModel: detectedGrowthModel,
      implementationComplexity: 0,
      stable: true,
      timeComplexity: ComplexityBounds(best: "O(1)", average: "O(1)", worst: "O(1)"),
      spaceComplexity: "O(1)",
      iconName: "fake"
    )
  }

  @Test
  func estimatedOperationsUsesTheDetectedFamilyNotTheAnchoredTaylorPolynomial() {
    // Mirrors the real Cocktail Merge Sort regression: growthModel is anchored at n = 756 (a size
    // this app never displays) and would extrapolate to a nonsensical negative value at n = 256
    // if it were the curve evaluated here.
    let model = metadata(
      sizeRange: 16...256,
      growthModel: OperationGrowthModel(
        anchorSize: 756,
        coefficients: [239683, 1763.36, 6.48657, 0.0159073, 2.92578e-05, 4.30503e-08]),
      detectedGrowthModel: DetectedGrowthModel(
        family: .exponential, coefficients: [920.704, 1.00738], rSquared: 0.808132)
    )
    let ops = model.estimatedOperations(atSize: 256)
    #expect(ops != nil)
    #expect(ops! > 0)
    #expect(abs(ops! - 6047.99) < 1)
  }

  @Test
  func estimatedOperationsIsNilWithoutADetectedGrowthModel() {
    let model = metadata(
      sizeRange: 16...256, growthModel: .unconstrained, detectedGrowthModel: nil)
    #expect(model.estimatedOperations(atSize: 256) == nil)
  }

  @Test
  func estimatedOperationsIsNilOutsideSizeRangeEvenWithADetectedGrowthModel() {
    let model = metadata(
      sizeRange: 4...8, growthModel: .unconstrained,
      detectedGrowthModel: DetectedGrowthModel(
        family: .powerLaw, coefficients: [1, 2], rSquared: 1))
    #expect(model.estimatedOperations(atSize: 256) == nil)
  }
}
