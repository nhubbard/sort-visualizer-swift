# Port Inventory

Standing tracking doc for Phase 7 of `IMPLEMENTATION_PLAN.md` ("porting ArrayV content at scale"),
which is explicitly open-ended with no fixed exit condition. Source of truth for the full list:
`~/ArrayV` (Java), inventoried directly rather than guessed — the file names, categories, and line
counts below come from reading that repo, not from `ARCHITECTURE_V2.md`'s illustrative examples.

**Status key:** `[x]` done and shipped · `[ ]` not started · `[~]` needs a decision before porting
(noted inline)

As of the native-porting batch (`ARCHITECTURE_V2.md` §2.6, revised), a "done" **sorting algorithm**
row means a native `Modules/BuiltInAlgorithms/Sources/<Name>.swift` `SortAlgorithm` conformance
registered in `AlgorithmRegistry.shared.builtIns` — not a `.js`/`.manifest.json` pair. JavaScript
(`App/Resources/Algorithms/<id>.js` + `.manifest.json`) is now only ever a *temporary* stage for a
brand-new algorithm you're still proving out — expect to see at most a handful of `.js` files
there at any time, never all of them, and expect any given one to be retired (deleted, with its
logic ported to `BuiltInAlgorithms`) once it's confirmed correct. Shuffles followed the same path
as of the native shuffle port batch — see §2's preamble. Visualizations remain native-only
(`Modules/BuiltInVisualizers/Sources/<Name>.swift`), unchanged.

The eventual goal is to retire the JS bridge (`ScriptingKit`'s `JSAlgorithmAdapter`/`ScriptRunner`/
`JSRecordingEngineBridge`) entirely, once new-algorithm prototyping in JS is no longer a live
workflow — not yet, while there's still a large unported backlog below.

## 1. Sorting algorithms

208 ArrayV classes across 9 categories, + 21 shared `templates/` base classes that are never
ported directly — only their concrete subclasses are.

ArrayV's `*Parallel` variants (12 across the categories below) are declined outright, not tracked
as pending: `RecordingEngine`'s tape is a single deterministic writer, so a "parallel" port would
just re-record the identical compare/swap sequence as the already-shipped sequential version under
a different name — real thread interleaving has no meaning in a model with one writer, and faking
it would be visual theater over duplicate content, not new algorithmic behavior. Removed from the
per-category lists below rather than left as "Decision Required" — the decision is already made.

**Effort tiers** (2026-07-11 pass): every remaining "Not Started" row below is now grouped by how
complex the *ArrayV Java source* actually is, not by category or alphabetical order. The number
cited per algorithm is "effective lines" — its own concrete class's line count, plus (when it
`extends` a shared `sorts/templates/` class rather than the bare `Sort` base) that template's own
line count, since that inherited logic is real complexity a port has to actually understand and
translate, not optional reading:

