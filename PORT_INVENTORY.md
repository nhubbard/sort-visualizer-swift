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
- [x] BinaryGnomeSort — done (native port batch 4), real category `.exchange`; despite the name,
      ArrayV's implementation is structurally Binary Insertion Sort (binary-search the sorted
      prefix, shift via adjacent swaps) — not the classic gnome-sort walk — noted in the port's doc
      comment and `description.md` rather than inventing gnome-sort behavior that isn't actually
      there, `Modules/BuiltInAlgorithms/Sources/BinaryGnomeSort.swift`
- [ ] BubbleBogoSort
- [x] CircleSortIterative — done (native port batch 4), real category `.exchange`,
      `Modules/BuiltInAlgorithms/Sources/CircleSortIterative.swift`
- [x] CircleSortRecursive — done (native port batch 4), real category `.exchange`,
      `Modules/BuiltInAlgorithms/Sources/CircleSortRecursive.swift`
- [ ] CircloidSort
- [ ] ClassicThreeSmoothCombSort
- [x] CocktailShakerSort — done (native port batch), real category `.exchange` (matches its package
      location here), `Modules/BuiltInAlgorithms/Sources/CocktailShakerSort.swift`
- [ ] CompleteGraphSort
- [x] DualPivotQuickSort — done (native port batch 3), real category `.exchange`, Yaroslavskiy's
      dual-pivot partition (the same algorithm family Java's `Arrays.sort` uses for primitive
      arrays), `Modules/BuiltInAlgorithms/Sources/DualPivotQuickSort.swift`
- [ ] ExchangeBogoSort
- [ ] ForcedStableQuickSort
- [ ] FunSort
- [x] LLQuickSort — done (native port batch 4), real category `.exchange`, ArrayV's actual classic
      quicksort (Lomuto partition, last-element pivot, distinct from our `quicksort.js`),
      `Modules/BuiltInAlgorithms/Sources/LLQuickSort.swift`
- [ ] LRQuickSort
- [ ] LRQuickSortParallel — `[~]` parallel, needs sequential-simulation decision
- [x] OddEvenSort — done (native port batch), real category `.exchange`, distinct `AlgorithmID` from
      the already-shipped `oddevenmergesortiterative`, `Modules/BuiltInAlgorithms/Sources/OddEvenSort.swift`
- [x] OptimizedBubbleSort — done (native port batch 3), real category `.exchange`, the classic
      "shrink by last-swap distance" early-exit optimization,
      `Modules/BuiltInAlgorithms/Sources/OptimizedBubbleSort.swift`
- [x] OptimizedCocktailShakerSort — done (native port batch 4), real category `.exchange`, the same
      "shrink by trailing sorted run" trick as OptimizedBubbleSort but bidirectional (forward + backward
      sweep each pass), `Modules/BuiltInAlgorithms/Sources/OptimizedCocktailShakerSort.swift`
- [x] OptimizedGnomeSort — done (native port batch 4), real category `.exchange`, Wikipedia's "smart
      Gnome Sort" — per-prefix backward-swapping insertion pass, structurally Insertion Sort rather than
      classic Gnome Sort's single forward/backward pointer,
      `Modules/BuiltInAlgorithms/Sources/OptimizedGnomeSort.swift`
