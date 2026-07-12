import Testing
@testable import AlgorithmKit

@Suite
struct AlgorithmMetadataTests {
    private func metadata(sizeRange: ClosedRange<Int>) -> AlgorithmMetadata {
        AlgorithmMetadata(
            displayName: "Fake",
            category: .exchange,
            sizeRange: sizeRange,
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
}
