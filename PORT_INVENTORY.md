# Port Inventory

Standing tracking doc for Phase 7 of `IMPLEMENTATION_PLAN.md` ("porting ArrayV content at scale"),
which is explicitly open-ended with no fixed exit condition. Source of truth for the full list:
`~/ArrayV` (Java), inventoried directly rather than guessed — file names, categories, and line
counts below come from reading that repo, not from `ARCHITECTURE_V2.md`'s illustrative examples.

**Status key:** `[x]` done and shipped · `[ ]` not started · `[~]` needs a decision before porting
(noted inline) · `[v1]` done, but ported from `Legacy/` rather than directly from ArrayV (a
different implementation of the same idea, not a 1:1 translation).

As of the native-porting batch (`ARCHITECTURE_V2.md` §2.6, revised), a "done" **sorting algorithm**
row means a native `Modules/BuiltInAlgorithms/Sources/<Name>.swift` `SortAlgorithm` conformance
registered in `AlgorithmRegistry.shared.builtIns` — not a `.js`/`.manifest.json` pair. JavaScript
(`App/Resources/Algorithms/<id>.js` + `.manifest.json`) is now only ever a *temporary* stage for a
brand-new algorithm you're still proving out — expect to see at most a handful of `.js` files
there at any time, never all of them, and expect any given one to be retired (deleted, with its
logic ported to `BuiltInAlgorithms`) once it's confirmed correct. Shuffles remain scripted-only
(`App/Resources/Shuffles/<id>.js` + `.manifest.json`, no native equivalent yet) and visualizations
remain native-only (`Modules/BuiltInVisualizers/Sources/<Name>.swift`) — neither of those changed.

## Sorting algorithms (208 ArrayV classes across 9 categories, + 21 shared `templates/` base
classes that are never ported directly — only their concrete subclasses are)

### `sorts/exchange/` (41)

- [x] BubbleSort — done (Phase 3), ported from `Legacy/` (`bubblesort.js`)
- [x] QuickSort — done (Phase 7 batch), ported from `Legacy/`'s two-pointer partition scheme, via
  the native PoC from Phase 2 (`quicksort.js`) — **not** a port of ArrayV's `LLQuickSort`/
  `LRQuickSort` (different partition scheme; those remain unported below)
- [x] GnomeSort — done (Phase 7 batch, easy pick), `gnomesort.js`
- [x] CombSort — done (Phase 7 batch, medium pick), `combsort.js`
- [ ] BinaryGnomeSort
- [ ] BubbleBogoSort
- [ ] CircleSortIterative
- [ ] CircleSortRecursive
- [ ] CircloidSort
- [ ] ClassicThreeSmoothCombSort
- [x] CocktailShakerSort — done (native port batch), real category `.exchange` (matches its package
      location here), `Modules/BuiltInAlgorithms/Sources/CocktailShakerSort.swift`
