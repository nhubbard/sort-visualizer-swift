import AlgorithmKit
import SortEngineKit
import Testing

@testable import BuiltInAlgorithms

/// Covers every shuffle that used to be a `.js`/`.manifest.json` pair, back when the
/// (now-removed) `ScriptingKit` JS backend's `BundledContentCorrectnessTests` verified them, before
/// all 5 were ported to native Swift.
@Suite
struct NativeShuffleCorrectnessTests {
  private static let shuffles: [any ShuffleAlgorithm] = [
    AlmostShuffle(), AscendingShuffle(), BlockRandomShuffle(), BSTTraversalShuffle(),
    CircleShuffle(),
    DescendingShuffle(), DoubleLayeredShuffle(), FinalBitonicShuffle(), FinalMergeShuffle(),
    FinalRadixShuffle(), GrayCodeShuffle(), HalfRotationShuffle(), HeapifiedShuffle(),
    InterlacedShuffle(), InvertedBSTShuffle(), LogarithmicSlopesShuffle(), MovedElementShuffle(),
    NaiveShuffle(), NoisyShuffle(), OrganShuffle(), PairwiseShuffle(), PartialReverseShuffle(),
    PartitionedShuffle(), QuicksortAdversaryShuffle(), RandomShuffle(), RealFinalMergeShuffle(),
    RealFinalRadixShuffle(), RecursiveRadixShuffle(), RecursiveReversalShuffle(), SawtoothShuffle(),
    ShuffledCubicShuffle(), ShuffledHalfShuffle(), ShuffledHeadShuffle(), ShuffledOddsShuffle(),
    ShuffledQuinticShuffle(), ShuffledTailShuffle(), SierpinskiShuffle(), TriangularShuffle()
  ]

  /// Unlike the curve shuffles (`ShuffledCubicShuffle`/`ShuffledQuinticShuffle`), these shuffles
  /// only rearrange existing values, so they owe a stronger guarantee than the length-only check
  /// above: the output must be a genuine permutation of the input.
  ///
  /// `LogarithmicSlopesShuffle` is excluded: ArrayV's own `2 * (i - power) + 1` index formula
  /// reads the same low indices repeatedly (e.g. at size 4, both `i = 1` and `i = 2` read index
  /// 1), producing duplicate values and dropping others — a real property of the formula itself,
  /// not an artifact of this app's 1-indexed values.
  private static let permutingShuffles: [any ShuffleAlgorithm] = [
    AlmostShuffle(), BlockRandomShuffle(), BSTTraversalShuffle(), CircleShuffle(),
    DoubleLayeredShuffle(),
    FinalBitonicShuffle(), FinalMergeShuffle(), FinalRadixShuffle(), GrayCodeShuffle(),
    HalfRotationShuffle(), HeapifiedShuffle(), InterlacedShuffle(), InvertedBSTShuffle(),
    MovedElementShuffle(), NaiveShuffle(), NoisyShuffle(), OrganShuffle(),
    PairwiseShuffle(), PartialReverseShuffle(), PartitionedShuffle(), QuicksortAdversaryShuffle(),
    RealFinalMergeShuffle(), RealFinalRadixShuffle(), RecursiveRadixShuffle(),
    RecursiveReversalShuffle(),
    SawtoothShuffle(), ShuffledHalfShuffle(), ShuffledHeadShuffle(), ShuffledOddsShuffle(),
    ShuffledTailShuffle(), SierpinskiShuffle(), TriangularShuffle()
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
      #expect(
        engine.values.count == identity.count, "\(shuffle.id.rawValue) changed the array's length")
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
  func everyPermutingShuffleIsAGenuinePermutationAcrossManySizes() {
    // 16 covers most of these comfortably; a couple (BSTTraversalShuffle/InvertedBSTShuffle's
    // queue-based level order, TriangularShuffle/SierpinskiShuffle's recursive index-permutation
    // builders) are index-structural rather than size-sensitive, so one mid-sized value per
    // shuffle is enough to catch a real permutation bug without re-deriving each one's own
    // preferred size range.
    for size in [1, 2, 3, 4, 5, 8, 16, 17, 32, 63, 100] {
      let identity = Array(1...size)
      for shuffle in Self.permutingShuffles {
        var engine = RecordingEngine(values: identity)
        shuffle.record(into: &engine)

        #expect(
          engine.values.sorted() == identity,
          "\(shuffle.id.rawValue) at size \(size) produced a non-permutation: \(identity) -> \(engine.values)"
        )
      }
    }
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
