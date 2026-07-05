# Port Inventory

Standing tracking doc for Phase 7 of `IMPLEMENTATION_PLAN.md` ("porting ArrayV content at scale"),
which is explicitly open-ended with no fixed exit condition. Source of truth for the full list:
`~/ArrayV` (Java), inventoried directly rather than guessed — file names, categories, and line
counts below come from reading that repo, not from `ARCHITECTURE_V2.md`'s illustrative examples.

**Status key:** `[x]` done and shipped · `[ ]` not started · `[~]` needs a decision before porting
(noted inline) · `[v1]` done, but ported from `Legacy/` rather than directly from ArrayV (a
different implementation of the same idea, not a 1:1 translation).

Every "done" row should have a corresponding `App/Resources/Algorithms/<id>.js` +
`.manifest.json`, `App/Resources/Shuffles/<id>.js` + `.manifest.json`, or
`Modules/BuiltInVisualizers/Sources/<Name>.swift`.

## Sorting algorithms (208 ArrayV classes across 9 categories, + 21 shared `templates/` base
classes that are never ported directly — only their concrete subclasses are)

### `sorts/exchange/` (41)

- [v1] BubbleSort — done (Phase 3), ported from `Legacy/` (`bubblesort.js`)
- [v1] QuickSort — done (Phase 7 batch), ported from `Legacy/`'s two-pointer partition scheme, via
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
- [ ] CocktailShakerSort (v1 has "shakersort" — good next pick)
- [ ] CompleteGraphSort
- [ ] DualPivotQuickSort
- [ ] ExchangeBogoSort
- [ ] ForcedStableQuickSort
- [ ] FunSort
- [ ] LLQuickSort (ArrayV's actual classic quicksort — distinct from our `quicksort.js`)
- [ ] LRQuickSort
- [ ] LRQuickSortParallel — `[~]` parallel, needs sequential-simulation decision
- [ ] OddEvenSort (v1 has "oddevensort" — good next pick)
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
- [ ] StoogeSort (v1 has "stoogesort" — good next pick)
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
- [ ] BinaryInsertionSort
- [ ] BlockInsertionSort
- [ ] ClassicTreeSort
- [ ] DoubleInsertionSort
- [ ] HanoiSort
- [ ] LibrarySort
- [ ] PatienceSort
- [ ] RecursiveShellSort
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
- [ ] CycleSort
- [ ] DoubleSelectionSort
- [ ] FlippedMinHeapSort
- [ ] LazyHeapSort
- [ ] MinHeapSort (v1 has "heapsort" mapped to MaxHeapSort above; this is its mirror)
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

- [x] BogoSort — done (Phase 7 batch, easy pick), `bogosort.js`
- [x] LSDRadixSort — done (Phase 7 batch, medium pick), `lsdradixsort.js`
- [ ] AmericanFlagSort
- [ ] BinaryQuickSortIterative
- [ ] BinaryQuickSortRecursive
- [ ] BogoBogoSort
- [ ] BozoSort (29 lines — simplest in this category, good next "easy" elsewhere if needed)
- [ ] ClassicGravitySort
- [ ] CocktailBogoSort
- [ ] CountingSort
- [ ] DeterministicBogoSort
- [ ] FlashSort
- [ ] GravitySort
- [ ] GuessSort
- [ ] InPlaceLSDRadixSort
- [ ] IndexSort
- [ ] LessBogoSort
- [ ] MedianQuickBogoSort
- [ ] MergeBogoSort
- [ ] MSDRadixSort
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
- [ ] BottomUpMergeSort
- [ ] BufferedStoogeSort
- [ ] ImprovedInPlaceMergeSort
- [ ] InPlaceMergeSort
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
- [ ] BoseNelsonSortIterative
- [ ] BoseNelsonSortParallel — `[~]` parallel
- [ ] BoseNelsonSortRecursive
- [ ] CreaseSort
- [ ] DiamondSortIterative
- [ ] DiamondSortRecursive
- [ ] FoldSort
- [ ] MatrixSort
- [ ] MergeExchangeSortIterative
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
- [ ] CocktailMergeSort
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
