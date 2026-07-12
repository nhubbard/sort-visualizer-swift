import Testing
@testable import SortFeature

/// `DisparityCircleMetalLayout`/`SpiralMetalLayout` are the two wedge layouts with a non-identity
/// `slots(forIndex:)` (`ColorCircleMetalLayout`'s geometry is purely positional — see its own doc
/// comment) — wedge `j`'s triangle reads `values[j]` and `values[j-1]` (its own point plus its
/// predecessor's), so the set of indices whose `slots(forIndex:)` must include slot `j` is exactly
/// `{j, j-1 mod count}`, equivalently: `slots(forIndex: i) == [i, (i+1) % count]` for every `i`.
/// Verified directly rather than trusted by inspection — the same discipline
/// `MetalShapeLayoutTests` applies to `PixelMeshMetalLayout`/`HoopStackMetalLayout`.
@Suite
struct MetalTriangleLayoutTests {
    @Test(arguments: [2, 3, 4, 5, 10, 100])
    func disparityCircleSlotMappingCoversExactlyItsTwoDependencies(count: Int) {
        assertWedgeSlotMapping(DisparityCircleMetalLayout.slots, count: count)
    }

    @Test(arguments: [2, 3, 4, 5, 10, 100])
    func spiralSlotMappingCoversExactlyItsTwoDependencies(count: Int) {
        assertWedgeSlotMapping(SpiralMetalLayout.slots, count: count)
    }

    @Test(arguments: [2, 3, 4, 5, 10, 100])
    func colorCircleSlotMappingStaysIdentity(count: Int) {
        // Confirms the doc-comment claim directly: ColorCircle's geometry never depends on a
        // neighbor's value, so it must NOT override the default identity mapping.
        for index in 0..<count {
            #expect(ColorCircleMetalLayout.slots(forIndex: index, count: count) == [index])
        }
    }

    private func assertWedgeSlotMapping(_ slots: (Int, Int) -> [Int], count: Int) {
        for index in 0..<count {
            #expect(slots(index, count) == [index, (index + 1) % count])
        }
    }
}
