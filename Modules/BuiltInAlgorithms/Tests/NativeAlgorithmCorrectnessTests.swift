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
    AsynchronousSort(), BadSort(), BaseNMaxHeapSort(), BinaryDoubleInsertionSort(),
    BinaryGnomeSort(),
    BinaryInsertionSort(), BinaryMergeSort(), BingoSort(), BinomialHeapSort(), BinomialSmoothSort(),
    BitonicSortIterative(),
    BitonicSortRecursive(), BlockSwapMergeSort(), BogoSort(), BoseNelsonSortIterative(),
    BottomUpHeapSort(), BottomUpMergeSort(), BozoSort(), BubbleBogoSort(), BubbleSort(),
    BurntPancakeSort(),
    CircleSortIterative(), CircleSortRecursive(), CircloidSort(),
    ClassicThreeSmoothCombSort(), ClassicTreeSort(), CocktailBogoSort(),
    CocktailMergeSort(), CocktailShakerSort(), CombSort(), CountingSort(), CycleSort(),
    DeterministicBogoSort(), DiamondSortRecursive(), DoubleInsertionSort(), DoubleSelectionSort(),
    DualPivotQuickSort(), ExchangeBogoSort(), FlashSort(), FlippedMinHeapSort(), GnomeSort(),
    GravitySort(),
    GuessSort(), HybridCombSort(), InPlaceMergeSort(), InsertionSort(), IntroCircleSortIterative(),
    IntroSort(), LazyHeapSort(), LessBogoSort(), LLQuickSort(), LRQuickSort(), LSDRadixSort(),
    MaxHeapSort(),
    MedianQuickBogoSort(), MergeBogoSort(), MergeExchangeSortIterative(), MergeSort(),
    MinHeapSort(), MSDRadixSort(),
    OddEvenMergeSortIterative(), OddEvenMergeSortRecursive(), OddEvenSort(),
    OptimizedBubbleSort(), OptimizedCocktailShakerSort(), OptimizedGnomeSort(),
    OptimizedGuessSort(),
    PairwiseSortIterative(), PancakeSort(), PigeonholeSort(), QuickBogoSort(), QuickSort(),
    RandomGuessSort(), RecursiveShellSort(), RotateMergeSort(), SelectionBogoSort(),
    SelectionSort(), ShellSort(),
    SimplifiedLibrarySort(), SlopeSort(), SlowSort(), SmartBogoBogoSort(), SmartGuessSort(),
    SnuffleSort(), StableCycleSort(),
    StablePermutationSort(), StableSelectionSort(), StaticSort(), StoogeSort(), StrandSort(),
    SwaplessBubbleSort(),
    TernaryHeapSort(), TernaryLLQuickSort(), TernaryLRQuickSort(), ThreeSmoothCombSortIterative(),
    ThreeSmoothCombSortRecursive(), TriangularHeapSort(), UnoptimizedBubbleSort(),
    UnoptimizedCocktailShakerSort(), WeakHeapSort(), WeavedMergeSort(), WeaveMergeSort()
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
}
