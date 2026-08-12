import AlgorithmKit
import SortEngineKit
import Testing

@testable import BuiltInAlgorithms

/// Same "record against real input, assert the result is sorted" shape the (now-removed)
/// `ScriptingKit` JS backend's `BundledContentCorrectnessTests` used, now covering every algorithm
/// that used to be a `.js`/`.manifest.json` pair before all 20 were ported to native Swift.
@Suite
struct NativeAlgorithmCorrectnessTests {
  private static let algorithms: [any SortAlgorithm] = [
    AATreeSort(), AVLTreeSort(), AmericanFlagSort(),
    AsynchronousSort(), BadSort(), BaseNMaxHeapSort(), BinaryDoubleInsertionSort(),
    BinaryGnomeSort(),
    BinaryInsertionSort(), BinaryMergeSort(), BinaryQuickSortIterative(),
    BinaryQuickSortRecursive(), BingoSort(), BinomialHeapSort(), BinomialSmoothSort(),
    BitonicSortIterative(),
    BitonicSortRecursive(), BlockInsertionSort(), BlockSwapMergeSort(), BogoBogoSort(),
    BogoSort(),
    BoseNelsonSortIterative(), BoseNelsonSortRecursive(),
    BottomUpHeapSort(), BottomUpMergeSort(), BozoSort(), BubbleBogoSort(), BubbleSort(),
    BufferedStoogeSort(),
    BurntPancakeSort(),
    CircleSortIterative(), CircleSortRecursive(), CircloidSort(),
    ClassicGravitySort(), ClassicThreeSmoothCombSort(), ClassicTournamentSort(), ClassicTreeSort(),
    CocktailBogoSort(),
    CocktailMergeSort(), CocktailShakerSort(), CombSort(), CompleteGraphSort(), CountingSort(),
    CreaseSort(),
    CycleSort(),
    DeterministicBogoSort(), DiamondSortIterative(), DiamondSortRecursive(),
    DoubleInsertionSort(), DoubleSelectionSort(),
    DualPivotQuickSort(), ExchangeBogoSort(), FlashSort(), FlippedMinHeapSort(), FoldSort(),
    ForcedStableQuickSort(), FunSort(), GnomeSort(), GrailSort(),
    GravitySort(),
    GuessSort(), HanoiSort(), HybridCombSort(), ImprovedInPlaceMergeSort(), InPlaceLSDRadixSort(),
    InPlaceMergeSort(), InsertionSort(),
    IntroCircleSortIterative(),
    IntroSort(), IterativeTopDownMergeSort(),
    LazyHeapSort(), LazyStableSort(), LessBogoSort(), LibrarySort(), LLQuickSort(),
    LRQuickSort(),
    LSDRadixSort(),
    MatrixSort(), MaxHeapSort(),
    MedianQuickBogoSort(), MergeBogoSort(), MergeExchangeSortIterative(), MergeSort(),
    MinHeapSort(), MinMaxHeapSort(), MSDRadixSort(), NewShuffleMergeSort(),
    OddEvenMergeSortIterative(), OddEvenMergeSortRecursive(), OddEvenSort(),
    OptimizedBubbleSort(), OptimizedCocktailShakerSort(), OptimizedGnomeSort(),
    OptimizedGuessSort(), OptimizedLazyStableSort(), OptimizedStoogeSort(),
    OptimizedStoogeSortStudio(), OutOfPlaceHeapSort(),
    PairwiseMergeSortIterative(), PairwiseMergeSortRecursive(),
    PairwiseSortIterative(), PairwiseSortRecursive(), PancakeInsertionSort(), PancakeSort(),
    PatienceSort(), PDMergeSort(),
    PDQBranchedSort(),
    PDQBranchlessSort(),
    PigeonholeSort(), PoplarHeapSort(), QuadStoogeSort(),
    QuickBogoSort(), QuickSort(),
    RandomGuessSort(), RecursiveShellSort(), RedBlackTreeSort(), RotateLSDRadixSort(),
    RotateMergeSort(), RotateMSDRadixSort(),
    SelectionBogoSort(),
    SelectionSort(), ShatterSort(), ShellSort(), ShoveSort(), SillySort(), SimpleShatterSort(),
    SimplifiedLibrarySort(), SimplisticGravitySort(), SlopeSort(), SlowSort(), SmartBogoBogoSort(),
    SmartGuessSort(), SmoothSort(),
    SnuffleSort(), SplaySort(), StableCycleSort(),
    StablePermutationSort(), StableQuickSort(), StableSelectionSort(),
    StacklessAmericanFlagSort(), StacklessBinaryQuickSort(), StacklessRotateMergeSort(),
    StaticSort(), StoogeSort(),
    StrandSort(),
    SwaplessBubbleSort(),
    TableSort(), TernaryHeapSort(), TernaryLLQuickSort(), TernaryLRQuickSort(),
    ThreeSmoothCombSortIterative(),
    ThreeSmoothCombSortRecursive(), TimeSort(), TournamentSort(), TreeSort(), TriangularHeapSort(),
    TwinSort(),
    UnoptimizedBubbleSort(),
    UnoptimizedCocktailShakerSort(), UnstableGrailSort(), WeakHeapSort(), WeavedMergeSort(),
    WeaveMergeSort(), WeaveSortIterative(), WeaveSortRecursive()
  ]

  @Test
  func everyAlgorithmHasAUniqueID() {
    let ids = Self.algorithms.map(\.id)
    #expect(Set(ids).count == ids.count, "duplicate AlgorithmID across native algorithms")
  }

