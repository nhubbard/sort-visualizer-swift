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
    func sampleSizesWalksEveryStepAcrossAWideRangeInsteadOfABoundedSampleCount() {
        // 16...512 steps by 16 (steppedSizeStep for a wide range) — every multiple of 16 from 16
        // through 512, not a handful of evenly-spaced samples.
        let sizes = ComplexityChart.sampleSizes(for: 16...512)
        #expect(sizes == Array(stride(from: 16, through: 512, by: 16)))
    }

    @Test
    func sampleSizesHandlesANarrowRangeWithoutCrashing() {
        // Width 12 (< 16), so steppedSizeStep is the full width — just the two endpoints.
        let sizes = ComplexityChart.sampleSizes(for: 4...16)

        #expect(sizes == [4, 16])
    }

    @Test
    func sampleSizesHandlesADegenerateSingleValueRange() {
        let sizes = ComplexityChart.sampleSizes(for: 8...8)
        #expect(sizes == [8])
    }
}
