import Testing
@testable import BenchmarkFeature

@Suite
struct ComplexityChartTests {
    @Test
    func sampleSizesStaysWithinRangeAndIncludesBothEndpoints() {
        let sizes = ComplexityChart.sampleSizes(for: 16...512)

        #expect(sizes.first == 16)
        #expect(sizes.last == 512)
        #expect(sizes.allSatisfy { (16...512).contains($0) })
        #expect(sizes == sizes.sorted())
        #expect(Set(sizes).count == sizes.count) // no duplicate sizes
    }

    @Test
    func sampleSizesHandlesANarrowRangeWithoutCrashing() {
        // Bogo Sort's real sizeRange — narrower than the usual sample count.
        let sizes = ComplexityChart.sampleSizes(for: 4...16)

        #expect(sizes.first == 4)
        #expect(sizes.last == 16)
        #expect(sizes.allSatisfy { (4...16).contains($0) })
    }

    @Test
    func sampleSizesHandlesADegenerateSingleValueRange() {
        let sizes = ComplexityChart.sampleSizes(for: 8...8)
        #expect(sizes == [8])
    }
}
