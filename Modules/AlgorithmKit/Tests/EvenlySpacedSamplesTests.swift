import Testing
@testable import AlgorithmKit

@Suite
struct EvenlySpacedSamplesTests {
    @Test
    func narrowRangeYieldsEveryValidValue() {
        #expect((4...7).evenlySpacedSamples(count: 6) == [4, 5, 6, 7])
    }

    @Test
    func wideRangeYieldsEvenlySpacedSamplesIncludingBothEndpoints() {
        let sizes = (16...512).evenlySpacedSamples(count: 6)
        #expect(sizes.first == 16)
        #expect(sizes.last == 512)
        #expect(sizes == sizes.sorted())
        #expect(sizes.count <= 7)
    }

    @Test
    func singleValueRangeYieldsThatOneValue() {
        #expect((10...10).evenlySpacedSamples(count: 6) == [10])
    }

    @Test
    func steppedValuesWalksByExactStepThroughAWholeMultipleRange() {
        #expect((16...64).steppedValues(by: 16) == [16, 32, 48, 64])
    }

    @Test
    func steppedValuesAppendsTheUpperBoundWhenNotAnExactMultiple() {
        #expect((16...70).steppedValues(by: 16) == [16, 32, 48, 64, 70])
    }

    @Test
    func steppedValuesByOneYieldsEveryValueInANarrowRange() {
        #expect((4...7).steppedValues(by: 1) == [4, 5, 6, 7])
    }

    @Test
    func steppedValuesSingleValueRangeYieldsThatOneValue() {
        #expect((10...10).steppedValues(by: 16) == [10])
    }
}
