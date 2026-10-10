import AlgorithmKit
import Foundation
import SortEngineKit
import Testing

@testable import BuiltInAlgorithms

/// Covers every shuffle that used to be a `.js`/`.manifest.json` pair, back when the
/// (now-removed) `ScriptingKit` JS backend's `BundledContentCorrectnessTests` verified them, before
/// all 5 were ported to native Swift.
@Suite
struct NativeShuffleCorrectnessTests {
  private static let shuffles: [any ShuffleAlgorithm] = AllBuiltInAlgorithms.shuffles

  /// Unlike the curve shuffles (`ShuffledCubicShuffle`/`ShuffledQuinticShuffle`), these shuffles
  /// only rearrange existing values, so they owe a stronger guarantee than the length-only check
  /// above: the output must be a genuine permutation of the input.
  ///
  /// `LogarithmicSlopesShuffle` is excluded: ArrayV's own `2 * (i - power) + 1` index formula
  /// reads the same low indices repeatedly (e.g. at size 4, both `i = 1` and `i = 2` read index
  /// 1), producing duplicate values and dropping others — a real property of the formula itself,
  /// not an artifact of this app's 1-indexed values.
  private static let permutingShuffles: [any ShuffleAlgorithm] = [
    AlmostShuffle(), AscendingShuffle(), BitReversalShuffle(), BlockRandomShuffle(), BlockReverseShuffle(),
    BSTTraversalShuffle(), CircleShuffle(), DescendingShuffle(), DoubleLayeredShuffle(),
    FinalBitonicShuffle(), FinalMergeShuffle(), FinalRadixShuffle(), GrailsortAdversaryShuffle(),
    GrayCodeShuffle(),
    HalfRotationShuffle(), HeapifiedShuffle(), InterlacedShuffle(), InvertedBSTShuffle(),
    MovedElementShuffle(), NoisyShuffle(), OrganShuffle(),
    PairwiseShuffle(), PartialReverseShuffle(), PartitionedShuffle(), PDQAdversaryShuffle(),
    QuicksortAdversaryShuffle(), RandomShuffle(),
    RealFinalMergeShuffle(), RealFinalRadixShuffle(), RecursiveRadixShuffle(),
    RecursiveReversalShuffle(),
    SawtoothShuffle(), ShuffleMergeAdversaryShuffle(), ShuffledHalfShuffle(), ShuffledHeadShuffle(),
    ShuffledOddsShuffle(),
    ShuffledTailShuffle(), SierpinskiShuffle(),
    TriangularHeapifiedShuffle(), TriangularShuffle()
  ]

  private static let exceptionalShuffleIDs: Set<ShuffleID> = [
    LogarithmicSlopesShuffle().id, ShuffledCubicShuffle().id, ShuffledQuinticShuffle().id
  ]

  @Test
  func everyShuffleHasAnExplicitOutputClassification() {
    let classified = Set(Self.permutingShuffles.map(\.id)).union(Self.exceptionalShuffleIDs)
    #expect(classified == Set(Self.shuffles.map(\.id)))
  }

  @Test
  func everyShuffleReproducesValuesAndOperationsForASeedAtBoundarySizes() {
    // The app's smallest selectable algorithm size is 4. Exercise both sides of power-of-two
    // boundaries and an odd larger size; fixed seeds include zero and the maximum UInt64.
    for size in [4, 7, 8, 9, 31, 32, 33, 127, 128, 129] {
      let initial = Array(1...size)
      for shuffle in Self.shuffles {
        for seed in [UInt64(0), 0xDEAD_BEEF_1234_5678, .max] {
          var first = RecordingEngine(values: initial, randomSeed: seed)
          var second = RecordingEngine(values: initial, randomSeed: seed)
          shuffle.record(into: &first)
          shuffle.record(into: &second)
          #expect(first.values == second.values, "\(shuffle.id.rawValue), size \(size), seed \(seed)")
          #expect(first.finish().tape == second.finish().tape,
                  "\(shuffle.id.rawValue) recorded different operations for seed \(seed)")
          #expect(!first.didExceedCap, "\(shuffle.id.rawValue) exceeded the test tape cap")

          if Self.exceptionalShuffleIDs.contains(shuffle.id) {
            #expect(first.values.count == size)
            #expect(first.values.allSatisfy { (1...size).contains($0) })
          } else {
            #expect(first.values.sorted() == initial,
                    "\(shuffle.id.rawValue) lost values at size \(size)")
          }
        }
      }
    }
  }

  @Test
  func randomShuffleUsesTheSuppliedSeed() {
    let initial = Array(1...128)
    var first = RecordingEngine(values: initial, randomSeed: 1)
    var second = RecordingEngine(values: initial, randomSeed: 2)
    RandomShuffle().record(into: &first)
    RandomShuffle().record(into: &second)
    #expect(first.values != second.values)
  }

  @Test
  func nonPermutationVariantsMatchTheirDocumentedDistributions() {
    let expectedCurves: [(Int, [Int], [Int])] = [
      (4, [2, 3, 4, 4], [2, 3, 4, 4]),
      (5, [2, 3, 4, 4, 5], [2, 4, 4, 4, 4]),
      (8, [2, 4, 5, 5, 6, 6, 6, 7], [2, 5, 5, 5, 6, 6, 6, 6])
    ]
    for (size, cubicValues, quinticValues) in expectedCurves {
      for (shuffle, expected) in [
        (ShuffledCubicShuffle() as any ShuffleAlgorithm, cubicValues),
        (ShuffledQuinticShuffle() as any ShuffleAlgorithm, quinticValues)
      ] {
        var engine = RecordingEngine(values: Array(1...size), randomSeed: 7)
        shuffle.record(into: &engine)
        #expect(engine.values.sorted() == expected,
                "\(shuffle.id.rawValue) changed its curve distribution at size \(size)")
      }
    }

    for size in [4, 5, 8, 9, 32, 33, 128, 129] {
      let initial = Array(1...size)
      var expected = [1]
      for index in 1..<size {
        var power = 1
        while power <= index / 2 { power *= 2 }
        expected.append(initial[2 * (index - power) + 1])
      }
      var engine = RecordingEngine(values: initial, randomSeed: 7)
      LogarithmicSlopesShuffle().record(into: &engine)
      #expect(engine.values == expected)
    }
  }

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

  @Test
  @MainActor
  func everyShuffleRecordedTapeReplaysItsActualOutput() {
    // The recorded tape is the replay artifact. This checks the actual outcome, including
    // non-permuting variants, independently of re-recording with the same seed.
    for size in [4, 16, 63] {
      let initial = Array(1...size)
      for shuffle in Self.shuffles {
        var recording = RecordingEngine(values: initial)
        shuffle.record(into: &recording)
        let result = recording.finish()
        #expect(!recording.didExceedCap, "\(shuffle.id.rawValue) exceeded the test tape cap")
        let tape = Tape(
          header: TapeHeader(
            algorithmID: "shuffle-test", initialValues: initial, visualSeed: 0,
            compareCount: 0, swapCount: 0, recordingDuration: 0,
            recordedAt: Date(timeIntervalSince1970: 0), shuffleID: shuffle.id.rawValue),
          operations: result.tape)
        let replay = ReplayEngine(tape: tape)
        replay.seek(to: tape.operations.count)
        #expect(
          replay.frame.map(\.value) == recording.values,
          "\(shuffle.id.rawValue) at size \(size) did not replay its recorded output")
      }
    }
  }
}
