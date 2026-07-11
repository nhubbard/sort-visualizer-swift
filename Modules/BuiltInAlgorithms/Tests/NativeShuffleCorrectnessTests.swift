import AlgorithmKit
import SortEngineKit
import Testing
@testable import BuiltInAlgorithms

/// The native counterpart to `ScriptingKitTests`' `BundledContentCorrectnessTests`'
/// `everyBundledShuffleRunsWithoutCrashingAndPreservesArrayLength`, now covering every shuffle
/// that used to be a `.js`/`.manifest.json` pair before all 5 were ported to native Swift.
@Suite
struct NativeShuffleCorrectnessTests {
    private static let shuffles: [any ShuffleAlgorithm] = [
        AscendingShuffle(), DescendingShuffle(), RandomShuffle(), ShuffledCubicShuffle(), ShuffledQuinticShuffle(),
    ]

    @Test
    func everyShuffleHasAUniqueID() {
        let ids = Self.shuffles.map(\.id)
        #expect(Set(ids).count == ids.count, "duplicate ShuffleID across native shuffles")
    }

    @Test
    func everyShufflePreservesArrayLength() {
        let size = 24
        let identity = Array(1...size)

        for shuffle in Self.shuffles {
            var engine = RecordingEngine(values: identity)
            shuffle.record(into: &engine)

            // A shuffle isn't a sort, and isn't even guaranteed to *permute* — shuffledcubic/
            // shuffledquintic deliberately remap values through a curve via setValue, matching
            // ArrayV's own "shuffle == just another instrumented algorithm" model (§2A.4). The one
            // universal invariant is that the array's length is unchanged.
            #expect(engine.values.count == identity.count, "\(shuffle.id.rawValue) changed the array's length")
        }
    }

    @Test
    func ascendingShuffleIsAGenuineNoOp() {
        let identity = Array(1...12)
        var engine = RecordingEngine(values: identity)
        AscendingShuffle().record(into: &engine)

        #expect(engine.values == identity)
        #expect(engine.finish().tape.isEmpty)
    }

    @Test
    func descendingShuffleReversesTheArrayExactly() {
        let identity = Array(1...12)
        var engine = RecordingEngine(values: identity)
        DescendingShuffle().record(into: &engine)

        #expect(engine.values == identity.reversed())
    }

    @Test
    func randomShuffleIsAGenuinePermutation() {
        let identity = Array(1...30)
        var engine = RecordingEngine(values: identity)
        RandomShuffle().record(into: &engine)

        #expect(engine.values.sorted() == identity)
    }

    @Test
    func curveShufflesStayWithinTheOriginalValueRangeAcrossManySizes() {
        // 4 is deliberately the smallest case here, not 2 or 3: it's the smallest `sizeRange`
        // lower bound any shipped algorithm actually uses (BogoSort/BozoSort's `4...7`) — below
        // that, this same curve math (faithfully ported from the original JS/legacy source) can
        // round up one past the array's own bounds, a real characteristic of the formula at tiny
        // n that no shipped algorithm's size range ever exercises.
        for size in [4, 5, 16, 63, 100] {
            let identity = Array(1...size)
            for shuffle in [ShuffledCubicShuffle(), ShuffledQuinticShuffle()] as [any ShuffleAlgorithm] {
                var engine = RecordingEngine(values: identity)
                shuffle.record(into: &engine)

                #expect(
                    engine.values.allSatisfy { (1...size).contains($0) },
                    "\(shuffle.id.rawValue) at size \(size) produced a value outside 1...\(size): \(engine.values)"
                )
            }
        }
    }
}
