import Testing
@testable import SortFeature

/// `PixelMeshMetalLayout`/`HoopStackMetalLayout` are the two layouts with a non-identity slot
/// mapping — the rest are trivially `slots(forIndex:) == [index]`, not worth a dedicated test.
/// These verify the mapping is a true, exhaustive bijection (every slot claimed by exactly one
/// index's `slots(forIndex:)`, and `arrayIndex(forSlot:)` agrees) across a range of array sizes,
/// including non-perfect-squares — the case `PixelMeshMetalLayout` exists to handle at all — rather
/// than trusting the hand-derived inverse-range arithmetic by inspection alone.
@Suite
struct MetalShapeLayoutTests {
    @Test(arguments: [1, 2, 3, 4, 5, 7, 8, 10, 15, 16, 17, 50, 63, 64, 65, 100, 200, 255, 256])
    func pixelMeshSlotMappingIsExhaustiveBijection(count: Int) {
        let cellCount = PixelMeshMetalLayout.instanceCount(for: count)
        #expect(cellCount >= count, "grid must have at least as many cells as array elements")

        var claimedBy = [Int?](repeating: nil, count: cellCount)
        for index in 0..<count {
            for slot in PixelMeshMetalLayout.slots(forIndex: index, count: count) {
                #expect((0..<cellCount).contains(slot), "slot \(slot) out of range for count=\(count)")
                #expect(claimedBy[slot] == nil, "slot \(slot) claimed by both \(claimedBy[slot] ?? -1) and \(index)")
                claimedBy[slot] = index
                #expect(
                    PixelMeshMetalLayout.arrayIndex(forSlot: slot, count: count) == index,
                    "arrayIndex(forSlot:) must agree with the index that claimed it via slots(forIndex:)"
                )
            }
        }
        for slot in 0..<cellCount {
            #expect(claimedBy[slot] != nil, "slot \(slot) (count=\(count)) claimed by no index — a cell would never repaint")
        }
    }

    @Test(arguments: [1, 2, 3, 4, 5, 10, 100])
    func hoopStackSlotMappingIsReversedBijection(count: Int) {
        for index in 0..<count {
            let slots = HoopStackMetalLayout.slots(forIndex: index, count: count)
            #expect(slots == [count - 1 - index])
            #expect(HoopStackMetalLayout.arrayIndex(forSlot: slots[0], count: count) == index)
        }
    }
}