- [ ] CompleteGraphSort
- [ ] DualPivotQuickSort
- [ ] ExchangeBogoSort
- [ ] ForcedStableQuickSort
- [ ] FunSort
- [ ] LLQuickSort (ArrayV's actual classic quicksort — distinct from our `quicksort.js`)
- [ ] LRQuickSort
- [ ] LRQuickSortParallel — `[~]` parallel, needs sequential-simulation decision
- [x] OddEvenSort — done (native port batch), real category `.exchange`, distinct `AlgorithmID` from
      the already-shipped `oddevenmergesortiterative`, `Modules/BuiltInAlgorithms/Sources/OddEvenSort.swift`
- [ ] OptimizedBubbleSort
- [ ] OptimizedCocktailShakerSort
- [ ] OptimizedGnomeSort
- [ ] OptimizedStoogeSort
- [ ] OptimizedStoogeSortStudio
- [ ] QuadStoogeSort
- [ ] ShoveSort
- [ ] SillySort
- [ ] SlopeSort
- [ ] SlowSort
- [ ] SnuffleSort
- [ ] StablePermutationSort
- [ ] StableQuickSort
- [ ] StableQuickSortParallel — `[~]` parallel
- [x] StoogeSort — done (native port batch), real category `.impractical` (**not** `.exchange`
      despite this package location — ArrayV's own `setCategory("Impractical Sorts")` is
      authoritative), `Modules/BuiltInAlgorithms/Sources/StoogeSort.swift`; content bundle reused
      and repaired from a pre-existing legacy-pipeline `stoogesort.bundle/`, not built from scratch
- [ ] SwaplessBubbleSort
- [ ] TableSort
- [ ] ThreeSmoothCombSortIterative
- [ ] ThreeSmoothCombSortParallel — `[~]` parallel
- [ ] ThreeSmoothCombSortRecursive
- [ ] UnoptimizedBubbleSort
- [ ] UnoptimizedCocktailShakerSort

### `sorts/insert/` (18)

- [x] InsertionSort — done (Phase 7 batch, easy pick), `insertionsort.js`
- [x] ShellSort — done (Phase 7 batch, medium pick), `shellsort.js`
- [ ] AATreeSort
- [ ] AVLTreeSort
- [ ] BinaryDoubleInsertionSort
- [x] BinaryInsertionSort — done (native port batch), real category `.insertion`,
      `Modules/BuiltInAlgorithms/Sources/BinaryInsertionSort.swift`
- [ ] BlockInsertionSort
- [ ] ClassicTreeSort
- [ ] DoubleInsertionSort
- [ ] HanoiSort
- [ ] LibrarySort
- [ ] PatienceSort
- [x] RecursiveShellSort — done (native port batch), real category `.insertion`,
      `Modules/BuiltInAlgorithms/Sources/RecursiveShellSort.swift`
- [ ] RedBlackTreeSort
- [ ] ShellSortParallel — `[~]` parallel
- [ ] SimplifiedLibrarySort
- [ ] SplaySort
- [ ] TreeSort

### `sorts/select/` (25)

- [x] SelectionSort — done (Phase 7 batch, easy pick), `selectionsort.js`
- [x] MaxHeapSort — done (Phase 7 batch, medium pick), `maxheapsort.js`
- [ ] AsynchronousSort
- [ ] BadSort
- [ ] BaseNMaxHeapSort
- [ ] BingoSort
- [ ] BinomialHeapSort
- [ ] BinomialSmoothSort
- [ ] BottomUpHeapSort
- [ ] ClassicTournamentSort
- [x] CycleSort — done (native port batch), real category `.selection`, deterministic single-write
      cycle-following (Cycle Sort's defining minimal-writes property), `Modules/BuiltInAlgorithms/Sources/CycleSort.swift`
- [ ] DoubleSelectionSort
- [ ] FlippedMinHeapSort
- [ ] LazyHeapSort
- [x] MinHeapSort — done (native port batch), real category `.selection`, mirrors the already-shipped
      `MaxHeapSort`'s sift-down with the child comparison flipped, `Modules/BuiltInAlgorithms/Sources/MinHeapSort.swift`
- [ ] MinMaxHeapSort
- [ ] OutOfPlaceHeapSort
- [ ] PoplarHeapSort
- [ ] SmoothSort
- [ ] StableCycleSort
- [ ] StableSelectionSort
- [ ] TernaryHeapSort
- [ ] TournamentSort
- [ ] TriangularHeapSort
- [ ] WeakHeapSort

### `sorts/distribute/` (36)

- [x] BogoSort — done (Phase 7 batch, easy pick), `bogosort.js`; **rewritten in the native port
      batch** from a literal random-shuffle-until-sorted loop to a deterministic lexicographic
      `next_permutation` walk (with `sizeRange` shrunk to `4...7`) — `RecordingEngine` has to
      pre-record the *entire* tape before playback, and an open-ended random walk has no ceiling on
      how large that tape can grow before it happens to land on sorted; the deterministic walk
      keeps the "try every arrangement" spirit with a hard n!-step ceiling instead
- [x] LSDRadixSort — done (Phase 7 batch, medium pick), `lsdradixsort.js`
- [ ] AmericanFlagSort
- [ ] BinaryQuickSortIterative
- [ ] BinaryQuickSortRecursive
- [ ] BogoBogoSort
- [x] BozoSort — done (native port batch), real category `.impractical` (**not** `.distribute`
      despite this package location — ArrayV's own `setCategory("Impractical Sorts")` is
      authoritative); ArrayV's "swap two random indices, check if sorted, repeat" was ported as a
      deterministic single-swap-per-step permutation walk (Heap's algorithm) instead of a literal
      random walk — see the note on `BogoSort` below for why,
      `Modules/BuiltInAlgorithms/Sources/BozoSort.swift`
- [ ] ClassicGravitySort
- [ ] CocktailBogoSort
- [x] CountingSort — done (native port batch), real category `.distribution`,
      `Modules/BuiltInAlgorithms/Sources/CountingSort.swift`
- [ ] DeterministicBogoSort
- [ ] FlashSort
- [ ] GravitySort
- [ ] GuessSort
- [ ] InPlaceLSDRadixSort
- [ ] IndexSort
- [ ] LessBogoSort
- [ ] MedianQuickBogoSort
- [ ] MergeBogoSort
- [x] MSDRadixSort — done (native port batch), real category `.distribution`, recursive per-bucket
      variant of the already-shipped `LSDRadixSort`, `Modules/BuiltInAlgorithms/Sources/MSDRadixSort.swift`
- [ ] OptimizedGuessSort
- [ ] PigeonholeSort
- [ ] QuickBogoSort
- [ ] RandomGuessSort
- [ ] RotateLSDRadixSort
- [ ] RotateMSDRadixSort
- [ ] SelectionBogoSort
- [ ] ShatterSort
- [ ] SimpleShatterSort
- [ ] SimplisticGravitySort
- [ ] SmartBogoBogoSort
- [ ] SmartGuessSort
- [ ] StacklessAmericanFlagSort
- [ ] StacklessBinaryQuickSort
- [ ] StaticSort
- [ ] TimeSort

### `sorts/merge/` (19)

- [x] MergeSort — done (Phase 7 batch, easy pick), `mergesort.js`
- [x] StrandSort — done (Phase 7 batch, medium pick), `strandsort.js`
- [ ] AndreySort
- [ ] BlockSwapMergeSort
- [x] BottomUpMergeSort — done (native port batch), real category `.merge`, non-recursive
      doubling-width variant of the already-shipped `MergeSort`, `Modules/BuiltInAlgorithms/Sources/BottomUpMergeSort.swift`
- [ ] BufferedStoogeSort
- [ ] ImprovedInPlaceMergeSort (**not** ported — distinct from plain `InPlaceMergeSort` below)
- [x] InPlaceMergeSort — done (native port batch), real category `.merge`; merges via rotation/
      insertion-shift instead of an aux buffer, so despite the name it's `spaceComplexity: O(log n)`
      (recursion stack only) at the cost of a worse `O(n^2)` average/worst merge step — **not**
      stable (positional swaps let equal elements leapfrog each other across recursion levels,
      verified empirically), `Modules/BuiltInAlgorithms/Sources/InPlaceMergeSort.swift`
- [ ] IterativeTopDownMergeSort
- [ ] LazyStableSort
- [ ] MergeSortParallel — `[~]` parallel
- [ ] NewShuffleMergeSort
- [ ] PDMergeSort
- [ ] QuadSort
- [ ] RotateMergeSort
- [ ] RotateMergeSortParallel — `[~]` parallel
- [ ] StacklessRotateMergeSort
- [ ] TwinSort (ArrayV files it under `merge/`'s sibling `hybrid/` package per its template
      location; tracked once, under hybrid below — originally picked as this batch's hybrid/medium
      but swapped for IntroSort, see hybrid/ section)
- [ ] WeavedMergeSort

### `sorts/misc/` (4)

- [x] PancakeSort — done (Phase 7 batch, easy pick), `pancakesort.js`
- [x] BurntPancakeSort — done (Phase 7 batch, medium pick — **substituted for the originally
      planned `PancakeInsertionSort`**, which needed held-value binary-search "monobound" helpers
      plus a direction-flip state machine; deemed too complex/fragile to port faithfully in this
      batch), `burntpancakesort.js`
- [ ] PancakeInsertionSort — deferred (see substitution note above); still worth a real port later
- [ ] StalinSort — `[~]` **not portable as-is**: it deletes out-of-order elements rather than
      repositioning them (a shrinking result, not a permutation). `SortOperation` has no
      remove/shrink case. Would need either a new engine primitive or a "fake it with duplicate
      values" hack — deferred until there's a real reason to add one.

### `sorts/concurrent/` (22)

- [x] BitonicSortIterative — done (Phase 7 batch, easy pick), `bitonicsortiterative.js`
- [x] OddEvenMergeSortIterative — done (Phase 7 batch, medium pick), `oddevenmergesortiterative.js`
- [ ] BitonicSortParallel — `[~]` parallel
- [ ] BitonicSortRecursive
- [x] BoseNelsonSortIterative — done (native port batch), real category `.concurrent` (ArrayV's
      "Concurrent Sorts" here really means *sorting network* — a fixed, data-independent
      compare-swap sequence, historically designed for parallel/hardware execution but run
      sequentially here, same as the already-shipped `BitonicSortIterative`/
      `OddEvenMergeSortIterative`), `Modules/BuiltInAlgorithms/Sources/BoseNelsonSortIterative.swift`
- [ ] BoseNelsonSortParallel — `[~]` parallel
- [ ] BoseNelsonSortRecursive
- [ ] CreaseSort
- [ ] DiamondSortIterative
- [ ] DiamondSortRecursive
- [ ] FoldSort
- [ ] MatrixSort
- [x] MergeExchangeSortIterative — done (native port batch), real category `.concurrent` (Batcher's
      odd-even merge sorting network), `Modules/BuiltInAlgorithms/Sources/MergeExchangeSortIterative.swift`
- [ ] OddEvenMergeSortParallel — `[~]` parallel
- [ ] OddEvenMergeSortRecursive
- [ ] PairwiseMergeSortIterative
- [ ] PairwiseMergeSortRecursive
- [ ] PairwiseSortIterative
- [ ] PairwiseSortRecursive
- [ ] WeaveSortIterative
- [ ] WeaveSortParallel — `[~]` parallel
- [ ] WeaveSortRecursive

### `sorts/quick/` (2 — the entire category)

- [x] TernaryLLQuickSort — done (Phase 7 batch, easy pick), `ternaryllquicksort.js`
- [x] TernaryLRQuickSort — done (Phase 7 batch, medium pick), `ternarylrquicksort.js`

### `sorts/hybrid/` (41 — generally the most complex category; no file here is genuinely "easy")

- [x] BinaryMergeSort — done (Phase 7 batch, relatively-easier pick; a genuine insertion/merge
      hybrid rather than a literal binary-search insertion sort), `binarymergesort.js`
- [x] IntroSort — done (Phase 7 batch, relatively-medium pick — **substituted for the originally
      planned `TwinSort`**, whose real-world implementation turned out to need an initial "twin
      swap" pre-pass plus intricate bottom-up tail-merging with a separate half-size swap buffer
      requiring extensive held-value tracking, far more complex than its 217-line template
      suggested; IntroSort instead reuses building blocks — ternary-quicksort-style strict
      comparisons, 0-indexed heapsort, swap-based insertion sort — already validated elsewhere in
      this same batch), `introsort.js`
- [ ] TwinSort — deferred (see substitution note above); still worth a real port later
- [ ] AdaptiveGrailSort (915 lines — very complex)
- [ ] BufferPartitionMergeSort
- [ ] ChaliceSort (767 lines — very complex)
- [ ] CircularGrailSort
- [x] CocktailMergeSort — done (native port batch), real category `.hybrid`; simplifies ArrayV's
      ~950-line galloping-mode `TimSorting` merge phase down to a plain bottom-up pairwise merge
      (same technique as the already-shipped `BottomUpMergeSort`, starting from a run width of
      `minRunLen` instead of 1) — correctness-preserving since galloping mode only changes how many
      comparisons a merge of two known-sorted runs takes, never the resulting order,
      `Modules/BuiltInAlgorithms/Sources/CocktailMergeSort.swift`
- [ ] DropMergeSort
- [ ] EctaSort
- [ ] FifthMergeSort
- [ ] FlanSort
- [ ] FluxSort
- [ ] GrailSort (780-line template)
- [ ] HybridCombSort
- [ ] ImprovedBlockSelectionSort
- [ ] IntroCircleSortIterative
- [ ] IntroCircleSortRecursive
- [ ] IntroSort
- [ ] KotaSort (1142-line template — largest in the whole `sorts/` tree)
- [ ] LazierestSort
- [ ] LaziestSort
- [ ] MedianMergeSort
- [ ] MergeInsertionSort
- [ ] OptimizedBottomUpMergeSort
- [ ] OptimizedDualPivotQuickSort
- [ ] OptimizedLazyStableSort
- [ ] OptimizedRotateMergeSort
- [ ] OptimizedWeaveMergeSort
- [ ] ParallelBlockMergeSort — `[~]` parallel
- [ ] ParallelGrailSort — `[~]` parallel
- [ ] PDQBranchedSort (570-line template)
- [ ] PDQBranchlessSort
- [ ] RemiSort
- [ ] SqrtSort
- [ ] StacklessDualPivotQuickSort
- [ ] StacklessHybridQuickSort
- [ ] SynchronousSqrtSort
- [ ] TimSort (950-line template)
- [ ] UnstableGrailSort
- [ ] WeaveMergeSort
- [ ] WikiSort (1068-line template)
- [ ] YujisBufferedMergeSort2

## Shuffles (45 in ArrayV's `Shuffles.java` enum — no subdirectories, listed flat)

v1's original 5 (Phase 6) don't map 1:1 onto ArrayV's list — noted inline where there's a rough
equivalent.

- [x] random.js — done (Phase 6), ports v1's "Random" (Fisher-Yates) ≈ ArrayV's `RANDOM`
- [x] ascending.js — done (Phase 6), ports v1's "Ascending" (no-op) ≈ ArrayV's `ALREADY`/`SORTED`
- [x] descending.js — done (Phase 6), ports v1's "Descending" (reverse) ≈ ArrayV's `REVERSE`
- [x] shuffledcubic.js — done (Phase 6), v1-original curve shuffle, no ArrayV equivalent
- [x] shuffledquintic.js — done (Phase 6), v1-original curve shuffle, no ArrayV equivalent
- [ ] ALMOST ("Slight Shuffle")
- [ ] NAIVE ("Naive Randomly")
- [ ] NOISY ("Noisy")
- [ ] BLOCK_RANDOMLY ("Randomly w/ Blocks")
- [ ] SHUFFLED_TAIL ("Scrambled Tail")
- [ ] SHUFFLED_HEAD ("Scrambled Head")
- [ ] MOVED_ELEMENT ("Shifted Element")
- [ ] SHUFFLED_ODDS ("Scrambled Odds")
- [ ] SHUFFLED_HALF ("Shuffled Half")
- [ ] PARTITIONED ("Partitioned")
- [ ] PARTIAL_REVERSE ("Half Reversed")
- [ ] HALF_ROTATION ("Half Rotation")
- [ ] DOUBLE_LAYERED ("Double Layered")
- [ ] FINAL_MERGE ("Final Merge Pass")
- [ ] REAL_FINAL_MERGE ("Shuffled Final Merge")
- [ ] SAWTOOTH ("Sawtooth")
- [ ] ORGAN ("Pipe Organ")
- [ ] FINAL_BITONIC ("Final Bitonic Pass")
- [ ] INTERLACED ("Interlaced")
- [ ] FINAL_RADIX ("Final Radix")
- [ ] REAL_FINAL_RADIX ("Real Final Radix")
- [ ] REC_RADIX ("Recursive Final Radix")
- [ ] BST_TRAVERSAL ("BST Traversal")
- [ ] INV_BST ("Inverted BST")
- [ ] LOG_SLOPES ("Logarithmic Slopes")
- [ ] CIRCLE ("First Circle Pass")
- [ ] PAIRWISE ("Final Pairwise Pass")
- [ ] REC_REV ("Recursive Reversal")
- [ ] GRAY_CODE ("Gray Code Fractal")
- [ ] SIERPINSKI ("Sierpinski Triangle")
- [ ] TRIANGULAR ("Triangular")
- [ ] BIT_REVERSE ("Bit Reversal")
- [ ] BLOCK_REVERSE ("Block Reverse")
- [ ] HEAPIFIED ("Heapified")
- [ ] SMOOTH ("Smoothified")
- [ ] POPLAR ("Poplarified")
- [ ] TRI_HEAP ("Triangular Heapified")
- [ ] QSORT_BAD ("Quicksort Adversary")
- [ ] PDQ_BAD ("PDQ Adversary" — ~345 lines, embeds most of pdqsort's own logic)
- [ ] GRAIL_BAD ("Grailsort Adversary")
- [ ] SHUF_MERGE_BAD ("Shuffle Merge Adversary")

## Visualizers (15 — the full, fixed set; `BuiltInVisualizers` is native-only per §2A.3, no
scripting for this axis)

- [x] BarGraph — done (Phase 4), `BarGraphVisualizer.swift`
- [x] Rainbow — done (Phase 5), `RainbowVisualizer.swift`
- [x] ScatterPlot (ArrayV: "Dots") — done (Phase 5), `ScatterPlotVisualizer.swift`
- [ ] DisparityBarGraph — needs `originalIndices` (§2A.6 disparity family)
- [ ] SineWave
- [ ] ColorCircle
- [ ] DisparityCircle — needs `originalIndices`
- [ ] DisparityChords — needs `originalIndices`; most geometrically complex of the circle group
- [ ] Spiral
- [ ] SpiralDots
- [ ] DisparityDots — needs `originalIndices`
- [ ] WaveDots
- [ ] PixelMesh
- [ ] HoopStack
- [ ] CustomImage — `[~]` deferred per §2A.6 (needs an image-picker UI + per-pixel remap; the
      largest/most novelty-heavy visual, explicitly a Phase 12 stretch goal candidate)