- [ ] OptimizedStoogeSort
- [ ] OptimizedStoogeSortStudio
- [ ] QuadStoogeSort
- [ ] ShoveSort
- [ ] SillySort
- [ ] SlopeSort
- [x] SlowSort — done (native port batch 3), real category `.exchange` (despite the "deliberately
      inefficient recursive sort" family resemblance to the already-shipped `.impractical`
      `StoogeSort` — ArrayV's own `setCategory("Exchange Sorts")` is authoritative), true worst-case
      complexity is `O(n^(log n))`, notably worse than any fixed polynomial,
      `Modules/BuiltInAlgorithms/Sources/SlowSort.swift`
- [ ] SnuffleSort
- [ ] StablePermutationSort
- [ ] StableQuickSort
- [ ] StableQuickSortParallel — `[~]` parallel
- [x] StoogeSort — done (native port batch), real category `.impractical` (**not** `.exchange`
      despite this package location — ArrayV's own `setCategory("Impractical Sorts")` is
      authoritative), `Modules/BuiltInAlgorithms/Sources/StoogeSort.swift`; content bundle reused
      and repaired from a pre-existing legacy-pipeline `stoogesort.bundle/`, not built from scratch
- [x] SwaplessBubbleSort — done (native port batch 3), real category `.exchange`, a bubble-sort
      pass expressed as a sequence of single-element carried-value writes instead of two-element
      swaps, `Modules/BuiltInAlgorithms/Sources/SwaplessBubbleSort.swift`
- [ ] TableSort
- [ ] ThreeSmoothCombSortIterative
- [ ] ThreeSmoothCombSortParallel — `[~]` parallel
- [ ] ThreeSmoothCombSortRecursive
- [x] UnoptimizedBubbleSort — done (native port batch 4), real category `.exchange`, the plain
      full-scan-every-pass Bubble Sort with no early-exit optimization,
      `Modules/BuiltInAlgorithms/Sources/UnoptimizedBubbleSort.swift`
- [ ] UnoptimizedCocktailShakerSort

### `sorts/insert/` (18)

- [x] InsertionSort — done (Phase 7 batch, easy pick), `insertionsort.js`
- [x] ShellSort — done (Phase 7 batch, medium pick), `shellsort.js`
- [ ] AATreeSort
- [ ] AVLTreeSort
- [x] BinaryDoubleInsertionSort — done (native port batch 4), real category `.insertion`,
      binary-search-accelerated version of the already-shipped `DoubleInsertionSort`,
      `Modules/BuiltInAlgorithms/Sources/BinaryDoubleInsertionSort.swift`
- [x] BinaryInsertionSort — done (native port batch), real category `.insertion`,
      `Modules/BuiltInAlgorithms/Sources/BinaryInsertionSort.swift`
- [ ] BlockInsertionSort
- [ ] ClassicTreeSort
- [x] DoubleInsertionSort — done (native port batch 3), real category `.insertion`, grows a sorted
      region from the middle outward in both directions at once; **fixed a real out-of-bounds bug
      in ArrayV's own source** (the trailing leftover-element block has no lower-bound guard on its
      backward scan — reverse-sorted input like `[2,1,0]` would throw
      `ArrayIndexOutOfBoundsException` in Java, trap in Swift — added a minimal `pos >= start`
      guard, confirmed via exhaustive/randomized testing this is the only unguarded access that's
      actually reachable), `Modules/BuiltInAlgorithms/Sources/DoubleInsertionSort.swift`
- [ ] HanoiSort
- [ ] LibrarySort
- [ ] PatienceSort
- [x] RecursiveShellSort — done (native port batch), real category `.insertion`,
      `Modules/BuiltInAlgorithms/Sources/RecursiveShellSort.swift`
- [ ] RedBlackTreeSort
- [ ] ShellSortParallel — `[~]` parallel
- [x] SimplifiedLibrarySort — done (native port batch 3), real category `.insertion` ("Library
      Sort"/gapped insertion sort — leaves gaps between sorted elements so future insertions rarely
      need to shift many elements), `Modules/BuiltInAlgorithms/Sources/SimplifiedLibrarySort.swift`
- [ ] SplaySort
- [ ] TreeSort

### `sorts/select/` (25)

- [x] SelectionSort — done (Phase 7 batch, easy pick), `selectionsort.js`
- [x] MaxHeapSort — done (Phase 7 batch, medium pick), `maxheapsort.js`
- [ ] AsynchronousSort
- [ ] BadSort
- [ ] BaseNMaxHeapSort
- [x] BingoSort — done (native port batch 4), real category `.selection`, targets a *value* (not
      an item) per pass so it clears every duplicate occurrence in one sweep,
      `Modules/BuiltInAlgorithms/Sources/BingoSort.swift`