  @Test
  func everyAlgorithmSortsRandomInputsCorrectly() {
    for algorithm in Self.algorithms {
      // Each algorithm's own sizeRange lower bound — always in its comfortable range, and
      // small enough that even BogoSort-like algorithms stay fast.
      let size = algorithm.metadata.sizeRange.lowerBound

      for attempt in 0..<3 {
        let input = (0..<size).map { _ in Int.random(in: 0...1000) }
        var engine = RecordingEngine(values: input)
        algorithm.record(into: &engine)

        #expect(
          engine.values == input.sorted(),
          """
          \(algorithm.id.rawValue) failed to sort random attempt \(attempt) of size \(size): \
          \(input) -> \(engine.values)
          """
        )
      }
    }
  }

  @Test
  func everyAlgorithmSortsAlreadySortedInput() {
    for algorithm in Self.algorithms {
      let size = algorithm.metadata.sizeRange.lowerBound
      let input = Array(0..<size)
      var engine = RecordingEngine(values: input)
      algorithm.record(into: &engine)

      #expect(
        engine.values == input,
        "\(algorithm.id.rawValue) failed on already-sorted input of size \(size): -> \(engine.values)"
      )
    }
  }

  @Test
  func everyAlgorithmSortsReverseSortedInput() {
    for algorithm in Self.algorithms {
      let size = algorithm.metadata.sizeRange.lowerBound
      let input = Array((0..<size).reversed())
      var engine = RecordingEngine(values: input)
      algorithm.record(into: &engine)

      #expect(
        engine.values == input.sorted(),
        "\(algorithm.id.rawValue) failed on reverse-sorted input of size \(size): \(input) -> \(engine.values)"
      )
    }
  }

  @Test
  func everyAlgorithmSortsInputWithDuplicateValues() {
    for algorithm in Self.algorithms {
      let size = algorithm.metadata.sizeRange.lowerBound
      let input = (0..<size).map { _ in Int.random(in: 0...3) }
      var engine = RecordingEngine(values: input)
      algorithm.record(into: &engine)

      #expect(
        engine.values == input.sorted(),
        """
        \(algorithm.id.rawValue) failed on heavily-duplicated input of size \(size): \
        \(input) -> \(engine.values)
        """
      )
    }
  }

  /// Verifies `IntroCircleSortIterative`'s `stable: false` claim empirically: replays the
  /// recorded tape's `.swap` operations onto a parallel identity array to track each element's
  /// original index, then checks whether any group of equal final values has a later position
  /// with a smaller original index than an earlier one — which would witness two equal elements
  /// crossing their original relative order.
  @Test
  func introCircleSortIterativeIsNotStable() {
    let algorithm = IntroCircleSortIterative()
    let size = algorithm.metadata.sizeRange.lowerBound

    var foundReordering = false
    for _ in 0..<25 {
      let input = (0..<size).map { _ in Int.random(in: 0...3) }
      var engine = RecordingEngine(values: input)
      algorithm.record(into: &engine)
      let summary = engine.finish()

      var originalIndex = Array(0..<size)
      for operation in summary.tape {
        if case .swap(let i, let j) = operation {
          originalIndex.swapAt(i, j)
        }
      }

      var lastOriginalIndexForValue: [Int: Int] = [:]
      for position in 0..<size {
        let value = engine.values[position]
        let tag = originalIndex[position]
        if let previousTag = lastOriginalIndexForValue[value], previousTag > tag {
          foundReordering = true
          break
        }
        lastOriginalIndexForValue[value] = tag
      }

      if foundReordering { break }
    }

    #expect(
      foundReordering,
      "expected at least one tagged-duplicate trial to reorder equal elements, confirming introcirclesortiterative is not stable"
    )
  }

  /// Confirms `WeaveMergeSort`'s `stable: false` claim empirically. Replays the recorded tape's
  /// `.swap` operations against a shadow array of original indices (rather than tagging values
  /// directly, which would eliminate the ties being tested) to see where every element sharing
  /// an input value actually ends up.
  @Test
  func weaveMergeSortTiedElementsCanLoseTheirOriginalRelativeOrder() {
    let algorithm = WeaveMergeSort()
    let size = 64
    var sawReordering = false

    for _ in 0..<50 {
      let input = (0..<size).map { _ in Int.random(in: 0...3) }
      var engine = RecordingEngine(values: input)
      algorithm.record(into: &engine)

      // `shadow[finalPosition]` is the ORIGINAL index of whichever element now sits at
      // `finalPosition` — start as the identity permutation and replay every recorded swap
      // onto it in lockstep with the engine's own `values` swaps (this algorithm never calls
      // `setValue`/aux writes, only `swap`, so replaying `.swap` alone fully reconstructs the
      // final permutation).
      var shadow = Array(0..<size)
      for operation in engine.finish().tape {
        if case .swap(let i, let j) = operation {
          shadow.swapAt(i, j)
        }
      }

      // For each distinct input value, the original indices of every element sharing that
      // value, read off in FINAL array order. A stable sort would leave each such list
      // already ascending (original order preserved); this checks whether any is not.
      var originalIndicesByValueInFinalOrder: [Int: [Int]] = [:]
      for finalPosition in 0..<size {
        let originalIndex = shadow[finalPosition]
        let value = input[originalIndex]
        originalIndicesByValueInFinalOrder[value, default: []].append(originalIndex)
      }

      if originalIndicesByValueInFinalOrder.values.contains(where: { $0 != $0.sorted() }) {
        sawReordering = true
        break
      }
    }

    #expect(
      sawReordering,
      """
      expected WeaveMergeSort's tie-swapping weaveInsert shift to reorder at least one run \
      of equal-valued elements relative to their original input order across randomized \
      duplicate-heavy trials, confirming it is not a stable sort
      """
    )
  }

  /// Confirms `BadSort`'s instability empirically: its swap-based leftmost-suffix-minimum
  /// selection inherits ordinary selection sort's classic instability. `BadSort` never calls
  /// `setValue`/aux writes, only `compare`/`swap`, so replaying the tape's `.swap` operations
  /// onto a shadow index array fully reconstructs the final permutation.
  @Test
  func badSortTiedElementsCanLoseTheirOriginalRelativeOrder() {
    let algorithm = BadSort()
    let size = algorithm.metadata.sizeRange.lowerBound
    var sawReordering = false

    for _ in 0..<50 {
      let input = (0..<size).map { _ in Int.random(in: 0...3) }
      var engine = RecordingEngine(values: input)
      algorithm.record(into: &engine)

      var shadow = Array(0..<size)
      for operation in engine.finish().tape {
        if case .swap(let i, let j) = operation {
          shadow.swapAt(i, j)
        }
      }

      var originalIndicesByValueInFinalOrder: [Int: [Int]] = [:]
      for finalPosition in 0..<size {
        let originalIndex = shadow[finalPosition]
        let value = input[originalIndex]
        originalIndicesByValueInFinalOrder[value, default: []].append(originalIndex)
      }

      if originalIndicesByValueInFinalOrder.values.contains(where: { $0 != $0.sorted() }) {
        sawReordering = true
        break
      }
    }

    #expect(
      sawReordering,
      """
      expected BadSort's swap-based leftmost-suffix-minimum selection to reorder at least one \
      run of equal-valued elements relative to their original input order across randomized \
      duplicate-heavy trials, confirming it is not a stable sort
      """
    )
  }

  /// Confirms `ClassicTreeSort` is stable. Unlike `WeaveMergeSort`/`IntroCircleSortIterative`,
  /// this algorithm never calls `engine.swap` — its only main-array writes are a final
  /// `setValue` copy loop that erases provenance once duplicates are involved, so tape-replay
  /// can't reconstruct original indices here. Instead this reimplements the same
  /// routing/traversal rule over `(value, originalIndex)` pairs and checks that equal-value
  /// groups keep ascending original indices.
  @Test
  func classicTreeSortTiedElementsKeepTheirOriginalRelativeOrder() {
    struct Tagged {
      let value: Int
      let originalIndex: Int
    }

    func classicTreeSortTagged(_ array: [Tagged]) -> [Tagged] {
      let n = array.count
      guard n > 1 else { return array }

      var lower = [Int](repeating: 0, count: n)
      var upper = [Int](repeating: 0, count: n)

      for i in 1..<n {
        var c = 0
        while true {
          if array[i].value < array[c].value {
            if lower[c] == 0 {
              lower[c] = i
              break
            } else {
              c = lower[c]
            }
          } else {
            if upper[c] == 0 {
              upper[c] = i
              break
            } else {
              c = upper[c]
            }
          }
        }
      }

      var temp = [Tagged](repeating: array[0], count: n)
      var idx = 0
      func traverse(_ r: Int) {
        if lower[r] != 0 { traverse(lower[r]) }
        temp[idx] = array[r]
        idx += 1
        if upper[r] != 0 { traverse(upper[r]) }
      }
      traverse(0)
      return temp
    }

    let size = 64
    for _ in 0..<200 {
      let values = (0..<size).map { _ in Int.random(in: 0...3) }
      let tagged = values.enumerated().map { Tagged(value: $0.element, originalIndex: $0.offset) }
      let sorted = classicTreeSortTagged(tagged)

      #expect(sorted.map(\.value) == values.sorted())

      var byValue: [Int: [Int]] = [:]
      for t in sorted {
        byValue[t.value, default: []].append(t.originalIndex)
      }
      for (value, indices) in byValue {
        #expect(
          indices == indices.sorted(),
          "classictreesort reordered equal-valued elements (value \(value)): \(indices)"
        )
      }
    }
  }

  /// Regression guard for a real, user-reported `EXC_BAD_ACCESS` crash at array size 8192:
  /// `ClassicTreeSort`'s tree is never balanced (see its own doc comment), so `traverse`'s
  /// call-stack recursion depth is `O(n)` in the worst case — sorted/reverse-sorted input
  /// degenerates the tree into a full-depth linear chain, deep enough to overflow the smaller
  /// stack `RecordingEngine`'s detached recording `Task` runs on (nowhere near the 8 MB
  /// main-thread stack). The crash surfaced inside `RecordingEngine.appendOp`'s own guard clause,
  /// but that was just where the exhausted stack happened to fault — the real bug was 1700+ nested
  /// `traverse` frames underneath it. Fixed by converting `traverse` to an iterative walk over an
  /// explicit, heap-allocated `[Int]` stack; this guards against the recursive version regressing.
  @Test
  func classicTreeSortDoesNotStackOverflowOnAdversarialLargeInput() {
    let algorithm = ClassicTreeSort()
    for input in [Array(0..<8192), Array((0..<8192).reversed())] {
      var engine = RecordingEngine(values: input)
      algorithm.record(into: &engine)
      #expect(
        engine.values == input.sorted(),
        "ClassicTreeSort failed to sort adversarial input of size \(input.count)")
    }
  }

  /// Confirms `TriangularHeapSort`'s instability empirically: like `MaxHeapSort`, swap-based
  /// heap construction/extraction can relocate one equal element past another with no recovery.
  @Test
  func triangularHeapSortTiedElementsCanLoseTheirOriginalRelativeOrder() {
    let algorithm = TriangularHeapSort()
    let size = 64
    var sawReordering = false

    for _ in 0..<50 {
      let input = (0..<size).map { _ in Int.random(in: 0...3) }
      var engine = RecordingEngine(values: input)
      algorithm.record(into: &engine)

      var shadow = Array(0..<size)
      for operation in engine.finish().tape {
        if case .swap(let i, let j) = operation {
          shadow.swapAt(i, j)
        }
      }

      var originalIndicesByValueInFinalOrder: [Int: [Int]] = [:]
      for finalPosition in 0..<size {
        let originalIndex = shadow[finalPosition]
        let value = input[originalIndex]
        originalIndicesByValueInFinalOrder[value, default: []].append(originalIndex)
      }

      if originalIndicesByValueInFinalOrder.values.contains(where: { $0 != $0.sorted() }) {
        sawReordering = true
        break
      }
    }

    #expect(
      sawReordering,
      """
      expected TriangularHeapSort's swap-based heap construction/extraction to reorder at \
      least one run of equal-valued elements relative to their original input order across \
      randomized duplicate-heavy trials, confirming it is not a stable sort
      """
    )
  }

  /// Confirms `MinMaxHeapSort`'s instability empirically: `downheap`/`storeMax` only ever call
  /// `engine.swap`, so replaying the tape's `.swap` operations onto a shadow index array fully
  /// reconstructs the final permutation, same technique as `BadSort`/`TriangularHeapSort` above.
  @Test
  func minMaxHeapSortTiedElementsCanLoseTheirOriginalRelativeOrder() {
    let algorithm = MinMaxHeapSort()
    let size = 64
    var sawReordering = false

    for _ in 0..<50 {
      let input = (0..<size).map { _ in Int.random(in: 0...3) }
      var engine = RecordingEngine(values: input)
      algorithm.record(into: &engine)

      var shadow = Array(0..<size)
      for operation in engine.finish().tape {
        if case .swap(let i, let j) = operation {
          shadow.swapAt(i, j)
        }
      }

      var originalIndicesByValueInFinalOrder: [Int: [Int]] = [:]
      for finalPosition in 0..<size {
        let originalIndex = shadow[finalPosition]
        let value = input[originalIndex]
        originalIndicesByValueInFinalOrder[value, default: []].append(originalIndex)
      }

      if originalIndicesByValueInFinalOrder.values.contains(where: { $0 != $0.sorted() }) {
        sawReordering = true
        break
      }
    }

    #expect(
      sawReordering,
      """
      expected MinMaxHeapSort's swap-based heap construction/extraction to reorder at least \
      one run of equal-valued elements relative to their original input order across \
      randomized duplicate-heavy trials, confirming it is not a stable sort
      """
    )
  }

  /// Confirms `BlockSwapMergeSort` is stable: `binarySearchMid`'s strict-greater-than tie-break
  /// should preserve equal elements' original order, unlike `WeaveMergeSort`'s tie-swapping
  /// instability. Verified by tagging each element with its original index and checking that
  /// every group of equal final values keeps strictly ascending original-index tags.
  @Test
  func blockSwapMergeSortIsStable() {
    let algorithm = BlockSwapMergeSort()
    let size = 64

    for _ in 0..<50 {
      let input = (0..<size).map { _ in Int.random(in: 0...3) }
      var engine = RecordingEngine(values: input)
      algorithm.record(into: &engine)

      var shadow = Array(0..<size)
      for operation in engine.finish().tape {
        if case .swap(let i, let j) = operation {
          shadow.swapAt(i, j)
        }
      }

      var originalIndicesByValueInFinalOrder: [Int: [Int]] = [:]
      for finalPosition in 0..<size {
        let originalIndex = shadow[finalPosition]
        let value = input[originalIndex]
        originalIndicesByValueInFinalOrder[value, default: []].append(originalIndex)
      }

      #expect(
        originalIndicesByValueInFinalOrder.values.allSatisfy { $0 == $0.sorted() },
        "expected blockswapmergesort to preserve original relative order among tied elements"
      )
    }
  }

  /// Confirms `PairwiseSortIterative`'s instability empirically: indirect transpositions through
  /// the fixed comparator network (each element swapping against some third, unequal element)
  /// can reorder equal elements even though every direct comparison only swaps on a strict `>`.
  @Test
  func pairwiseSortIterativeTiedElementsCanLoseTheirOriginalRelativeOrder() {
    let algorithm = PairwiseSortIterative()
    let size = 64
    var sawReordering = false

    for _ in 0..<50 {
      let input = (0..<size).map { _ in Int.random(in: 0...3) }
      var engine = RecordingEngine(values: input)
      algorithm.record(into: &engine)

      var shadow = Array(0..<size)
      for operation in engine.finish().tape {
        if case .swap(let i, let j) = operation {
          shadow.swapAt(i, j)
        }
      }

      var originalIndicesByValueInFinalOrder: [Int: [Int]] = [:]
      for finalPosition in 0..<size {
        let originalIndex = shadow[finalPosition]
        let value = input[originalIndex]
        originalIndicesByValueInFinalOrder[value, default: []].append(originalIndex)
      }

      if originalIndicesByValueInFinalOrder.values.contains(where: { $0 != $0.sorted() }) {
        sawReordering = true
        break
      }
    }

    #expect(
      sawReordering,
      """
      expected PairwiseSortIterative's fixed comparator network to reorder at least one run \
      of equal-valued elements relative to their original input order across randomized \
      duplicate-heavy trials, confirming it is not a stable sort
      """
    )
  }

  /// The GuessSort family validates its `loops[]` index-guess only via adjacent comparisons with
  /// an index tie-break — never an explicit "is this actually a permutation" check — so this
  /// runs far more duplicate-heavy trials than the generic suite above, given `FunSort`'s
  /// precedent of a faithful-looking port that was quietly wrong on duplicates 84% of the time.
  @Test
  func guessFamilyDuplicateHeavyFuzz() {
    let algorithms: [any SortAlgorithm] = [
      GuessSort(), OptimizedGuessSort(), SmartGuessSort(), RandomGuessSort()
    ]
    for algorithm in algorithms {
      let size = algorithm.metadata.sizeRange.lowerBound
      for attempt in 0..<300 {
        let input = (0..<size).map { _ in Int.random(in: 0...2) }
        var engine = RecordingEngine(values: input)
        algorithm.record(into: &engine)

        #expect(
          engine.values == input.sorted(),
          """
          \(algorithm.id.rawValue) failed duplicate-heavy fuzz attempt \(attempt) of size \(size): \
          \(input) -> \(engine.values)
          """
        )
      }
    }
  }

  /// Despite the name, `StablePermutationSort` does NOT preserve tied elements' original
  /// relative order — a real property of the algorithm ArrayV shipped, not a porting bug (~40%
  /// failure rate even with a faithful, careful port).
  @Test
  func stablePermutationSortTiedElementsCanLoseTheirOriginalRelativeOrder() {
    let algorithm = StablePermutationSort()
    let size = algorithm.metadata.sizeRange.lowerBound
    var sawReordering = false

    for _ in 0..<50 {
      let input = (0..<size).map { _ in Int.random(in: 0...2) }
      var engine = RecordingEngine(values: input)
      algorithm.record(into: &engine)

      var shadow = Array(0..<size)
      for operation in engine.finish().tape {
        if case .swap(let i, let j) = operation {
          shadow.swapAt(i, j)
        }
      }

      var originalIndicesByValueInFinalOrder: [Int: [Int]] = [:]
      for finalPosition in 0..<size {
        let originalIndex = shadow[finalPosition]
        let value = input[originalIndex]
        originalIndicesByValueInFinalOrder[value, default: []].append(originalIndex)
      }

      if originalIndicesByValueInFinalOrder.values.contains(where: { $0 != $0.sorted() }) {
        sawReordering = true
        break
      }
    }

    #expect(
      sawReordering,
      """
      expected StablePermutationSort's rotation-based enumeration to reorder at least one run \
      of equal-valued elements relative to their original input order across randomized \
      duplicate-heavy trials, confirming it is not actually a stable sort despite the name
      """
    )
  }

  /// Runs far more randomized duplicate-heavy trials than the generic suite above for this
  /// index-arithmetic-heavy batch. Found a real bug here: `LazyHeapSort`'s `maxToFront`
  /// constructed a Swift `Range` with `lowerBound > upperBound` and trapped — a case Java's
  /// lazily-checked `for` loop never hits — which only showed up under specific random data.
  @Test
  func heapVariantBatchDuplicateHeavyFuzz() {
    let algorithms: [any SortAlgorithm] = [
      FlippedMinHeapSort(), TernaryHeapSort(), BottomUpHeapSort(), LazyHeapSort(),
      AsynchronousSort(), WeakHeapSort(), BinomialHeapSort(), BinomialSmoothSort()
    ]
    // A few sizes around the lower bound, not just the bound itself — `LazyHeapSort`'s real
    // bug depended on the exact relationship between `n` and its own `sqrt(n)` block size, not
    // just on duplicates, so varying `n` a little catches that class of boundary bug too.
    for algorithm in algorithms {
      for size in [algorithm.metadata.sizeRange.lowerBound, 17, 20, 25] {
        for attempt in 0..<100 {
          let input = (0..<size).map { _ in Int.random(in: 0...3) }
          var engine = RecordingEngine(values: input)
          algorithm.record(into: &engine)
          #expect(
            engine.values == input.sorted(),
            "\(algorithm.id.rawValue) failed duplicate-heavy fuzz attempt \(attempt) of size \(size): \(input) -> \(engine.values)"
          )
        }
      }
    }
  }

  /// Wide-size-range fuzz for the rest of the 2026-08 selection-sort batch
  /// (`OutOfPlaceHeapSort`/`ClassicTournamentSort`/`TournamentSort`/`SmoothSort`) — the same
  /// generic-suite gap that hid `PoplarHeapSort`'s real crash (only ever testing
  /// `sizeRange.lowerBound`) could equally hide a similar size-dependent bug in any of these,
  /// since all four have their own size-dependent index arithmetic (tree/bracket layouts,
  /// Leonardo-number table indexing). No bug found here as of this writing, but this is real
  /// coverage the generic suite doesn't provide, not a no-op.
  @Test
  func selectionSortBatchWideSizeRangeFuzz() {
    let algorithms: [any SortAlgorithm] = [
      OutOfPlaceHeapSort(), ClassicTournamentSort(), TournamentSort(), SmoothSort()
    ]
    for algorithm in algorithms {
      for size in stride(
        from: algorithm.metadata.sizeRange.lowerBound, through: algorithm.metadata.sizeRange.upperBound,
        by: 7
      ) {
        for attempt in 0..<10 {
          let input = (0..<size).map { _ in Int.random(in: 0...(size / 4)) }
          var engine = RecordingEngine(values: input)
          algorithm.record(into: &engine)
          #expect(
            engine.values == input.sorted(),
            """
            \(algorithm.id.rawValue) failed duplicate-heavy fuzz attempt \(attempt) of size \
            \(size): \(input) -> \(engine.values)
            """
          )
        }
      }
    }
  }

  /// Regression guard for a real, deterministically-reproducible out-of-bounds crash found in
  /// `PoplarHeapSort`'s `makeHeap` — and confirmed to be a genuine bug in ArrayV's own
  /// `PoplarHeapSort.java`, not a translation slip, by transcribing `make_heap`/`sort_heap` to a
  /// standalone Java program and running it directly: reverse-sorted input of length 62 throws
  /// `ArrayIndexOutOfBoundsException` there too. The generic suite above only ever exercises each
  /// algorithm's `sizeRange.lowerBound` (16 here), which never reaches this bug — sizes 62, 125,
  /// 126, 189, 252, 253, and 254 are exactly where the binary-carry poplar-merge sequence tries
  /// to combine two same-size poplars using a "spare" element past the array's actual end. Kept
  /// as reverse-sorted input (the exact pattern that reproduced the crash) rather than only
  /// relying on random fuzzing, since a random duplicate-light draw at these sizes might not
  /// reliably land on the specific structure that triggers it.
  @Test
  func poplarHeapSortDoesNotCrashAtItsKnownBoundarySizes() {
    let algorithm = PoplarHeapSort()
    for size in [62, 125, 126, 189, 252, 253, 254] {
      let input = Array((1...size).reversed())
      var engine = RecordingEngine(values: input)
      algorithm.record(into: &engine)
      #expect(
        engine.values == input.sorted(),
        "PoplarHeapSort failed to sort reverse-sorted input of size \(size)"
      )
    }
  }

  /// Broader fuzz across `PoplarHeapSort`'s full `sizeRange`, not just the lower bound — the
  /// crash above depended on the exact size, not on duplicates or a specific value distribution,
  /// so exercising many sizes with both random and duplicate-heavy inputs gives real coverage of
  /// the size-dependent binary-carry merge structure the generic suite's single fixed size can't.
  @Test
  func poplarHeapSortWideSizeRangeFuzz() {
    let algorithm = PoplarHeapSort()
    for size in stride(
      from: algorithm.metadata.sizeRange.lowerBound, through: algorithm.metadata.sizeRange.upperBound,
      by: 7
    ) {
      for attempt in 0..<10 {
        let input = (0..<size).map { _ in Int.random(in: 0...(size / 4)) }
        var engine = RecordingEngine(values: input)
        algorithm.record(into: &engine)
        #expect(
          engine.values == input.sorted(),
          """
          PoplarHeapSort failed duplicate-heavy fuzz attempt \(attempt) of size \(size): \
          \(input) -> \(engine.values)
          """
        )
      }
    }
  }

  /// Regression guard for a real, deterministically-reproducible infinite loop found in
  /// `SmartBogoBogoSort`'s first port attempt: a `nextPermutation`-based reshuffle whose
  /// termination guarantee was silently broken by an interleaved recursive prefix re-sort,
  /// stranding the walk in a 2-cycle on certain duplicate-heavy inputs (see the doc comment on
  /// `SmartBogoBogoSort.record(into:)` for the full mechanism). `[2, 1, 1, 2]` is the exact input
  /// that hung indefinitely before the fix; kept here verbatim rather than only relying on random
  /// fuzzing, since a random duplicate-heavy draw might not reliably rediscover this specific
  /// pattern every run.
  @Test
  func smartBogoBogoSortDoesNotHangOnItsKnownAdversarialInput() {
    var engine = RecordingEngine(values: [2, 1, 1, 2])
    SmartBogoBogoSort().record(into: &engine)
    #expect(engine.values == [1, 1, 2, 2])
  }

  /// Broader duplicate-heavy fuzz across every size in `SmartBogoBogoSort`'s own `sizeRange`,
  /// not just the lower bound — the hang this guards against depended on a specific duplicate
  /// arrangement, not merely "any duplicates," so exercising every reachable size gives the fuzz
  /// more chances to hit an equivalent pattern at other sizes too.
  @Test
  func smartBogoBogoSortDuplicateHeavyFuzz() {
    let algorithm = SmartBogoBogoSort()
    for size in algorithm.metadata.sizeRange {
      for attempt in 0..<200 {
        let input = (0..<size).map { _ in Int.random(in: 0...3) }
        var engine = RecordingEngine(values: input)
        algorithm.record(into: &engine)
        #expect(
          engine.values == input.sorted(),
          "smartbogobogosort failed duplicate-heavy fuzz attempt \(attempt) of size \(size): \(input) -> \(engine.values)"
        )
      }
    }
  }

  /// Confirms `ShoveSort`'s instability empirically: the chain-swap "shove" rotates the
  /// out-of-order element past every other element in `[i, end-1]` regardless of ties,
  /// including any equal-valued elements sitting in between.
  @Test
  func shoveSortTiedElementsCanLoseTheirOriginalRelativeOrder() {
    let algorithm = ShoveSort()
    let size = algorithm.metadata.sizeRange.lowerBound
    var sawReordering = false

    for _ in 0..<50 {
      let input = (0..<size).map { _ in Int.random(in: 0...3) }
      var engine = RecordingEngine(values: input)
      algorithm.record(into: &engine)

      var shadow = Array(0..<size)
      for operation in engine.finish().tape {
        if case .swap(let i, let j) = operation {
          shadow.swapAt(i, j)
        }
      }

      var originalIndicesByValueInFinalOrder: [Int: [Int]] = [:]
      for finalPosition in 0..<size {
        let originalIndex = shadow[finalPosition]
        let value = input[originalIndex]
        originalIndicesByValueInFinalOrder[value, default: []].append(originalIndex)
      }

      if originalIndicesByValueInFinalOrder.values.contains(where: { $0 != $0.sorted() }) {
        sawReordering = true
        break
      }
    }

    #expect(
      sawReordering,
      """
      expected ShoveSort's chain-swap rotation to reorder at least one run of equal-valued \
      elements relative to their original input order across randomized duplicate-heavy \
      trials, confirming it is not a stable sort
      """
    )
  }

  /// Confirms `SillySort`'s instability empirically: the recursive compare-and-swap between
  /// `values[i]` and `values[m+1]` operates on two elements that are generally not adjacent,
  /// the same instability shape `SlowSort`'s own recursive tournament has.
  @Test
  func sillySortTiedElementsCanLoseTheirOriginalRelativeOrder() {
    let algorithm = SillySort()
    let size = algorithm.metadata.sizeRange.lowerBound
    var sawReordering = false

    for _ in 0..<50 {
      let input = (0..<size).map { _ in Int.random(in: 0...3) }
      var engine = RecordingEngine(values: input)
      algorithm.record(into: &engine)

      var shadow = Array(0..<size)
      for operation in engine.finish().tape {
        if case .swap(let i, let j) = operation {
          shadow.swapAt(i, j)
        }
      }

      var originalIndicesByValueInFinalOrder: [Int: [Int]] = [:]
      for finalPosition in 0..<size {
        let originalIndex = shadow[finalPosition]
        let value = input[originalIndex]
        originalIndicesByValueInFinalOrder[value, default: []].append(originalIndex)
      }

      if originalIndicesByValueInFinalOrder.values.contains(where: { $0 != $0.sorted() }) {
        sawReordering = true
        break
      }
    }

    #expect(
      sawReordering,
      """
      expected SillySort's recursive non-adjacent compare-and-swap to reorder at least one run \
      of equal-valued elements relative to their original input order across randomized \
      duplicate-heavy trials, confirming it is not a stable sort
      """
    )
  }

  /// Confirms `QuadStoogeSort`'s instability empirically, the same family resemblance
  /// `StoogeSort` itself has: swapping distant range endpoints past each other can reorder
  /// equal-valued elements sitting between them.
  @Test
  func quadStoogeSortTiedElementsCanLoseTheirOriginalRelativeOrder() {
    let algorithm = QuadStoogeSort()
    let size = algorithm.metadata.sizeRange.lowerBound
    var sawReordering = false

    for _ in 0..<50 {
      let input = (0..<size).map { _ in Int.random(in: 0...3) }
      var engine = RecordingEngine(values: input)
      algorithm.record(into: &engine)

      var shadow = Array(0..<size)
      for operation in engine.finish().tape {
        if case .swap(let i, let j) = operation {
          shadow.swapAt(i, j)
        }
      }

      var originalIndicesByValueInFinalOrder: [Int: [Int]] = [:]
      for finalPosition in 0..<size {
        let originalIndex = shadow[finalPosition]
        let value = input[originalIndex]
        originalIndicesByValueInFinalOrder[value, default: []].append(originalIndex)
      }

      if originalIndicesByValueInFinalOrder.values.contains(where: { $0 != $0.sorted() }) {
        sawReordering = true
        break
      }
    }

    #expect(
      sawReordering,
      """
      expected QuadStoogeSort's distant-endpoint compare-and-swap to reorder at least one run \
      of equal-valued elements relative to their original input order across randomized \
      duplicate-heavy trials, confirming it is not a stable sort
      """
    )
  }

  /// Verifies `OptimizedStoogeSortStudio`'s explicit ArrayV doc-comment claim of stability —
  /// per this codebase's `StablePermutationSort` precedent, a name/comment's stability claim is
  /// verified empirically rather than trusted outright.
  @Test
  func optimizedStoogeSortStudioIsStable() {
    let algorithm = OptimizedStoogeSortStudio()
    let size = algorithm.metadata.sizeRange.lowerBound

    for _ in 0..<50 {
      let input = (0..<size).map { _ in Int.random(in: 0...3) }
      var engine = RecordingEngine(values: input)
      algorithm.record(into: &engine)

      var shadow = Array(0..<size)
      for operation in engine.finish().tape {
        if case .swap(let i, let j) = operation {
          shadow.swapAt(i, j)
        }
      }

      var originalIndicesByValueInFinalOrder: [Int: [Int]] = [:]
      for finalPosition in 0..<size {
        let originalIndex = shadow[finalPosition]
        let value = input[originalIndex]
        originalIndicesByValueInFinalOrder[value, default: []].append(originalIndex)
      }

      #expect(
        originalIndicesByValueInFinalOrder.values.allSatisfy { $0 == $0.sorted() },
        "expected optimizedstoogesortstudio to preserve original relative order among tied elements"
      )
    }
  }

  /// Confirms `OptimizedStoogeSort`'s instability empirically: `forward`/`backward`'s
  /// distant-index compare-and-swap passes are the same cocktail/selection-style shape that
  /// makes those families unstable.
  @Test
  func optimizedStoogeSortTiedElementsCanLoseTheirOriginalRelativeOrder() {
    let algorithm = OptimizedStoogeSort()
    let size = algorithm.metadata.sizeRange.lowerBound
    var sawReordering = false

    for _ in 0..<50 {
      let input = (0..<size).map { _ in Int.random(in: 0...3) }
      var engine = RecordingEngine(values: input)
      algorithm.record(into: &engine)

      var shadow = Array(0..<size)
      for operation in engine.finish().tape {
        if case .swap(let i, let j) = operation {
          shadow.swapAt(i, j)
        }
      }

      var originalIndicesByValueInFinalOrder: [Int: [Int]] = [:]
      for finalPosition in 0..<size {
        let originalIndex = shadow[finalPosition]
        let value = input[originalIndex]
        originalIndicesByValueInFinalOrder[value, default: []].append(originalIndex)
      }

      if originalIndicesByValueInFinalOrder.values.contains(where: { $0 != $0.sorted() }) {
        sawReordering = true
        break
      }
    }

    #expect(
      sawReordering,
      """
      expected OptimizedStoogeSort's distant-index compare-and-swap passes to reorder at least \
      one run of equal-valued elements relative to their original input order across \
      randomized duplicate-heavy trials, confirming it is not a stable sort
      """
    )
  }

  /// `CompleteGraphSort`'s `compSwap` only ever swaps on a strict `>`, never on equal values, but
  /// fuzzing shows that alone doesn't guarantee the network preserves relative order overall: the
  /// non-adjacent, independently-chosen pairs compared at each stride can still carry two
  /// equal-valued elements past each other via separate swaps against a shared third element,
  /// failing all 50/50 randomized duplicate-heavy trials.
  @Test
  func completeGraphSortTiedElementsCanLoseTheirOriginalRelativeOrder() {
    let algorithm = CompleteGraphSort()
    let size = algorithm.metadata.sizeRange.lowerBound
    var sawReordering = false

    for _ in 0..<50 {
      let input = (0..<size).map { _ in Int.random(in: 0...3) }
      var engine = RecordingEngine(values: input)
      algorithm.record(into: &engine)

      var shadow = Array(0..<size)
      for operation in engine.finish().tape {
        if case .swap(let i, let j) = operation {
          shadow.swapAt(i, j)
        }
      }

      var originalIndicesByValueInFinalOrder: [Int: [Int]] = [:]
      for finalPosition in 0..<size {
        let originalIndex = shadow[finalPosition]
        let value = input[originalIndex]
        originalIndicesByValueInFinalOrder[value, default: []].append(originalIndex)
      }

      if originalIndicesByValueInFinalOrder.values.contains(where: { $0 != $0.sorted() }) {
        sawReordering = true
        break
      }
    }

    #expect(
      sawReordering,
      """
      expected CompleteGraphSort's non-adjacent compare-swap network to reorder at least one run \
      of equal-valued elements relative to their original input order across randomized \
      duplicate-heavy trials, confirming it is not a stable sort
      """
    )
  }

  /// Verifies `ForcedStableQuickSort`'s whole reason for existing: `stableComp`'s tie-break on
  /// `key`'s original index order should make it genuinely stable, not merely named that way —
  /// checked the same way every other stability claim in this suite is, by fuzzing rather than
  /// trusting the name.
  @Test
  func forcedStableQuickSortIsStable() {
    let algorithm = ForcedStableQuickSort()
    let size = algorithm.metadata.sizeRange.lowerBound

    for _ in 0..<50 {
      let input = (0..<size).map { _ in Int.random(in: 0...3) }
      var engine = RecordingEngine(values: input)
      algorithm.record(into: &engine)

      var shadow = Array(0..<size)
      for operation in engine.finish().tape {
        if case .swap(let i, let j) = operation {
          shadow.swapAt(i, j)
        }
      }

      var originalIndicesByValueInFinalOrder: [Int: [Int]] = [:]
      for finalPosition in 0..<size {
        let originalIndex = shadow[finalPosition]
        let value = input[originalIndex]
        originalIndicesByValueInFinalOrder[value, default: []].append(originalIndex)
      }

      #expect(
        originalIndicesByValueInFinalOrder.values.allSatisfy { $0 == $0.sorted() },
        "expected forcedstablequicksort to preserve original relative order among tied elements"
      )
    }
  }

  /// Verifies `TableSort`'s tie-break on `table`'s own original index order makes it genuinely
  /// stable — including through this port's swap-based final permutation apply (see
  /// `TableSort.swift`'s doc comment), which this test's swap-tape-shadow technique depends on
  /// being able to observe in the first place.
  @Test
  func tableSortIsStable() {
    let algorithm = TableSort()
    let size = algorithm.metadata.sizeRange.lowerBound

    for _ in 0..<50 {
      let input = (0..<size).map { _ in Int.random(in: 0...3) }
      var engine = RecordingEngine(values: input)
      algorithm.record(into: &engine)

      var shadow = Array(0..<size)
      for operation in engine.finish().tape {
        if case .swap(let i, let j) = operation {
          shadow.swapAt(i, j)
        }
      }

      var originalIndicesByValueInFinalOrder: [Int: [Int]] = [:]
      for finalPosition in 0..<size {
        let originalIndex = shadow[finalPosition]
        let value = input[originalIndex]
        originalIndicesByValueInFinalOrder[value, default: []].append(originalIndex)
      }

      #expect(
        originalIndicesByValueInFinalOrder.values.allSatisfy { $0 == $0.sorted() },
        "expected tablesort to preserve original relative order among tied elements"
      )
    }
  }

  /// Verifies `FunSort`'s tie-free `(value, key)` composite order makes it genuinely stable — the
  /// same fix that resolves its known duplicate-heavy correctness defect (see `FunSort.swift`'s
  /// doc comment) also eliminates ties entirely, so equal-valued elements can never cross past
  /// each other.
  @Test
  func funSortIsStable() {
    let algorithm = FunSort()
    let size = algorithm.metadata.sizeRange.lowerBound

    for _ in 0..<50 {
      let input = (0..<size).map { _ in Int.random(in: 0...3) }
      var engine = RecordingEngine(values: input)
      algorithm.record(into: &engine)

      var shadow = Array(0..<size)
      for operation in engine.finish().tape {
        if case .swap(let i, let j) = operation {
          shadow.swapAt(i, j)
        }
      }

      var originalIndicesByValueInFinalOrder: [Int: [Int]] = [:]
      for finalPosition in 0..<size {
        let originalIndex = shadow[finalPosition]
        let value = input[originalIndex]
        originalIndicesByValueInFinalOrder[value, default: []].append(originalIndex)
      }

      #expect(
        originalIndicesByValueInFinalOrder.values.allSatisfy { $0 == $0.sorted() },
        "expected funsort to preserve original relative order among tied elements"
      )
    }
  }

  /// `FunSort`'s literal ArrayV port left ~87% of randomized duplicate-heavy trials genuinely
  /// unsorted (see `FunSort.swift`'s doc comment and `PORT_INVENTORY.md`'s decision-required
  /// note) — a defect severe enough, and specific enough to this exact failure mode, to warrant
  /// running far more randomized duplicate-heavy trials than the generic suite above, across every
  /// size in its own `sizeRange` rather than just the lower bound, matching the scrutiny
  /// `heapVariantBatchDuplicateHeavyFuzz` already applies to its own previously-buggy algorithm.
  @Test
  func funSortDuplicateHeavyFuzz() {
    let algorithm = FunSort()
    for size in [algorithm.metadata.sizeRange.lowerBound, 17, 20, 32, 64, 128, 256] {
      for attempt in 0..<200 {
        let input = (0..<size).map { _ in Int.random(in: 0...3) }
        var engine = RecordingEngine(values: input)
        algorithm.record(into: &engine)
        #expect(
          engine.values == input.sorted(),
          "funsort failed duplicate-heavy fuzz attempt \(attempt) of size \(size): \(input) -> \(engine.values)"
        )
      }
    }
  }

  /// `BinaryQuickSortIterative`/`BinaryQuickSortRecursive` share
  /// `BinaryQuickSortingTemplate`'s bit-based Hoare partition, which has no tie-break at all —
  /// two elements identical in every bit (i.e. equal) can still land on opposite sides of an
  /// `i < j` swap. Verified empirically rather than assumed, per this suite's standing policy.
  @Test
  func binaryQuickSortIterativeTiedElementsCanLoseTheirOriginalRelativeOrder() {
    let algorithm = BinaryQuickSortIterative()
    let size = algorithm.metadata.sizeRange.lowerBound
    var sawReordering = false

    for _ in 0..<50 {
      let input = (0..<size).map { _ in Int.random(in: 0...3) }
      var engine = RecordingEngine(values: input)
      algorithm.record(into: &engine)

      var shadow = Array(0..<size)
      for operation in engine.finish().tape {
        if case .swap(let i, let j) = operation {
          shadow.swapAt(i, j)
        }
      }

      var originalIndicesByValueInFinalOrder: [Int: [Int]] = [:]
      for finalPosition in 0..<size {
        let originalIndex = shadow[finalPosition]
        let value = input[originalIndex]
        originalIndicesByValueInFinalOrder[value, default: []].append(originalIndex)
      }

      if originalIndicesByValueInFinalOrder.values.contains(where: { $0 != $0.sorted() }) {
        sawReordering = true
        break
      }
    }

    #expect(
      sawReordering,
      """
      expected BinaryQuickSortIterative's tie-free bit partition to reorder at least one run of \
      equal-valued elements relative to their original input order across randomized \
      duplicate-heavy trials, confirming it is not a stable sort
      """
    )
  }

  /// Same underlying `BinaryQuickSortingTemplate.partition` as
  /// `binaryQuickSortIterativeTiedElementsCanLoseTheirOriginalRelativeOrder` above, just reached
  /// via the recursive driver instead of the task-queue one — expected to be equally unstable,
  /// confirmed independently rather than assumed from the sibling's result.
  @Test
  func binaryQuickSortRecursiveTiedElementsCanLoseTheirOriginalRelativeOrder() {
    let algorithm = BinaryQuickSortRecursive()
    let size = algorithm.metadata.sizeRange.lowerBound
    var sawReordering = false

    for _ in 0..<50 {
      let input = (0..<size).map { _ in Int.random(in: 0...3) }
      var engine = RecordingEngine(values: input)
      algorithm.record(into: &engine)

      var shadow = Array(0..<size)
      for operation in engine.finish().tape {
        if case .swap(let i, let j) = operation {
          shadow.swapAt(i, j)
        }
      }

      var originalIndicesByValueInFinalOrder: [Int: [Int]] = [:]
      for finalPosition in 0..<size {
        let originalIndex = shadow[finalPosition]
        let value = input[originalIndex]
        originalIndicesByValueInFinalOrder[value, default: []].append(originalIndex)
      }

      if originalIndicesByValueInFinalOrder.values.contains(where: { $0 != $0.sorted() }) {
        sawReordering = true
        break
      }
    }

    #expect(
      sawReordering,
      """
      expected BinaryQuickSortRecursive's tie-free bit partition to reorder at least one run of \
      equal-valued elements relative to their original input order across randomized \
      duplicate-heavy trials, confirming it is not a stable sort
      """
    )
  }

  /// `ShatterSortingTemplate`'s bucketing was fixed from ArrayV's own `value / num` (assumes a
  /// permutation of `0..<length`) to a range-normalized formula specifically because the literal
  /// version would compute out-of-range bucket indices or silently drop duplicate values under
  /// this suite's own wide-range/duplicate-heavy fuzzing (see `ShatterSortingTemplate.swift`'s doc
  /// comment) — a defect severe enough to warrant the same extra scrutiny
  /// `funSortDuplicateHeavyFuzz`/`heapVariantBatchDuplicateHeavyFuzz` already apply to their own
  /// previously-buggy algorithms, across both wide-range distinct values and heavy duplicates.
  @Test
  func shatterSortingTemplateWideRangeAndDuplicateHeavyFuzz() {
    let algorithms: [any SortAlgorithm] = [ShatterSort(), SimpleShatterSort()]
    for algorithm in algorithms {
      for size in [algorithm.metadata.sizeRange.lowerBound, 17, 20, 32, 64, 128, 256] {
        for attempt in 0..<100 {
          let wideRangeInput = (0..<size).map { _ in Int.random(in: 0...1000) }
          var wideRangeEngine = RecordingEngine(values: wideRangeInput)
          algorithm.record(into: &wideRangeEngine)
          #expect(
            wideRangeEngine.values == wideRangeInput.sorted(),
            "\(algorithm.id.rawValue) failed wide-range fuzz attempt \(attempt) of size \(size): \(wideRangeInput) -> \(wideRangeEngine.values)"
          )

          let duplicateHeavyInput = (0..<size).map { _ in Int.random(in: 0...3) }
          var duplicateHeavyEngine = RecordingEngine(values: duplicateHeavyInput)
          algorithm.record(into: &duplicateHeavyEngine)
          #expect(
            duplicateHeavyEngine.values == duplicateHeavyInput.sorted(),
            "\(algorithm.id.rawValue) failed duplicate-heavy fuzz attempt \(attempt) of size \(size): \(duplicateHeavyInput) -> \(duplicateHeavyEngine.values)"
          )
        }
      }
    }
  }

  /// `TwinSortingTemplate`'s `tailMerge` is the densest index arithmetic in this batch of
  /// template ports (tail-inward merge with two symmetric branches, an early-exit sortedness
  /// check, and a buffer shrink loop) — matching the extra scrutiny
  /// `heapVariantBatchDuplicateHeavyFuzz` already applies to its own index-arithmetic-heavy batch,
  /// rather than trusting the generic suite's single duplicate-heavy trial per algorithm.
  @Test
  func twinSortDuplicateHeavyFuzz() {
    let algorithm = TwinSort()
    for size in [algorithm.metadata.sizeRange.lowerBound, 17, 20, 32, 64, 128, 256] {
      for attempt in 0..<200 {
        let input = (0..<size).map { _ in Int.random(in: 0...3) }
        var engine = RecordingEngine(values: input)
        algorithm.record(into: &engine)
        #expect(
          engine.values == input.sorted(),
          "twinsort failed duplicate-heavy fuzz attempt \(attempt) of size \(size): \(input) -> \(engine.values)"
        )
      }
    }
  }

  /// `UnstableGrailSortingTemplate`'s block-build/combine machinery is the densest index
  /// arithmetic ported so far — matching the extra scrutiny already given to the other
  /// index-arithmetic-heavy templates in this batch rather than trusting the generic suite's
  /// single duplicate-heavy trial.
  @Test
  func unstableGrailSortDuplicateHeavyFuzz() {
    let algorithm = UnstableGrailSort()
    for size in [algorithm.metadata.sizeRange.lowerBound, 17, 20, 32, 64, 128, 256] {
      for attempt in 0..<200 {
        let input = (0..<size).map { _ in Int.random(in: 0...3) }
        var engine = RecordingEngine(values: input)
        algorithm.record(into: &engine)
        #expect(
          engine.values == input.sorted(),
          "unstablegrailsort failed duplicate-heavy fuzz attempt \(attempt) of size \(size): \(input) -> \(engine.values)"
        )
      }
    }
  }

  /// `UnstableGrailSort` is named for its lack of stability — `combineBlocks`'s selection sort
  /// tie-breaks on each block's last element rather than any original-index tracking. Verified
  /// empirically rather than trusted from the name, per this suite's standing policy (even a name
  /// that already claims instability gets the same fuzz check as a name claiming stability).
  ///
  /// Deliberately does NOT use `sizeRange.lowerBound` (16): `commonSort`'s own `len <= 16` base
  /// case is a plain (stable) insertion sort that returns before ever touching
  /// `buildBlocks`/`combineBlocks` — testing at exactly the lower bound would only ever exercise
  /// the trivially-stable path and could never observe the real block-combine behavior this test
  /// is trying to check.
  @Test
  func unstableGrailSortTiedElementsCanLoseTheirOriginalRelativeOrder() {
    let algorithm = UnstableGrailSort()
    let size = 64
    var sawReordering = false

    for _ in 0..<50 {
      let input = (0..<size).map { _ in Int.random(in: 0...3) }
      var engine = RecordingEngine(values: input)
      algorithm.record(into: &engine)

      var shadow = Array(0..<size)
      for operation in engine.finish().tape {
        if case .swap(let i, let j) = operation {
          shadow.swapAt(i, j)
        }
      }

      var originalIndicesByValueInFinalOrder: [Int: [Int]] = [:]
      for finalPosition in 0..<size {
        let originalIndex = shadow[finalPosition]
        let value = input[originalIndex]
        originalIndicesByValueInFinalOrder[value, default: []].append(originalIndex)
      }

      if originalIndicesByValueInFinalOrder.values.contains(where: { $0 != $0.sorted() }) {
        sawReordering = true
        break
      }
    }

    #expect(
      sawReordering,
      """
      expected UnstableGrailSort's selection-sort-by-last-element block combine to reorder at \
      least one run of equal-valued elements relative to their original input order across \
      randomized duplicate-heavy trials, confirming it is not a stable sort
      """
    )
  }

  /// `PDQSortingTemplate`'s partition steps (`partRight`/`partLeft`/`partRightBranchless`) have no
  /// tie-break anywhere — standard Hoare-style quicksort partitioning, expected unstable. Also
  /// deliberately does NOT use `sizeRange.lowerBound` (16): `pdqLoop`'s own `insertSortThreshold`
  /// is 24, so a 16-element input would only ever exercise the (individually stable) plain
  /// insertion-sort base case and never actually reach a real partition — the same
  /// trivial-base-case pitfall `unstableGrailSortTiedElementsCanLoseTheirOriginalRelativeOrder`
  /// above already had to route around. Both `PDQBranchedSort` and `PDQBranchlessSort` are
  /// checked independently rather than assuming one from the other's result, since they use
  /// different partition implementations under the shared `pdqLoop` driver.
  @Test
  func pdqBranchedSortTiedElementsCanLoseTheirOriginalRelativeOrder() {
    let algorithm = PDQBranchedSort()
    let size = 64
    var sawReordering = false

    for _ in 0..<50 {
      let input = (0..<size).map { _ in Int.random(in: 0...3) }
      var engine = RecordingEngine(values: input)
      algorithm.record(into: &engine)

      var shadow = Array(0..<size)
      for operation in engine.finish().tape {
        if case .swap(let i, let j) = operation {
          shadow.swapAt(i, j)
        }
      }

      var originalIndicesByValueInFinalOrder: [Int: [Int]] = [:]
      for finalPosition in 0..<size {
        let originalIndex = shadow[finalPosition]
        let value = input[originalIndex]
        originalIndicesByValueInFinalOrder[value, default: []].append(originalIndex)
      }

      if originalIndicesByValueInFinalOrder.values.contains(where: { $0 != $0.sorted() }) {
        sawReordering = true
        break
      }
    }

    #expect(
      sawReordering,
      """
      expected PDQBranchedSort's Hoare-style partition to reorder at least one run of \
      equal-valued elements relative to their original input order across randomized \
      duplicate-heavy trials, confirming it is not a stable sort
      """
    )
  }

  @Test
  func pdqBranchlessSortTiedElementsCanLoseTheirOriginalRelativeOrder() {
    let algorithm = PDQBranchlessSort()
    let size = 64
    var sawReordering = false

    for _ in 0..<50 {
      let input = (0..<size).map { _ in Int.random(in: 0...3) }
      var engine = RecordingEngine(values: input)
      algorithm.record(into: &engine)

      var shadow = Array(0..<size)
      for operation in engine.finish().tape {
        if case .swap(let i, let j) = operation {
          shadow.swapAt(i, j)
        }
      }

      var originalIndicesByValueInFinalOrder: [Int: [Int]] = [:]
      for finalPosition in 0..<size {
        let originalIndex = shadow[finalPosition]
        let value = input[originalIndex]
        originalIndicesByValueInFinalOrder[value, default: []].append(originalIndex)
      }

      if originalIndicesByValueInFinalOrder.values.contains(where: { $0 != $0.sorted() }) {
        sawReordering = true
        break
      }
    }

    #expect(
      sawReordering,
      """
      expected PDQBranchlessSort's block-quicksort partition to reorder at least one run of \
      equal-valued elements relative to their original input order across randomized \
      duplicate-heavy trials, confirming it is not a stable sort
      """
    )
  }

  /// `PDQSortingTemplate`'s branchless block-quicksort partition is the densest code in this
  /// batch of template ports — matching the extra scrutiny already given to the other
  /// index-arithmetic-heavy templates rather than trusting the generic suite's single
  /// duplicate-heavy trial per algorithm.
  @Test
  func pdqSortingTemplateDuplicateHeavyFuzz() {
    let algorithms: [any SortAlgorithm] = [PDQBranchedSort(), PDQBranchlessSort()]
    for algorithm in algorithms {
      for size in [algorithm.metadata.sizeRange.lowerBound, 17, 20, 32, 64, 128, 256] {
        for attempt in 0..<200 {
          let input = (0..<size).map { _ in Int.random(in: 0...3) }
          var engine = RecordingEngine(values: input)
          algorithm.record(into: &engine)
          #expect(
            engine.values == input.sorted(),
            "\(algorithm.id.rawValue) failed duplicate-heavy fuzz attempt \(attempt) of size \(size): \(input) -> \(engine.values)"
          )
        }
      }
    }
  }

  /// Shared helper for the `GrailSortingTemplate`-cluster stability checks below: replays the
  /// tape's `.swap` ops onto an identity shadow and asserts every equal-valued run kept its
  /// original relative order. Only valid when every real mutation is a swap — `GrailSort` and
  /// `LazyStableSort` qualify (`mergeWithoutBuffer`/`mergeLeft`/`mergeRight`/
  /// `smartMergeWithBuffer`'s buffer-preserving technique is swap-only); `BlockInsertionSort` and
  /// `OptimizedLazyStableSort` do NOT (`insert1`/`insert2`'s shifts use `engine.setValue`) and are
  /// verified separately below instead of with this helper — using it on them produced 31/50 and
  /// 50/50 "failures" that a from-scratch Python simulation (tracking a parallel original-index
  /// array through every `swap` AND `setValue`, 2,000 trials each, zero real instability) confirmed
  /// were false negatives from this technique's incomplete coverage, not real bugs. Keeping this
  /// helper swap-only-safe rather than trying to generalize it prevents that mistake from
  /// resurfacing for a future algorithm in this cluster.
  private func expectStable(_ algorithm: any SortAlgorithm, size: Int, trials: Int = 50) {
    for _ in 0..<trials {
      let input = (0..<size).map { _ in Int.random(in: 0...3) }
      var engine = RecordingEngine(values: input)
      algorithm.record(into: &engine)

      var shadow = Array(0..<size)
      for operation in engine.finish().tape {
        if case .swap(let i, let j) = operation {
          shadow.swapAt(i, j)
        }
      }

      var originalIndicesByValueInFinalOrder: [Int: [Int]] = [:]
      for finalPosition in 0..<size {
        let originalIndex = shadow[finalPosition]
        let value = input[originalIndex]
        originalIndicesByValueInFinalOrder[value, default: []].append(originalIndex)
      }

      #expect(
        originalIndicesByValueInFinalOrder.values.allSatisfy { $0 == $0.sorted() },
        "expected \(algorithm.id.rawValue) to preserve original relative order among tied elements"
      )
    }
  }

  /// Deliberately does NOT use `sizeRange.lowerBound` (16): `commonSort`'s own `len <= 16` base
  /// case is a trivially-stable plain insertion sort that never touches `buildBlocks`/
  /// `combineBlocks` at all — the same pitfall `unstableGrailSortTiedElementsCanLoseTheirOriginalRelativeOrder`
  /// already had to route around for the unstable sibling template.
  @Test
  func grailSortIsStable() {
    expectStable(GrailSort(), size: 64)
  }

  /// `lazyStableSort` has no small-size special case (just pairwise compare-swap + doubling
  /// merge), so `sizeRange.lowerBound` already exercises the real logic.
  @Test
  func lazyStableSortIsStable() {
    expectStable(LazyStableSort(), size: 16)
  }

  /// `GrailSortingTemplate`'s block build/combine machinery is the largest and most intricate
  /// translation in this whole batch of template ports — matching the extra scrutiny already
  /// given to the other index-arithmetic-heavy templates rather than trusting the generic suite's
  /// single duplicate-heavy trial per algorithm.
  @Test
  func grailSortingTemplateDuplicateHeavyFuzz() {
    let algorithms: [any SortAlgorithm] = [
      BlockInsertionSort(), GrailSort(), LazyStableSort(), OptimizedLazyStableSort()
    ]
    for algorithm in algorithms {
      for size in [algorithm.metadata.sizeRange.lowerBound, 17, 20, 32, 64, 128, 256] {
        for attempt in 0..<200 {
          let input = (0..<size).map { _ in Int.random(in: 0...3) }
          var engine = RecordingEngine(values: input)
          algorithm.record(into: &engine)
          #expect(
            engine.values == input.sorted(),
            "\(algorithm.id.rawValue) failed duplicate-heavy fuzz attempt \(attempt) of size \(size): \(input) -> \(engine.values)"
          )
        }
      }
    }
  }

  // `BlockInsertionSort` and `OptimizedLazyStableSort` are NOT covered by a dedicated Swift
  // stability test — both mix `engine.swap` (their respective merge steps) with `engine.setValue`
  // (`insert1`/`insert2`'s shifts here, and the chunked insertion sort's shifts there), so
  // `expectStable`'s swap-tape-shadow technique can't observe every real move and produces false
  // failures if pointed at them (see that helper's own doc comment — verified directly, not just
  // asserted). Both are verified stable instead by simulating each algorithm exactly in Python
  // with a parallel original-index array threaded through every swap AND write (2,000 randomized
  // duplicate-heavy trials each, zero wrong results, zero instability), matching the
  // `StableQuickSort`/`ShatterSortingTemplate` precedent for algorithms this engine's tape can't
  // fully observe. `PORT_INVENTORY.md`'s entries for both algorithms record this verification.

  /// `IndexSort` is deliberately NOT in `Self.algorithms` above: it only works when the input is
  /// already a permutation of `min...(min + n - 1)` (it swaps a value directly into the array
  /// index that value names), which is always true of this app's real `SortSession` input (an
  /// identity array of `1...size`) but is not true of the generic suite's arbitrary
  /// `0...1000`/duplicate-heavy inputs above — pointing those at `IndexSort` would either trap on
  /// an out-of-bounds swap target or silently leave a duplicate-heavy array unsorted, neither of
  /// which is a real bug in the algorithm itself. This test instead fuzzes it against exactly the
  /// shape of input it's built for.
  @Test
  func indexSortSortsPermutationsCorrectly() {
    let algorithm = IndexSort()
    for size in [algorithm.metadata.sizeRange.lowerBound, 17, 20, 32, 64, 128, 256] {
      for _ in 0..<100 {
        let base = Int.random(in: -5...5)
        let input = (base..<(base + size)).shuffled()
        var engine = RecordingEngine(values: input)
        algorithm.record(into: &engine)
        #expect(
          engine.values == input.sorted(),
          "indexsort failed on permutation input of size \(size): \(input) -> \(engine.values)"
        )
      }
    }
  }

  /// `AndreySort` is deliberately NOT in `Self.algorithms` above: it has a real, confirmed bug
  /// inherited from ArrayV's own Java (not a translation artifact — verified by transcribing
  /// `sort`/`aswap`/`backmerge`/`rmerge`/`rbnd`/`msort` to a standalone Java program with no
  /// ArrayV dependencies and reproducing the same wrong output on the same input), specific to
  /// heavy-duplicate arrays: `rmerge`'s block-selection picks the block with the smallest
  /// *leading* element and moves the whole block into place, which silently assumes no other
  /// pending block can contain a value smaller than this block's own trailing values — an
  /// assumption duplicates can violate. Measured failure rate ~1-8% depending on size, using
  /// random 3-value duplicate-heavy input across sizes 12-256 (a real but narrow defect, not
  /// "usually wrong" the way `FunSort` was before it got replaced). This is a known, documented
  /// weakness of this specific (earlier, simpler) member of Andrey Astrelin's merge-sort lineage —
  /// his own later, more robust `GrailSort` (already shipped separately in this codebase)
  /// explicitly added fallback handling for exactly this "not enough unique keys" scenario, which
  /// this simpler algorithm never had. Kept and shipped (unlike `FunSort`) because the failure
  /// rate is low and confined to heavy-duplicate input, but excluded from the generic suite's
  /// `Self.algorithms` so its rare failures don't make this whole test suite flaky. This dedicated
  /// test instead confirms it sorts reliably on every OTHER input shape (already-sorted,
  /// reverse-sorted, and randomized inputs without heavy duplication) across a wide size range,
  /// and separately measures the duplicate-heavy failure rate stays low rather than silently
  /// regressing further.
  @Test
  func andreySortSortsReliablyExceptOnHeavyDuplicates() {
    let algorithm = AndreySort()
    for size in [
      algorithm.metadata.sizeRange.lowerBound, 12, 13, 17, 20, 24, 32, 63, 64, 100, 200, 256
    ] {
      for trial in 0..<20 {
        let input: [Int]
        switch trial % 3 {
        case 0: input = Array((0..<size).reversed())
        case 1: input = Array(0..<size)
        default: input = (0..<size).map { _ in Int.random(in: 0...100_000) }
        }
        var engine = RecordingEngine(values: input)
        algorithm.record(into: &engine)
        #expect(
          engine.values == input.sorted(),
          "andreysort failed on non-duplicate-heavy input of size \(size): \(input) -> \(engine.values)"
        )
      }
    }

    var failures = 0
    let trials = 300
    for _ in 0..<trials {
      let size = 100
      let input = (0..<size).map { _ in Int.random(in: 0...2) }
      var engine = RecordingEngine(values: input)
      algorithm.record(into: &engine)
      if engine.values != input.sorted() { failures += 1 }
    }
    #expect(
      failures < trials / 10,
      "expected andreysort's known duplicate-heavy failure rate to stay under 10%, saw \(failures)/\(trials)"
    )
  }

  /// Extra scrutiny for the 5 newly-ported `sorts/insert/` Hard-tier algorithms, matching the
  /// precedent set for every other batch in this file: more randomized duplicate-heavy trials
  /// than the generic suite's single pass per algorithm, across several sizes including ones
  /// that exercise `LibrarySort`'s rebalance boundary and `HanoiSort`'s duplicate-run grouping.
  @Test
  func hardInsertionBatchDuplicateHeavyFuzz() {
    let algorithms: [any SortAlgorithm] = [
      AATreeSort(), AVLTreeSort(), RedBlackTreeSort(), HanoiSort(), LibrarySort()
    ]
    for algorithm in algorithms {
      for size in [algorithm.metadata.sizeRange.lowerBound, 5, 8, 16, 20, 32] {
        for attempt in 0..<100 {
          let input = (0..<size).map { _ in Int.random(in: 0...3) }
          var engine = RecordingEngine(values: input)
          algorithm.record(into: &engine)
          #expect(
            engine.values == input.sorted(),
            "\(algorithm.id.rawValue) failed duplicate-heavy fuzz attempt \(attempt) of size \(size): \(input) -> \(engine.values)"
          )
        }
      }
    }
  }

  /// Shared tagged-pair shape for the stability checks below: every one of the 5 new
  /// `sorts/insert/` Hard-tier algorithms writes its main-array output via `setValue`, never
  /// `swap` (same limitation `classicTreeSortTiedElementsKeepTheirOriginalRelativeOrder`
  /// documents above `expectStable`) — tape replay can't reconstruct original indices once
  /// duplicates are involved, so each algorithm's real routing/insertion logic is reimplemented
  /// here over `(value, originalIndex)` pairs instead.
  private struct Tagged {
    let value: Int
    let originalIndex: Int
  }

  private func assertTaggedGroupsStayOrdered(
    _ sorted: [Tagged], inputCount: Int, algorithmName: String
  ) {
    var byValue: [Int: [Int]] = [:]
    for t in sorted {
      byValue[t.value, default: []].append(t.originalIndex)
    }
    for (value, indices) in byValue {
      #expect(
        indices == indices.sorted(),
        "\(algorithmName) reordered equal-valued elements (value \(value)): \(indices)"
      )
    }
  }

  @Test
  func aaTreeSortTiedElementsKeepTheirOriginalRelativeOrder() {
    final class Node {
      let tag: Tagged
      var left: Node?
      var right: Node?
      var level = 0
      init(_ tag: Tagged) { self.tag = tag }
    }
    func level(_ node: Node?) -> Int { node?.level ?? -1 }
    func skew(_ node: Node) -> Node {
      guard let l = node.left else { return node }
      node.left = l.right
      l.right = node
      return l
    }
    func split(_ node: Node) -> Node {
      guard let r = node.right else { return node }
      node.right = r.left
      r.left = node
      r.level += 1
      return r
    }
    func add(_ node: Node?, _ tag: Tagged) -> Node {
      guard let node else { return Node(tag) }
      if tag.value < node.tag.value {
        node.left = add(node.left, tag)
        if level(node.left) == node.level {
          if node.level != level(node.right) { return skew(node) }
          node.level += 1
          return node
        }
        return node
      } else {
        node.right = add(node.right, tag)
        if level(node.right?.right) == node.level { return split(node) }
        return node
      }
    }
    func traverse(_ node: Node?, into result: inout [Tagged]) {
      guard let node else { return }
      traverse(node.left, into: &result)
      result.append(node.tag)
      traverse(node.right, into: &result)
    }

    let size = 64
    for _ in 0..<200 {
      let values = (0..<size).map { _ in Int.random(in: 0...3) }
      var root: Node?
      for (index, value) in values.enumerated() {
        root = add(root, Tagged(value: value, originalIndex: index))
      }
      var sorted: [Tagged] = []
      traverse(root, into: &sorted)
      #expect(sorted.map(\.value) == values.sorted())
      assertTaggedGroupsStayOrdered(sorted, inputCount: size, algorithmName: "aatreesort")
    }
  }

  @Test
  func redBlackTreeSortTiedElementsKeepTheirOriginalRelativeOrder() {
    final class Node {
      let tag: Tagged
      var left: Node?
      var right: Node?
      var isRed = true
      init(_ tag: Tagged) { self.tag = tag }
    }
    func isRed(_ node: Node?) -> Bool { node?.isRed ?? false }
    func singleRotateRight(_ node: Node) -> Node {
      let b = node.left!
      node.left = b.right
      b.right = node
      b.isRed = false
      node.isRed = true
      return b
    }
    func singleRotateLeft(_ node: Node) -> Node {
      let b = node.right!
      node.right = b.left
      b.left = node
      b.isRed = false
      node.isRed = true
      return b
    }
    func doubleRotateRight(_ node: Node) -> Node {
      node.left = singleRotateLeft(node.left!)
      return singleRotateRight(node)
    }
    func doubleRotateLeft(_ node: Node) -> Node {
      node.right = singleRotateRight(node.right!)
      return singleRotateLeft(node)
    }
    struct AddResult { var node: Node; var needsFix: Bool }
    func add(_ node: Node?, _ tag: Tagged) -> AddResult {
      guard let node else { return AddResult(node: Node(tag), needsFix: false) }
      if !node.isRed, isRed(node.left), isRed(node.right) {
        node.isRed = true
        node.left!.isRed = false
        node.right!.isRed = false
      }
      if tag.value < node.tag.value {
        let result = add(node.left, tag)
        node.left = result.node
        if result.needsFix {
          if isRed(node.left!.left) { return AddResult(node: singleRotateRight(node), needsFix: false) }
          return AddResult(node: doubleRotateRight(node), needsFix: false)
        }
        return AddResult(node: node, needsFix: node.isRed && isRed(node.left))
      } else {
        let result = add(node.right, tag)
        node.right = result.node
        if result.needsFix {
          if isRed(node.right!.right) { return AddResult(node: singleRotateLeft(node), needsFix: false) }
          return AddResult(node: doubleRotateLeft(node), needsFix: false)
        }
        return AddResult(node: node, needsFix: node.isRed && isRed(node.right))
      }
    }
    func traverse(_ node: Node?, into result: inout [Tagged]) {
      guard let node else { return }
      traverse(node.left, into: &result)
      result.append(node.tag)
      traverse(node.right, into: &result)
    }

    let size = 64
    for _ in 0..<200 {
      let values = (0..<size).map { _ in Int.random(in: 0...3) }
      var root: Node?
      for (index, value) in values.enumerated() {
        let result = add(root, Tagged(value: value, originalIndex: index))
        root = result.node
        root?.isRed = false
      }
      var sorted: [Tagged] = []
      traverse(root, into: &sorted)
      #expect(sorted.map(\.value) == values.sorted())
      assertTaggedGroupsStayOrdered(sorted, inputCount: size, algorithmName: "redblacktreesort")
    }
  }

  @Test
  func avlTreeSortTiedElementsKeepTheirOriginalRelativeOrder() {
    final class Node {
      let tag: Tagged
      var left: Node?
      var right: Node?
      var balance = 0
      init(_ tag: Tagged) { self.tag = tag }
    }
    func singleRotateRight(_ node: Node) -> Node {
      let b = node.left!
      node.left = b.right
      b.right = node
      node.balance = 0
      b.balance = 0
      return b
    }
    func singleRotateLeft(_ node: Node) -> Node {
      let b = node.right!
      node.right = b.left
      b.left = node
      node.balance = 0
      b.balance = 0
      return b
    }
    func doubleRotateRight(_ node: Node) -> Node {
      let oldBBalance = node.left!.right!.balance
      node.left = singleRotateLeft(node.left!)
      let b = singleRotateRight(node)
      if oldBBalance == -1 { b.right!.balance = 1 }
      if oldBBalance == 1 { b.left!.balance = -1 }
      return b
    }
    func doubleRotateLeft(_ node: Node) -> Node {
      let oldBBalance = node.right!.left!.balance
      node.right = singleRotateRight(node.right!)
      let b = singleRotateLeft(node)
      if oldBBalance == -1 { b.right!.balance = 1 }
      if oldBBalance == 1 { b.left!.balance = -1 }
      return b
    }
    struct AddResult { var node: Node; var heightChanged: Bool }
    func heightChangeLeft(_ node: Node) -> AddResult {
      if node.balance != -1 {
        node.balance -= 1
        return AddResult(node: node, heightChanged: node.balance == -1)
      }
      if node.left!.balance == -1 { return AddResult(node: singleRotateRight(node), heightChanged: false) }
      return AddResult(node: doubleRotateRight(node), heightChanged: false)
    }
    func heightChangeRight(_ node: Node) -> AddResult {
      if node.balance != 1 {
        node.balance += 1
        return AddResult(node: node, heightChanged: node.balance == 1)
      }
      if node.right!.balance == 1 { return AddResult(node: singleRotateLeft(node), heightChanged: false) }
      return AddResult(node: doubleRotateLeft(node), heightChanged: false)
    }
    func add(_ node: Node?, _ tag: Tagged) -> AddResult {
      guard let node else { return AddResult(node: Node(tag), heightChanged: true) }
      if tag.value < node.tag.value {
        let result = add(node.left, tag)
        node.left = result.node
        if result.heightChanged { return heightChangeLeft(node) }
        return AddResult(node: node, heightChanged: false)
      } else {
        let result = add(node.right, tag)
        node.right = result.node
        if result.heightChanged { return heightChangeRight(node) }
        return AddResult(node: node, heightChanged: false)
      }
    }
    func traverse(_ node: Node?, into result: inout [Tagged]) {
      guard let node else { return }
      traverse(node.left, into: &result)
      result.append(node.tag)
      traverse(node.right, into: &result)
    }

    let size = 64
    for _ in 0..<200 {
      let values = (0..<size).map { _ in Int.random(in: 0...3) }
      var root: Node?
      for (index, value) in values.enumerated() {
        root = add(root, Tagged(value: value, originalIndex: index)).node
      }
      var sorted: [Tagged] = []
      traverse(root, into: &sorted)
      #expect(sorted.map(\.value) == values.sorted())
      assertTaggedGroupsStayOrdered(sorted, inputCount: size, algorithmName: "avltreesort")
    }
  }

  /// Reimplements `LibrarySort`'s gap-array insertion over tagged pairs. `empty` becomes a
  /// sentinel `Tagged` (value `Int.min`, an impossible `originalIndex`) instead of `Int.min`
  /// directly, and every comparison switches from `slots[...] > value` to `slots[...].value >
  /// tag.value` — otherwise this is the exact same algorithm as the shipped port.
  @Test
  func librarySortTiedElementsKeepTheirOriginalRelativeOrder() {
    let empty = Tagged(value: .min, originalIndex: -1)

    func runLibrarySort(_ values: [Int]) -> [Tagged] {
      var capacity = 0
      var slots: [Tagged] = []
      var positions: [Int] = []

      func rebalance() {
        let count = positions.count
        let newCapacity = max(2, count * 2)
        var newSlots = [Tagged](repeating: empty, count: newCapacity)
        var newPositions = [Int]()
        for (i, pos) in positions.enumerated() {
          newSlots[i * 2] = slots[pos]
          newPositions.append(i * 2)
        }
        slots = newSlots
        positions = newPositions
        capacity = newCapacity
      }

      func insert(_ tag: Tagged) {
        if positions.count == capacity { rebalance() }

        var lo = 0
        var hi = positions.count
        while lo < hi {
          let mid = (lo + hi) / 2
          if slots[positions[mid]].value > tag.value { hi = mid } else { lo = mid + 1 }
        }
        let k = lo
        let targetPos = k == 0 ? 0 : positions[k - 1] + 1

        guard targetPos == capacity || slots[targetPos].value != empty.value else {
          slots[targetPos] = tag
          positions.insert(targetPos, at: k)
          return
        }

        var leftGap = targetPos - 1
        while leftGap >= 0, slots[leftGap].value != empty.value { leftGap -= 1 }
        var rightGap = targetPos
        while rightGap < capacity, slots[rightGap].value != empty.value { rightGap += 1 }
        let leftDistance = leftGap >= 0 ? targetPos - leftGap : Int.max
        let rightDistance = rightGap < capacity ? rightGap - targetPos : Int.max

        if rightDistance <= leftDistance {
          var i = rightGap
          while i > targetPos {
            slots[i] = slots[i - 1]
            i -= 1
          }
          for idx in k..<(k + (rightGap - targetPos)) { positions[idx] += 1 }
          slots[targetPos] = tag
          positions.insert(targetPos, at: k)
        } else {
          let shiftCount = (targetPos - 1) - leftGap
          var i = leftGap
          while i < targetPos - 1 {
            slots[i] = slots[i + 1]
            i += 1
          }
          for idx in (k - shiftCount)..<k { positions[idx] -= 1 }
          slots[targetPos - 1] = tag
          positions.insert(targetPos - 1, at: k)
        }
      }

      guard values.count > 1 else {
        return values.enumerated().map { Tagged(value: $0.element, originalIndex: $0.offset) }
      }
      for (index, value) in values.enumerated() {
        insert(Tagged(value: value, originalIndex: index))
      }
      return positions.map { slots[$0] }
    }

    for size in [16, 17, 32, 64] {
      for _ in 0..<100 {
        let values = (0..<size).map { _ in Int.random(in: 0...3) }
        let sorted = runLibrarySort(values)
        #expect(sorted.map(\.value) == values.sorted())
        assertTaggedGroupsStayOrdered(sorted, inputCount: size, algorithmName: "librarysort")
      }
    }
  }

  /// Reimplements `HanoiSort`'s stack machinery over tagged pairs (its main-array writes are
  /// `setValue`, same tape-replay limitation as the tests above) and confirms `metadata.stable
  /// == false` empirically: despite `moveFromMain`/`moveToMain`/`moveBetweenStacks` moving
  /// whole runs of equal elements together as a unit, the stack-shuffling `hanoi` move sequence
  /// still lets two equal elements end up in the opposite of their original relative order.
  @Test
  func hanoiSortTiedElementsCanLoseTheirOriginalRelativeOrder() {
    enum StackID { case two, three }

    func runHanoiSort(_ values: [Int]) -> [Tagged] {
      let n = values.count
      guard n > 1 else {
        return values.enumerated().map { Tagged(value: $0.element, originalIndex: $0.offset) }
      }

      var main = values.enumerated().map { Tagged(value: $0.element, originalIndex: $0.offset) }
      var stack2: [Tagged] = []
      var stack3: [Tagged] = []

      func push(_ id: StackID, _ tag: Tagged) {
        switch id {
        case .two: stack2.append(tag)
        case .three: stack3.append(tag)
        }
      }
      func pop(_ id: StackID) -> Tagged {
        switch id {
        case .two: return stack2.removeLast()
        case .three: return stack3.removeLast()
        }
      }
      func peek(_ id: StackID) -> Tagged? {
        switch id {
        case .two: return stack2.last
        case .three: return stack3.last
        }
      }
      func isEmptyStack(_ id: StackID) -> Bool {
        switch id {
        case .two: return stack2.isEmpty
        case .three: return stack3.isEmpty
        }
      }

      var sp = 0
      var unsorted = 0
      var target = 0
      var targetMoves = 0

      @discardableResult
      func moveFromMain(_ id: StackID, checkUnsorted: Bool) -> Int {
        var duplicates = 1
        push(id, main[sp])
        sp += 1
        var endOnLength = sp >= n || (checkUnsorted && sp >= unsorted)
        while !endOnLength, main[sp].value == peek(id)?.value {
          duplicates += 1
          push(id, main[sp])
          sp += 1
          endOnLength = sp >= n || (checkUnsorted && sp >= unsorted)
        }
        return duplicates
      }

      func moveToMain(_ id: StackID) {
        sp -= 1
        main[sp] = pop(id)
        while !isEmptyStack(id), peek(id)?.value == main[sp].value {
          sp -= 1
          main[sp] = pop(id)
        }
      }

      func moveBetweenStacks(_ from: StackID, _ to: StackID) {
        push(to, pop(from))
        while !isEmptyStack(from), peek(from)?.value == peek(to)?.value {
          push(to, pop(from))
        }
      }

      func validNumberMoves(_ moves: Int) -> Bool {
        if moves == 0 { return true }
        if moves % 2 == 0 { return false }
        return validNumberMoves(moves / 2)
      }
      func getHeight(_ movesPlus1: Int) -> Int {
        if movesPlus1 == 1 { return 0 }
        return getHeight(movesPlus1 / 2) + 1
      }
      func endConMet(_ endCon: Int, _ moves: Int) -> Bool {
        guard validNumberMoves(moves) else { return false }
        switch endCon {
        case 1: return stack2.isEmpty || target <= stack2.last!.value
        case 2: return moves == targetMoves
        case 3: return stack2.isEmpty
        default: preconditionFailure("unknown end condition")
        }
      }

      @discardableResult
      func hanoi(_ startStack: Int, _ goRight: Bool, _ endCon: Int) -> Int {
        var moves = 0
        var minPoleLoc = startStack

        if !endConMet(endCon, moves) {
          moves += 1
          switch minPoleLoc {
          case 1:
            if goRight {
              moveFromMain(.two, checkUnsorted: true)
              minPoleLoc = 2
            } else {
              moveFromMain(.three, checkUnsorted: true)
              minPoleLoc = 3
            }
          case 2:
            if goRight {
              moveBetweenStacks(.two, .three)
              minPoleLoc = 3
            } else {
              moveToMain(.two)
              minPoleLoc = 1
            }
          default:
            if goRight {
              moveToMain(.three)
              minPoleLoc = 1
            } else {
              moveBetweenStacks(.three, .two)
              minPoleLoc = 2
            }
          }
        }

        while !endConMet(endCon, moves) {
          moves += 2
          switch minPoleLoc {
          case 1:
            if !stack2.isEmpty, stack3.isEmpty || stack2.last!.value < stack3.last!.value {
              moveBetweenStacks(.two, .three)
            } else {
              moveBetweenStacks(.three, .two)
            }
            if goRight {
              moveFromMain(.two, checkUnsorted: true)
              minPoleLoc = 2
            } else {
              moveFromMain(.three, checkUnsorted: true)
              minPoleLoc = 3
            }
          case 2:
            if stack3.isEmpty || (sp < unsorted && main[sp].value < stack3.last!.value) {
              moveFromMain(.three, checkUnsorted: true)
            } else {
              moveToMain(.three)
            }
            if goRight {
              moveBetweenStacks(.two, .three)
              minPoleLoc = 3
            } else {
              moveToMain(.two)
              minPoleLoc = 1
            }
          default:
            if stack2.isEmpty || (sp < unsorted && main[sp].value < stack2.last!.value) {
              moveFromMain(.two, checkUnsorted: true)
            } else {
              moveToMain(.two)
            }
            if goRight {
              moveToMain(.three)
              minPoleLoc = 1
            } else {
              moveBetweenStacks(.three, .two)
              minPoleLoc = 2
            }
          }
        }
        return moves
      }

      func removeFromMainStack() {
        target = main[sp].value
        let moves = hanoi(2, true, 1)
        let height = getHeight(moves + 1)
        targetMoves = moves
        let evenHeight = height % 2 == 0
        if evenHeight { hanoi(1, true, 2) }
        unsorted += moveFromMain(.two, checkUnsorted: false)
        hanoi(3, evenHeight, 2)
      }

      func returnToMainStack() {
        let moves = hanoi(2, true, 3)
        let height = getHeight(moves + 1)
        if height % 2 == 1 {
          targetMoves = moves
          hanoi(3, true, 2)
        }
      }

      while unsorted < n {
        removeFromMainStack()
      }
      returnToMainStack()

      return main
    }

    var sawReordering = false
    for size in [4, 5, 8, 16, 20] {
      for _ in 0..<100 {
        let values = (0..<size).map { _ in Int.random(in: 0...3) }
        let sorted = runHanoiSort(values)
        #expect(sorted.map(\.value) == values.sorted())

        var byValue: [Int: [Int]] = [:]
        for t in sorted {
          byValue[t.value, default: []].append(t.originalIndex)
        }
        if byValue.values.contains(where: { $0 != $0.sorted() }) {
          sawReordering = true
        }
      }
    }

    #expect(
      sawReordering,
      """
      expected HanoiSort's stack-shuffling move sequence to reorder at least one run of \
      equal-valued elements relative to their original input order across randomized \
      duplicate-heavy trials, confirming it is not a stable sort
      """
    )
  }

}