- **Trivial** (≤50 effective lines) — under an hour, usually a single self-contained loop.
- **Easy** (51–100) — comparable to this project's own "easy pick" batches so far.
- **Medium** (101–200) — comparable to "medium pick"/"relatively medium" batches so far.
- **Hard** (201–400, or a same-category prerequisite that isn't ported yet) — multi-session.
- **Very Hard** (400+, or extends one of the five largest templates — `GrailSorting` 780,
  `QuadSorting` 875, `TimSorting` 950, `WikiSorting` 1068, `KotaSorting` 1142, `PDQSorting` 570) —
  multi-day, matches the "very complex" language already used for `AdaptiveGrailSort`/`ChaliceSort`.

Several clusters share one large template or one unported prerequisite — porting the shared piece
once makes every sibling in that cluster much cheaper than its tier alone suggests, so tackle a
cluster together rather than picking its members apart on separate days:

- **The Bogo/Guess family (16 algorithms, spread across exchange + distribute below)** all extend
  `BogoSorting` (261 lines), but the *real* blocker isn't that template — it's the same
  "`RecordingEngine` can't pre-record an open-ended random search" problem `BogoSort`/`BozoSort`
  already solved by rewriting as a deterministic permutation walk (see
  `Modules/BuiltInAlgorithms/Sources/BogoSort.swift`'s doc comment). Every one of these 16 needs
  that same rewrite treatment, not a literal port of `BogoSorting` — apply the established pattern
  per variant rather than re-deriving it, and expect each variant to be cheap once the first one in
  a session re-establishes the pattern.
- **The Grail cluster**: `BlockInsertionSort` (insert), `GrailSort`, `OptimizedLazyStableSort`
  (hybrid), and `LazyStableSort` (merge) all extend `GrailSorting` (780 lines) — port the template
  once, then all four wrapper algorithms are comparatively small.
- **The Quad cluster**: `QuadSort` (merge) and `FluxSort` (hybrid) both extend `QuadSorting`
  (875 lines).
- **The PDQ cluster**: `PDQBranchedSort` and `PDQBranchlessSort` (both hybrid) both extend
  `PDQSorting` (570 lines).
- **The MultiWayMerge cluster**: `FlanSort` and `RemiSort` (both hybrid) both extend
  `MultiWayMergeSorting` (82 lines) — a much smaller shared template, so this pair is cheaper than
  its members' own size alone suggests.
- **The BlockMerge cluster**: `ChaliceSort` and `SynchronousSqrtSort` (both hybrid) both extend
  `BlockMergeSorting` (352 lines).
- `NewShuffleMergeSort` (merge) directly extends the not-yet-ported `IterativeTopDownMergeSort`
  (merge) — port that prerequisite first, not just its shared template.
- `IntroCircleSortIterative`/`IntroCircleSortRecursive` (hybrid) extend the already-small
  `IterativeCircleSorting`/`CircleSorting` templates (44/48 lines) — trivial once `CircleSort*` (already shipped) established the pattern.

### a. Exchange sorts (`sorts/exchange/`, 41)

#### Completed

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
- [x] CircleSortIterative — done (native port batch 4), real category `.exchange`,
      `Modules/BuiltInAlgorithms/Sources/CircleSortIterative.swift`
- [x] CircleSortRecursive — done (native port batch 4), real category `.exchange`,
      `Modules/BuiltInAlgorithms/Sources/CircleSortRecursive.swift`
- [x] CocktailShakerSort — done (native port batch), real category `.exchange` (matches its package
      location here), `Modules/BuiltInAlgorithms/Sources/CocktailShakerSort.swift`
- [x] DualPivotQuickSort — done (native port batch 3), real category `.exchange`, Yaroslavskiy's
      dual-pivot partition (the same algorithm family Java's `Arrays.sort` uses for primitive
      arrays), `Modules/BuiltInAlgorithms/Sources/DualPivotQuickSort.swift`
- [x] LLQuickSort — done (native port batch 4), real category `.exchange`, ArrayV's actual classic
      quicksort (Lomuto partition, last-element pivot, distinct from our `quicksort.js`),
      `Modules/BuiltInAlgorithms/Sources/LLQuickSort.swift`
- [x] OddEvenSort — done (native port batch), real category `.exchange`, distinct `AlgorithmID` from
      the already-shipped `oddevenmergesortiterative`, `Modules/BuiltInAlgorithms/Sources/OddEvenSort.swift`
- [x] OptimizedBubbleSort — done (native port batch 3), real category `.exchange`, the classic
      "shrink by last-swap distance" early-exit optimization,
      `Modules/BuiltInAlgorithms/Sources/OptimizedBubbleSort.swift`
- [x] OptimizedCocktailShakerSort — done (native port batch 4), real category `.exchange`, the same
      "shrink by trailing sorted run" trick as OptimizedBubbleSort but bidirectional (forward and backward
      sweep each pass), `Modules/BuiltInAlgorithms/Sources/OptimizedCocktailShakerSort.swift`
- [x] OptimizedGnomeSort — done (native port batch 4), real category `.exchange`, Wikipedia's "smart
      Gnome Sort" — per-prefix backward-swapping insertion pass, structurally Insertion Sort rather than
      classic Gnome Sort's single forward/backward pointer,
      `Modules/BuiltInAlgorithms/Sources/OptimizedGnomeSort.swift`
- [x] SlowSort — done (native port batch 3), real category `.exchange` (despite the "deliberately
      inefficient recursive sort" family resemblance to the already-shipped `.impractical`
      `StoogeSort` — ArrayV's own `setCategory("Exchange Sorts")` is authoritative), true worst-case
      complexity is `O(n^(log n))`, notably worse than any fixed polynomial,
      `Modules/BuiltInAlgorithms/Sources/SlowSort.swift`
- [x] StoogeSort — done (native port batch), real category `.impractical` (**not** `.exchange`
      despite this package location — ArrayV's own `setCategory("Impractical Sorts")` is
      authoritative), `Modules/BuiltInAlgorithms/Sources/StoogeSort.swift`; content bundle reused
      and repaired from a pre-existing legacy-pipeline `stoogesort.bundle/`, not built from scratch
- [x] SwaplessBubbleSort — done (native port batch 3), real category `.exchange`, a bubble-sort
      pass expressed as a sequence of single-element carried-value writes instead of two-element
      swaps, `Modules/BuiltInAlgorithms/Sources/SwaplessBubbleSort.swift`
- [x] UnoptimizedBubbleSort — done (native port batch 4), real category `.exchange`, the plain
      full-scan-every-pass Bubble Sort with no early-exit optimization,
      `Modules/BuiltInAlgorithms/Sources/UnoptimizedBubbleSort.swift`

#### Not Started

**Trivial:**
- [ ] ExchangeBogoSort — 35 lines (Bogo family — see cluster note above)
- [ ] SnuffleSort — 44 lines
- [ ] SlopeSort — 46 lines

**Easy:**
- [ ] ShoveSort — 52 lines
- [ ] SillySort — 57 lines
- [ ] BubbleBogoSort — 59 lines (Bogo family — see cluster note above)
- [ ] ClassicThreeSmoothCombSort — 60 lines
- [ ] QuadStoogeSort — 61 lines
- [ ] ThreeSmoothCombSortIterative — 66 lines
- [ ] ThreeSmoothCombSortRecursive — 69 lines
- [ ] LRQuickSort — 71 lines
- [ ] OptimizedStoogeSortStudio — 75 lines
- [ ] CircloidSort — 77 lines
- [ ] UnoptimizedCocktailShakerSort — 83 lines
- [ ] StablePermutationSort — 86 lines (Bogo family — see cluster note above)
- [ ] FunSort — 88 lines
- [ ] OptimizedStoogeSort — 91 lines

**Medium:**
- [ ] CompleteGraphSort — 109 lines
- [ ] StableQuickSort — 112 lines
- [ ] ForcedStableQuickSort — 115 lines
- [ ] TableSort — 132 lines

### b. Insertion sorts (`sorts/insert/`, 18)

#### Completed

- [x] InsertionSort — done (Phase 7 batch, easy pick), `insertionsort.js`
- [x] ShellSort — done (Phase 7 batch, medium pick), `shellsort.js`
- [x] BinaryDoubleInsertionSort — done (native port batch 4), real category `.insertion`,
      binary-search-accelerated version of the already-shipped `DoubleInsertionSort`,
      `Modules/BuiltInAlgorithms/Sources/BinaryDoubleInsertionSort.swift`
- [x] BinaryInsertionSort — done (native port batch), real category `.insertion`,
      `Modules/BuiltInAlgorithms/Sources/BinaryInsertionSort.swift`
- [x] DoubleInsertionSort — done (native port batch 3), real category `.insertion`, grows a sorted
      region from the middle outward in both directions at once; **fixed a real out-of-bounds bug
      in ArrayV's own source** (the trailing leftover-element block has no lower-bound guard on its
      backward scan — reverse-sorted input like `[2,1,0]` would throw
      `ArrayIndexOutOfBoundsException` in Java, trap in Swift — added a minimal `pos >= start`
      guard, confirmed via exhaustive/randomized testing this is the only unguarded access that's
      actually reachable), `Modules/BuiltInAlgorithms/Sources/DoubleInsertionSort.swift`
- [x] RecursiveShellSort — done (native port batch), real category `.insertion`,
      `Modules/BuiltInAlgorithms/Sources/RecursiveShellSort.swift`
- [x] SimplifiedLibrarySort — done (native port batch 3), real category `.insertion` ("Library
      Sort"/gapped insertion sort — leaves gaps between sorted elements so future insertions rarely
      need to shift many elements), `Modules/BuiltInAlgorithms/Sources/SimplifiedLibrarySort.swift`

#### Not Started

**Easy:**
- [ ] ClassicTreeSort — 96 lines

**Medium:**
- [ ] PatienceSort — 127 lines
- [ ] SplaySort — 157 lines
- [ ] TreeSort — 168 lines

**Hard:**
- [ ] LibrarySort — 233 lines
- [ ] AATreeSort — 248 lines
- [ ] HanoiSort — 326 lines
- [ ] RedBlackTreeSort — 336 lines
- [ ] AVLTreeSort — 373 lines

**Very Hard:**
- [ ] BlockInsertionSort — 86 own lines, but extends `GrailSorting` (780 lines, Grail cluster —
      see note above); ~866 effective lines

### c. Selection sorts (`sorts/select/`, 25)

#### Completed

- [x] SelectionSort — done (Phase 7 batch, easy pick), `selectionsort.js`
- [x] MaxHeapSort — done (Phase 7 batch, medium pick), `maxheapsort.js`
- [x] BingoSort — done (native port batch 4), real category `.selection`, targets a *value* (not
      an item) per pass so it clears every duplicate occurrence in one sweep,
      `Modules/BuiltInAlgorithms/Sources/BingoSort.swift`
- [x] CycleSort — done (native port batch), real category `.selection`, deterministic single-write
      cycle-following (Cycle Sort's defining minimal-writes property), `Modules/BuiltInAlgorithms/Sources/CycleSort.swift`
- [x] DoubleSelectionSort — done (native port batch 3), real category `.selection`, finds both the
      minimum and maximum of the remaining range in one scan, placing them at both ends per pass;
      exhaustively tested (400K+ trials) the swap-ordering subtlety flagged during porting — no bug
      found, ArrayV's own single guard is good enough,
      `Modules/BuiltInAlgorithms/Sources/DoubleSelectionSort.swift`
- [x] MinHeapSort — done (native port batch), real category `.selection`, mirrors the already-shipped
      `MaxHeapSort`'s sift-down with the child comparison flipped, `Modules/BuiltInAlgorithms/Sources/MinHeapSort.swift`
- [x] StableCycleSort — done (native port batch 4), real category `.selection`, a stable variant of
      the already-shipped `CycleSort` that tracks resolved positions and not-yet-resolved duplicates
      within each cycle's original span to preserve relative order among ties,
      `Modules/BuiltInAlgorithms/Sources/StableCycleSort.swift`
- [x] StableSelectionSort — done (native port batch 3), real category `.selection`, rotates the
      found minimum into place via single-element shifts instead of a direct swap, making it
      genuinely stable unlike plain `SelectionSort`,
      `Modules/BuiltInAlgorithms/Sources/StableSelectionSort.swift`

#### Not Started

`SmoothSort`/`PoplarHeapSort`/`TriangularHeapSort` below are also each a hard prerequisite for a
shuffle (§2's `SMOOTH`/`POPLAR`/`TRI_HEAP`, which literally call these sorts' own heapify step) —
not just their own tier, they unblock a shuffle too.

**Trivial:**
- [ ] BaseNMaxHeapSort — 50 lines

**Easy:**
- [ ] BadSort — 54 lines
- [ ] BinomialSmoothSort — 54 lines
- [ ] BinomialHeapSort — 60 lines
- [ ] FlippedMinHeapSort — 64 lines
- [ ] BottomUpHeapSort — 66 lines
- [ ] LazyHeapSort — 75 lines
- [ ] TernaryHeapSort — 79 lines
- [ ] TriangularHeapSort — 80 lines (also a shuffle prerequisite — see note above)
- [ ] WeakHeapSort — 84 lines
- [ ] AsynchronousSort — 85 lines

**Medium:**
- [ ] OutOfPlaceHeapSort — 102 lines
- [ ] MinMaxHeapSort — 123 lines
- [ ] ClassicTournamentSort — 140 lines
- [ ] TournamentSort — 156 lines

**Hard:**
- [ ] SmoothSort — 205 lines (also a shuffle prerequisite — see note above)
- [ ] PoplarHeapSort — 209 lines (also a shuffle prerequisite — see note above)

### d. Distribution sorts (`sorts/distribute/`, 36)

#### Completed

- [x] BogoSort — done (Phase 7 batch, easy pick), `bogosort.js`; **rewritten in the native port
      batch** from a literal random-shuffle-until-sorted loop to a deterministic lexicographic
      `next_permutation` walk (with `sizeRange` shrunk to `4...7`) — `RecordingEngine` has to
      pre-record the *entire* tape before playback, and an open-ended random walk has no ceiling on
      how large that tape can grow before it happens to land on sorted; the deterministic walk
      keeps the "try every arrangement" spirit with a hard n!-step ceiling instead
- [x] LSDRadixSort — done (Phase 7 batch, medium pick), `lsdradixsort.js`
- [x] BozoSort — done (native port batch), real category `.impractical` (**not** `.distribute`
      despite this package location — ArrayV's own `setCategory("Impractical Sorts")` is
      authoritative); ArrayV's "swap two random indices, check if sorted, repeat" was ported as a
      deterministic single-swap-per-step permutation walk (Heap's algorithm) instead of a literal
      random walk — see the note on `BogoSort` above for why,
      `Modules/BuiltInAlgorithms/Sources/BozoSort.swift`
- [x] CountingSort — done (native port batch), real category `.distribution`,
      `Modules/BuiltInAlgorithms/Sources/CountingSort.swift`
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
- [x] MSDRadixSort — done (native port batch), real category `.distribution`, recursive per-bucket
      variant of the already-shipped `LSDRadixSort`, `Modules/BuiltInAlgorithms/Sources/MSDRadixSort.swift`
- [x] PigeonholeSort — done (native port batch 3), real category `.distribution`; close cousin of
      the already-shipped `CountingSort` but a simpler direct tally-and-re-emit technique with no
      cumulative-sum/backward-scan trick, so — unlike `CountingSort` — it's **not** stable (proven
      by inspecting the recorded tape: zero `.swap` operations, and every write operation is a value
      manufactured from the bucket index alone, never carrying an original position forward),
      `Modules/BuiltInAlgorithms/Sources/PigeonholeSort.swift`
- [x] StaticSort — done (native port batch 4), real category `.distribution`, classify-into-n-buckets
      + cycle-permute + size-dependent insertion/heap-sort finish,
      `Modules/BuiltInAlgorithms/Sources/StaticSort.swift`

#### Not Started

**Trivial:**
- [ ] LessBogoSort — 33 lines (Bogo family — see cluster note above)
- [ ] CocktailBogoSort — 46 lines (Bogo family — see cluster note above)

**Easy:**
- [ ] RandomGuessSort — 55 lines (Bogo family — see cluster note above)
- [ ] OptimizedGuessSort — 59 lines (Bogo family — see cluster note above)
- [ ] SmartGuessSort — 60 lines (Bogo family — see cluster note above)
- [ ] IndexSort — 64 lines
- [ ] SimplisticGravitySort — 64 lines
- [ ] GuessSort — 65 lines (Bogo family — see cluster note above)
- [ ] DeterministicBogoSort — 67 lines (Bogo family — see cluster note above)
- [ ] MedianQuickBogoSort — 67 lines (Bogo family — see cluster note above)
- [ ] SelectionBogoSort — 68 lines (Bogo family — see cluster note above)
- [ ] SmartBogoBogoSort — 72 lines (Bogo family — see cluster note above)
- [ ] ClassicGravitySort — 77 lines
- [ ] QuickBogoSort — 83 lines (Bogo family — see cluster note above)
- [ ] MergeBogoSort — 86 lines (Bogo family — see cluster note above)
- [ ] InPlaceLSDRadixSort — 87 lines

**Medium:**
- [ ] BogoBogoSort — 102 lines (Bogo family — see cluster note above)
- [ ] StacklessBinaryQuickSort — 105 lines
- [ ] RotateLSDRadixSort — 118 lines
- [ ] TimeSort — 120 lines
- [ ] BinaryQuickSortIterative — 43 own + 101 `BinaryQuickSorting` template = 144 lines
- [ ] BinaryQuickSortRecursive — 43 own + 101 `BinaryQuickSorting` template = 144 lines
- [ ] StacklessAmericanFlagSort — 144 lines
- [ ] ShatterSort — 51 own + 102 `ShatterSorting` template = 153 lines
- [ ] SimpleShatterSort — 51 own + 102 `ShatterSorting` template = 153 lines
- [ ] AmericanFlagSort — 155 lines
- [ ] RotateMSDRadixSort — 164 lines

### e. Merge sorts (`sorts/merge/`, 19)

#### Completed

- [x] MergeSort — done (Phase 7 batch, easy pick), `mergesort.js`
- [x] StrandSort — done (Phase 7 batch, medium pick), `strandsort.js`
- [x] BottomUpMergeSort — done (native port batch), real category `.merge`, non-recursive
      doubling-width variant of the already-shipped `MergeSort`, `Modules/BuiltInAlgorithms/Sources/BottomUpMergeSort.swift`
- [x] InPlaceMergeSort — done (native port batch), real category `.merge`; merges via rotation/
      insertion-shift instead of an aux buffer, so despite the name it's `spaceComplexity: O(log n)`
      (recursion stack only) at the cost of a worse `O(n^2)` average/worst merge step — **not**
      stable (positional swaps let equal elements leapfrog each other across recursion levels,
      verified empirically), `Modules/BuiltInAlgorithms/Sources/InPlaceMergeSort.swift`
- [x] RotateMergeSort — done (native port batch 3), real category `.merge`; a genuinely in-place
      merge (unlike the already-shipped `InPlaceMergeSort`'s O(n^2)-degrading insertion-shift) that
      uses binary search to find the split point and block rotation to merge, keeping the ordinary
      O(n log n) merge-sort bound while staying O(1) space,
      `Modules/BuiltInAlgorithms/Sources/RotateMergeSort.swift`
- [x] WeavedMergeSort — done (native port batch 4), real category `.merge`, splits into interleaved/
      strided subsequences instead of contiguous halves before recursing,
      `Modules/BuiltInAlgorithms/Sources/WeavedMergeSort.swift`

#### Not Started

**Easy:**
- [ ] ImprovedInPlaceMergeSort — 92 lines (**not** ported — distinct from plain `InPlaceMergeSort` above)
- [ ] BufferedStoogeSort — 96 lines
- [ ] BlockSwapMergeSort — 98 lines

**Medium:**
- [ ] StacklessRotateMergeSort — 125 lines
- [ ] IterativeTopDownMergeSort — 137 lines (also a same-category prerequisite — see note above)
- [ ] AndreySort — 158 lines
- [ ] PDMergeSort — 183 lines

**Hard:**
- [ ] NewShuffleMergeSort — 203 lines, and directly extends the not-yet-ported
      `IterativeTopDownMergeSort` above rather than just a shared template — port that one first

**Very Hard:**
- [ ] LazyStableSort — 60 own + 780 `GrailSorting` template = 840 lines (Grail cluster — see note above)
- [ ] QuadSort — 51 own + 875 `QuadSorting` template = 926 lines (Quad cluster — see note above)

**Tracked elsewhere:**
- [ ] TwinSort (ArrayV files it under `merge/`'s sibling `hybrid/` package per its template
      location; tracked once, under the hybrid section below — originally picked as this batch's hybrid/medium
      but swapped for IntroSort, see hybrid/ section)

### f. Miscellaneous sorts (`sorts/misc/`, 4)

#### Completed

- [x] PancakeSort — done (Phase 7 batch, easy pick), `pancakesort.js`
- [x] BurntPancakeSort — done (Phase 7 batch, medium pick — **substituted for the originally
      planned `PancakeInsertionSort`**, which needed held-value binary-search "monobound" helpers
      plus a direction-flip state machine; deemed too complex/fragile to port faithfully in this
      batch), `burntpancakesort.js`

#### Not Started

**Medium (by line count — see caveat):**
- [ ] PancakeInsertionSort — 128 lines, deferred (see substitution note above); still worth a real
      port later. Line count alone undersells this one — the held-value binary-search "monobound"
      helpers plus the direction-flip state machine make it feel more like a Hard port in practice.

#### Decision Required

- [~] StalinSort — **not portable as-is**: it deletes out-of-order elements rather than
      repositioning them (a shrinking result, not a permutation). `SortOperation` has no
      remove/shrink case. Would need either a new engine primitive or a "fake it with duplicate
      values" hack — deferred until there's a real reason to add one. Kept in this list rather than
      dropped like the `*Parallel` variants above, but unlikely to actually be implemented — no
      other algorithm currently needs a shrink primitive to justify adding one just for this.

### g. Concurrent sorts (`sorts/concurrent/`, 22)

#### Completed

- [x] BitonicSortIterative — done (Phase 7 batch, easy pick), `bitonicsortiterative.js`
- [x] OddEvenMergeSortIterative — done (Phase 7 batch, medium pick), `oddevenmergesortiterative.js`
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
- [x] MergeExchangeSortIterative — done (native port batch), real category `.concurrent` (Batcher's
      odd-even merge sorting network), `Modules/BuiltInAlgorithms/Sources/MergeExchangeSortIterative.swift`
- [x] OddEvenMergeSortRecursive — done (native port batch 3), real category `.concurrent` (Batcher's
      odd-even merge sorting network); a generalized recursive formulation (credited to a rewrite
      by Piotr Grochowski building on H.W. Lang's original) with real parity-dependent branching
      that handles arbitrary array lengths directly — the highest-risk pick in its wave, verified
      with exhaustive coverage of every size 1 through 40 plus many larger sizes (1146+ cases, zero
      failures), `Modules/BuiltInAlgorithms/Sources/OddEvenMergeSortRecursive.swift`

#### Not Started

**Trivial:**
- [ ] DiamondSortRecursive — 39 lines

**Easy:**
- [ ] BoseNelsonSortRecursive — 55 lines
- [ ] WeaveSortIterative — 63 lines
- [ ] CreaseSort — 65 lines
- [ ] DiamondSortIterative — 67 lines
- [ ] PairwiseMergeSortIterative — 67 lines
- [ ] FoldSort — 77 lines
- [ ] WeaveSortRecursive — 77 lines
- [ ] PairwiseMergeSortRecursive — 80 lines
- [ ] PairwiseSortRecursive — 81 lines
- [ ] PairwiseSortIterative — 88 lines

**Medium:**
- [ ] MatrixSort — 120 lines

### h. Quick sorts (`sorts/quick/`, 2 — the entire category)

#### Completed

- [x] TernaryLLQuickSort — done (Phase 7 batch, easy pick), `ternaryllquicksort.js`
- [x] TernaryLRQuickSort — done (Phase 7 batch, medium pick), `ternarylrquicksort.js`

### i. Hybrid sorts (`sorts/hybrid/`, 41)

Generally the most complex category, and home to most of the Very Hard tier below — but a handful
of small wrapper algorithms over an already-shipped template keep it from being uniformly hard.

#### Completed

- [x] BinaryMergeSort — done (Phase 7 batch, relatively easy pick; a genuine insertion/merge
      hybrid rather than a literal binary-search insertion sort), `binarymergesort.js`
- [x] IntroSort — done (Phase 7 batch, relatively-medium pick — **substituted for the originally
      planned `TwinSort`**, whose real-world implementation turned out to need an initial "twin
      swap" pre-pass plus intricate bottom-up tail-merging with a separate half-size swap buffer
      requiring extensive held-value tracking, far more complex than its 217-line template
      suggested; IntroSort instead reuses building blocks — ternary-quicksort-style strict
      comparisons, 0-indexed heapsort, swap-based insertion sort — already validated elsewhere in
      this same batch), `introsort.js`
- [x] CocktailMergeSort — done (native port batch), real category `.hybrid`; simplifies ArrayV's
      ~950-line galloping-mode `TimSorting` merge phase down to a plain bottom-up pairwise merge
      (same technique as the already-shipped `BottomUpMergeSort`, starting from a run width of
      `minRunLen` instead of 1) — correctness-preserving since galloping mode only changes how many
      comparisons a merge of two known-sorted runs takes, never the resulting order,
      `Modules/BuiltInAlgorithms/Sources/CocktailMergeSort.swift`
- [x] HybridCombSort — done (native port batch 3), real category `.hybrid`; identical to the
      already-shipped `CombSort` except once the shrinking gap drops below a small threshold, it
      abandons the comb-gap technique and finishes with one straight insertion-sort pass — proven
      (analytically and empirically, 40+ trials per boundary size) that this finish never fires
      more than once per sort, `Modules/BuiltInAlgorithms/Sources/HybridCombSort.swift`

#### Not Started

**Easy:**
- [ ] WeaveMergeSort — 97 lines
- [ ] IntroCircleSortIterative — 53 own + 44 `IterativeCircleSorting` template = 97 lines (trivial
      once `CircleSort*`, already shipped, established the pattern)

**Medium:**
- [ ] IntroCircleSortRecursive — 53 own + 48 `CircleSorting` template = 101 lines
- [ ] MergeInsertionSort — 125 lines
- [ ] OptimizedDualPivotQuickSort — 140 lines
- [ ] OptimizedBottomUpMergeSort — 144 lines
- [ ] LaziestSort — 153 lines
- [ ] StacklessDualPivotQuickSort — 156 lines
- [ ] StacklessHybridQuickSort — 163 lines
- [ ] DropMergeSort — 166 lines
- [ ] OptimizedWeaveMergeSort — 172 lines
- [ ] ImprovedBlockSelectionSort — 184 lines

**Hard:**
- [ ] YujisBufferedMergeSort2 — 202 lines
- [ ] MedianMergeSort — 204 lines
- [ ] LazierestSort — 209 lines
- [ ] CircularGrailSort — 209 lines (self-contained despite the name — doesn't actually extend
      `GrailSorting`)
- [ ] FifthMergeSort — 221 lines
- [ ] TwinSort — 57 own + 217 `TwinSorting` template = 274 lines; deferred (see substitution note
      above, and §1e's redirect note) — still worth a real port later
- [ ] BufferPartitionMergeSort — 290 lines
- [ ] OptimizedRotateMergeSort — 305 lines
- [ ] RemiSort — 270 own + 82 `MultiWayMergeSorting` template = 352 lines (MultiWayMerge cluster —
      see note above)
- [ ] EctaSort — 362 lines

**Very Hard:**
- [ ] SqrtSort — 425 lines
- [ ] UnstableGrailSort — 71 own + 355 `UnstableGrailSorting` template = 426 lines
- [ ] FlanSort — 367 own + 82 `MultiWayMergeSorting` template = 449 lines (MultiWayMerge cluster —
      see note above)
- [ ] SynchronousSqrtSort — 190 own + 352 `BlockMergeSorting` template = 542 lines (BlockMerge
      cluster — see note above)
- [ ] PDQBranchlessSort — 46 own + 570 `PDQSorting` template = 616 lines (PDQ cluster — see note above)
- [ ] PDQBranchedSort — 49 own + 570-line `PDQSorting` template = 619 lines (PDQ cluster — see note above)
- [ ] GrailSort — 91 own + 780 `GrailSorting` template = 871 lines (Grail cluster — see note above)
- [ ] OptimizedLazyStableSort — 106 own + 780 `GrailSorting` template = 886 lines (Grail cluster —
      see note above)
- [ ] AdaptiveGrailSort — 915 lines — very complex, but self-contained (extends the bare `Sort`
      base directly, despite the name)
- [ ] TimSort — 45-line composition wrapper + 950 `TimSorting` template = 995 effective lines
- [ ] FluxSort — 202 own + 875 `QuadSorting` template = 1077 lines (Quad cluster — see note above)
- [ ] ChaliceSort — 767 own + 352 `BlockMergeSorting` template = 1119 lines — very complex
      (BlockMerge cluster — see note above)
- [ ] WikiSort — 75-line wrapper + 1068 `WikiSorting` template = 1143 effective lines
- [ ] KotaSort — 33-line wrapper + 1142 `KotaSorting` template = 1175 effective lines — the largest
      template in the whole `sorts/` tree

## 2. Shuffles

Forty-five in ArrayV's `Shuffles.java` enum — no subdirectories, listed flat. v1's original 5 (Phase 6)
doesn't map 1:1 onto ArrayV's list — noted inline where there's a rough equivalent.

As of the native shuffle port batch, a "done" row means a native
`Modules/BuiltInAlgorithms/Sources/<Name>.swift` `ShuffleAlgorithm` conformance registered in
`ShuffleRegistry.shared.builtIns` — not a `.js`/`.manifest.json` pair, the same convention §1's
preamble describes for sorting algorithms. `App/Resources/Shuffles/` is empty until the next
shuffle is being proven out in JS first, same as `Algorithms/`.

### a. Completed

- [x] Random — done (native shuffle port batch; originally Phase 6 as `random.js`), ports v1's
      "Random" (Fisher-Yates) ≈ ArrayV's `RANDOM`, `Modules/BuiltInAlgorithms/Sources/RandomShuffle.swift`
- [x] Ascending — done (native shuffle port batch; originally Phase 6 as `ascending.js`), ports
      v1's "Ascending" (no-op) ≈ ArrayV's `ALREADY`/`SORTED`,
      `Modules/BuiltInAlgorithms/Sources/AscendingShuffle.swift`
- [x] Descending — done (native shuffle port batch; originally Phase 6 as `descending.js`), ports
      v1's "Descending" (reverse) ≈ ArrayV's `REVERSE`,
      `Modules/BuiltInAlgorithms/Sources/DescendingShuffle.swift`
- [x] Shuffled cubic — done (native shuffle port batch; originally Phase 6 as `shuffledcubic.js`),
      v1-original curve shuffle, no ArrayV equivalent,
      `Modules/BuiltInAlgorithms/Sources/ShuffledCubicShuffle.swift`
- [x] Shuffled quintic — done (native shuffle port batch; originally Phase 6 as
      `shuffledquintic.js`), v1-original curve shuffle, no ArrayV equivalent,
      `Modules/BuiltInAlgorithms/Sources/ShuffledQuinticShuffle.swift`

### b. Not Started

Every shuffle lives as one enum constant's method body inside ArrayV's single 1,484-line
`Shuffles.java`, not a separate file — "effective lines" below is that one method's own body
(`~/ArrayV`'s `utils/Shuffles.java`), since there's no shared shuffle template to inherit
complexity from. Shuffles compress into a much narrower range than sorts do: nearly all of them are
Trivial by the same thresholds §1 uses, so within that tier they're listed in ascending order rather
than subdivided further.

`HEAPIFIED`/`SMOOTH`/`POPLAR`/`TRI_HEAP` each call directly into a sort's own heapify step
(`MaxHeapSort.makeHeap`/`SmoothSort.smoothHeapify`/`PoplarHeapSort.poplarHeapify`/
`TriangularHeapSort.triangularHeapify`) rather than reimplementing it — `HEAPIFIED` is portable now
(`MaxHeapSort` already shipped), but `SMOOTH`/`POPLAR`/`TRI_HEAP` are each blocked on their
same-named sort being ported first (see §1c), regardless of how trivial their own body looks.

`QSORT_BAD`/`PDQ_BAD`/`GRAIL_BAD`/`SHUF_MERGE_BAD` sound like they'd need their namesake sort
already ported (to reverse-engineer its worst case), but don't — each embeds its own self-contained
adversarial-input construction, independent of whether `LLQuickSort`(shipped)/`PDQBranchedSort`/
`GrailSort`/`NewShuffleMergeSort` exist as Swift code.

**Trivial:**
- [ ] SMOOTH ("Smoothified") — 12 lines, but blocked on `SmoothSort` (§1c) — see note above
- [ ] POPLAR ("Poplarified") — 12 lines, but blocked on `PoplarHeapSort` (§1c) — see note above
- [ ] PARTIAL_REVERSE ("Half Reversed") — 13 lines
- [ ] QSORT_BAD ("Quicksort Adversary") — 13 lines
- [ ] HEAPIFIED ("Heapified") — 13 lines
- [ ] NAIVE ("Naive Randomly") — 14 lines
- [ ] SHUFFLED_HALF ("Shuffled Half") — 14 lines
- [ ] DOUBLE_LAYERED ("Double Layered") — 14 lines
- [ ] PARTITIONED ("Partitioned") — 15 lines
- [ ] REAL_FINAL_MERGE ("Shuffled Final Merge") — 15 lines
- [ ] ALMOST ("Slight Shuffle") — 16 lines
- [ ] NOISY ("Noisy") — 16 lines
- [ ] SHUFFLED_ODDS ("Scrambled Odds") — 17 lines
- [ ] MOVED_ELEMENT ("Shifted Element") — 19 lines
- [ ] TRI_HEAP ("Triangular Heapified") — 19 lines, but blocked on `TriangularHeapSort` (§1c) — see
      note above
- [ ] FINAL_MERGE ("Final Merge Pass") — 21 lines
- [ ] SAWTOOTH ("Sawtooth") — 21 lines
- [ ] ORGAN ("Pipe Organ") — 21 lines
- [ ] FINAL_RADIX ("Final Radix") — 22 lines
- [ ] LOG_SLOPES ("Logarithmic Slopes") — 22 lines
- [ ] REC_REV ("Recursive Reversal") — 22 lines
- [ ] SHUFFLED_TAIL ("Scrambled Tail") — 23 lines
- [ ] SHUFFLED_HEAD ("Scrambled Head") — 23 lines
- [ ] FINAL_BITONIC ("Final Bitonic Pass") — 23 lines
- [ ] HALF_ROTATION ("Half Rotation") — 24 lines
- [ ] INTERLACED ("Interlaced") — 24 lines
- [ ] GRAY_CODE ("Gray Code Fractal") — 24 lines
- [ ] REAL_FINAL_RADIX ("Real Final Radix") — 28 lines
- [ ] SIERPINSKI ("Sierpinski Triangle") — 31 lines
- [ ] REC_RADIX ("Recursive Final Radix") — 32 lines
- [ ] BLOCK_RANDOMLY ("Randomly w/ Blocks") — 33 lines
- [ ] TRIANGULAR ("Triangular") — 37 lines
- [ ] BST_TRAVERSAL ("BST Traversal") — 37 lines
- [ ] CIRCLE ("First Circle Pass") — 38 lines
- [ ] PAIRWISE ("Final Pairwise Pass") — 39 lines
- [ ] INV_BST ("Inverted BST") — 42 lines

**Easy:**
- [ ] BIT_REVERSE ("Bit Reversal") — 53 lines
- [ ] GRAIL_BAD ("Grailsort Adversary") — 55 lines — see adversary note above
- [ ] SHUF_MERGE_BAD ("Shuffle Merge Adversary") — 63 lines — see adversary note above
- [ ] BLOCK_REVERSE ("Block Reverse") — 68 lines

**Hard:**
- [ ] PDQ_BAD ("PDQ Adversary") — 345 lines, embeds most of pdqsort's own logic — see adversary
      note above

## 3. Visualizers

15 — the full, fixed set; `BuiltInVisualizers` is native-only per §2A.3, no scripting for this axis.

### a. Completed

- [x] BarGraph — done (Phase 4), `BarGraphVisualizer.swift`
- [x] ColorCircle
- [x] HoopStack
- [x] PixelMesh
- [x] Rainbow — done (Phase 5), `RainbowVisualizer.swift`
- [x] ScatterPlot (ArrayV: "Dots") — done (Phase 5), `ScatterPlotVisualizer.swift`
- [x] SineWave
- [x] Spiral
- [x] SpiralDots
- [x] WaveDots

### b. Not Started

All four below share the same real blocker regardless of their own tier: none is portable until
`originalIndices` tracking (§2A.6) exists as a shared engine/visualization feature — that shared
prerequisite, not any one file's size, is the actual gate here.

**Easy:**
- [ ] DisparityBarGraph — 54 lines — needs `originalIndices` (§2A.6 disparity family, see note above)
- [ ] DisparityCircle — 85 lines — needs `originalIndices`, see note above
- [ ] DisparityChords — 92 lines — needs `originalIndices`, see note above; most geometrically
      complex of the circle group despite the modest line count

**Medium:**
- [ ] DisparityDots — 114 lines — needs `originalIndices`, see note above

### c. Decision Required

- [~] CustomImage — deferred per §2A.6 (needs an image-picker UI + per-pixel remap; the
      largest/most novelty-heavy visual, explicitly a Phase 12 stretch goal candidate;
      this is not going to work well since 256 is our upper bound for visuals for
      performance and memory usage)