- [ ] BinomialHeapSort
- [ ] BinomialSmoothSort
- [ ] BottomUpHeapSort
- [ ] ClassicTournamentSort
- [x] CycleSort — done (native port batch), real category `.selection`, deterministic single-write
      cycle-following (Cycle Sort's defining minimal-writes property), `Modules/BuiltInAlgorithms/Sources/CycleSort.swift`
- [x] DoubleSelectionSort — done (native port batch 3), real category `.selection`, finds both the
      minimum and maximum of the remaining range in one scan, placing them at both ends per pass;
      exhaustively tested (400K+ trials) the swap-ordering subtlety flagged during porting — no bug
      found, ArrayV's own single guard is sufficient,
      `Modules/BuiltInAlgorithms/Sources/DoubleSelectionSort.swift`
- [ ] FlippedMinHeapSort
- [ ] LazyHeapSort
- [x] MinHeapSort — done (native port batch), real category `.selection`, mirrors the already-shipped
      `MaxHeapSort`'s sift-down with the child comparison flipped, `Modules/BuiltInAlgorithms/Sources/MinHeapSort.swift`
- [ ] MinMaxHeapSort
- [ ] OutOfPlaceHeapSort
- [ ] PoplarHeapSort
- [ ] SmoothSort
- [x] StableCycleSort — done (native port batch 4), real category `.selection`, a stable variant of
      the already-shipped `CycleSort` that tracks resolved positions and not-yet-resolved duplicates
      within each cycle's original span to preserve relative order among ties,
      `Modules/BuiltInAlgorithms/Sources/StableCycleSort.swift`
- [x] StableSelectionSort — done (native port batch 3), real category `.selection`, rotates the
      found minimum into place via single-element shifts instead of a direct swap, making it
      genuinely stable unlike plain `SelectionSort`,
      `Modules/BuiltInAlgorithms/Sources/StableSelectionSort.swift`
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
- [x] FlashSort — done (native port batch 3), real category `.distribution`; **skips ArrayV's own
      dead-code recursion** (it copies oversized classes out via `Arrays.copyOfRange`, recurses,
      then never writes the sorted copy back — the unconditional final straight insertion sort is
      what actually finishes every sort, with or without that recursion) — documented on the type;
      surprisingly found (and exhaustively verified, 87K+ combinations) to be genuinely stable
      despite Flash Sort's usual reputation otherwise, `Modules/BuiltInAlgorithms/Sources/FlashSort.swift`
- [x] GravitySort — done (native port batch 3), real category `.distribution` ("Bead Sort" —
      computes the physical falling-beads result via a tally + backward partial sum rather than a
      literal simulation); real complexity is `O(n*k)` (k = value range), not `O(n+k)` like
      Counting/Pigeonhole Sort, since the value-level loop nests the full element scan,
      `Modules/BuiltInAlgorithms/Sources/GravitySort.swift`
- [ ] GuessSort
- [ ] InPlaceLSDRadixSort
- [ ] IndexSort
- [ ] LessBogoSort
- [ ] MedianQuickBogoSort
- [ ] MergeBogoSort
- [x] MSDRadixSort — done (native port batch), real category `.distribution`, recursive per-bucket
      variant of the already-shipped `LSDRadixSort`, `Modules/BuiltInAlgorithms/Sources/MSDRadixSort.swift`
- [ ] OptimizedGuessSort
- [x] PigeonholeSort — done (native port batch 3), real category `.distribution`; close cousin of
      the already-shipped `CountingSort` but a simpler direct tally-and-re-emit technique with no
      cumulative-sum/backward-scan trick, so — unlike `CountingSort` — it's **not** stable (proven
      by inspecting the recorded tape: zero `.swap` operations, and every write is a value
      manufactured from the bucket index alone, never carrying an original position forward),
      `Modules/BuiltInAlgorithms/Sources/PigeonholeSort.swift`
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
- [x] StaticSort — done (native port batch 4), real category `.distribution`, classify-into-n-buckets
      + cycle-permute + size-dependent insertion/heap-sort finish,
      `Modules/BuiltInAlgorithms/Sources/StaticSort.swift`
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
- [x] RotateMergeSort — done (native port batch 3), real category `.merge`; a genuinely in-place
      merge (unlike the already-shipped `InPlaceMergeSort`'s O(n^2)-degrading insertion-shift) that
      uses binary search to find the split point and block rotation to merge, keeping the ordinary
      O(n log n) merge-sort bound while staying O(1) space,
      `Modules/BuiltInAlgorithms/Sources/RotateMergeSort.swift`
- [ ] RotateMergeSortParallel — `[~]` parallel
- [ ] StacklessRotateMergeSort
- [ ] TwinSort (ArrayV files it under `merge/`'s sibling `hybrid/` package per its template
      location; tracked once, under hybrid below — originally picked as this batch's hybrid/medium
      but swapped for IntroSort, see hybrid/ section)
- [x] WeavedMergeSort — done (native port batch 4), real category `.merge`, splits into interleaved/
      strided sub-sequences instead of contiguous halves before recursing,
      `Modules/BuiltInAlgorithms/Sources/WeavedMergeSort.swift`

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
- [x] BitonicSortRecursive — done (native port batch 3), real category `.concurrent` (a sorting
      network, same as ArrayV's "Concurrent Sorts" family generally means here); H.W. Lang's
      generalized recursive formulation, which handles arbitrary array lengths directly (splitting
      at the greatest power of two below the range size) without needing the already-shipped
      `BitonicSortIterative`'s padding technique — exhaustively verified at many non-power-of-two
      sizes, `Modules/BuiltInAlgorithms/Sources/BitonicSortRecursive.swift`
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
- [x] OddEvenMergeSortRecursive — done (native port batch 3), real category `.concurrent` (Batcher's
      odd-even merge sorting network); a generalized recursive formulation (credited to a rewrite
      by Piotr Grochowski building on H.W. Lang's original) with real parity-dependent branching
      that handles arbitrary array lengths directly — the highest-risk pick in its wave, verified
      with exhaustive coverage of every size 1 through 40 plus many larger sizes (1146+ cases, zero
      failures), `Modules/BuiltInAlgorithms/Sources/OddEvenMergeSortRecursive.swift`
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
- [x] HybridCombSort — done (native port batch 3), real category `.hybrid`; identical to the
      already-shipped `CombSort` except once the shrinking gap drops below a small threshold it
      abandons the comb-gap technique and finishes with one straight insertion-sort pass — proven
      (analytically and empirically, 40+ trials per boundary size) that this finish never fires
      more than once per sort, `Modules/BuiltInAlgorithms/Sources/HybridCombSort.swift`
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
