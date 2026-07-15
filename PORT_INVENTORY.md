# Port Inventory

Standing tracking doc for Phase 7 of `IMPLEMENTATION_PLAN.md` ("porting ArrayV content at scale"),
which is explicitly open-ended with no fixed exit condition. Source of truth for the full list:
`~/ArrayV` (Java), inventoried directly rather than guessed — the file names, categories, and line
counts below come from reading that repo, not from `ARCHITECTURE_V2.md`'s illustrative examples.

**Status key:** `[x]` done and shipped · `[ ]` not started · `[~]` needs a decision before porting
(noted inline)

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

- **The Bogo/Guess family, spread across exchange + distribute below** all extend `BogoSorting`
  (261 lines), but the *real* blocker isn't that template — it's the same "`RecordingEngine` can't
  pre-record an open-ended random search" problem `BogoSort`/`BozoSort` already solved by
  rewriting as a deterministic permutation walk (see
  `Modules/BuiltInAlgorithms/Sources/BogoSort.swift`'s doc comment) — apply the established pattern
  per variant rather than re-deriving it. **Status as of the 2026-07-15 batch: done except
  `BogoBogoSort`** (deferred — see its own note under §1d, "Not Started"). Several members turned
  out to already be deterministic in ArrayV itself (no rewrite needed, just a faithful port); one
  (`SelectionBogoSort`) turned out to only need a single deterministic sweep, cheap enough to ship
  with a much larger `sizeRange` than a typical bogo variant.
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

- [x] BubbleBogoSort (Bogo family) — deterministic substitute, not a literal port: repeatedly
      sweeps every adjacent pair left-to-right and swaps whenever inverted (exactly bubble sort's
      own mechanic) instead of ArrayV's random-adjacent-pair-pick, since every accepted swap
      strictly fixes one inversion regardless of which pair gets picked when. Genuinely O(n^2) now
      (not factorial), so shipped with a much larger `sizeRange` (16...256) than a typical bogo
      variant, matching `ExchangeBogoSort`'s own precedent.
- [x] StablePermutationSort (Bogo family) — already fully deterministic in ArrayV (no `randInt` in
      the Java source) — a faithful port, not a redesign. Heap's-algorithm walk over an index array
      with a *rotation* (not a swap) as the step-to-next-arrangement move. **Despite the name, it's
      not actually stable** — fuzzed empirically after a careful, faithful translation still
      reordered ties in ~40% of duplicate-heavy trials; shipped as `stable: false`, the same "name
      promises more than the algorithm delivers" surprise `FunSort` already has documented above.

#### Not Started

##### Easy

- [ ] ShoveSort — 52 lines
- [ ] SillySort — 57 lines
- [ ] QuadStoogeSort — 61 lines (ArrayV's own `setCategory` call for this one is actually
      `"Impractical Sorts"`, not `"Exchange Sorts"`, despite living in `sorts/exchange/` — port as
      `.impractical`, not `.exchange`, per `AlgorithmCategory`'s "match ArrayV's `setCategory` call,
      not its package directory" rule. Also `setUnreasonablySlow(true)`/limit 2048.)
- [ ] OptimizedStoogeSortStudio — 75 lines
- [ ] OptimizedStoogeSort — 91 lines

##### Decision required

- [~] FunSort — 88 lines. **Do not port as a literal translation.** ArrayV's own algorithm
      (`Reads.compareIndices(array, pos, i, 0, false) != 0`, which resolves to a plain value
      comparison per `Reads.compareIndices`'s implementation) treats "the binary search landed on
      *some* index holding an equal value" as sufficient to mark index `i` permanently settled, even
      when that index isn't `i`'s own eventual home. On duplicate-heavy input this repeatedly leaves
      the array genuinely **unsorted** (not merely unstable) once the loop moves past `i` and never
      revisits it — confirmed against a faithful line-for-line Python re-implementation of the Java
      source itself (i.e. not a porting bug): 1,680/2,000 randomized duplicate-heavy trials (values
      drawn from a small range, sizes 2–24) ended with an unsorted final array, e.g. `[3, 0, 5, 3, 1,
      0] -> [0, 1, 3, 3, 5, 0]`. 2,000/2,000 trials with all-distinct values passed, so the defect is
      specific to duplicates. This codebase's own `NativeAlgorithmCorrectnessTests` mandates that
      *every* registered algorithm sorts duplicate-heavy input correctly with no exceptions, so a
      literal port cannot be registered as-is — either find/design a corrected convergence check
      before porting (which would no longer be a faithful translation) or skip this one.

##### Medium

- [ ] CompleteGraphSort — 109 lines
- [ ] StableQuickSort — 112 lines
- [ ] ForcedStableQuickSort — 115 lines
- [ ] TableSort — 132 lines

### b. Insertion sorts (`sorts/insert/`, 18)

#### Completed

Move algorithms here when you finish them.

#### Not Started

##### Medium

- [ ] PatienceSort — 127 lines
- [ ] SplaySort — 157 lines
- [ ] TreeSort — 168 lines

##### Hard

- [ ] LibrarySort — 233 lines
- [ ] AATreeSort — 248 lines
- [ ] HanoiSort — 326 lines
- [ ] RedBlackTreeSort — 336 lines
- [ ] AVLTreeSort — 373 lines

##### Very Hard

- [ ] BlockInsertionSort — 86 own lines, but extends `GrailSorting` (780 lines, Grail cluster —
      see note above); ~866 effective lines

### c. Selection sorts (`sorts/select/`, 25)

#### Completed

Move algorithms here when you finish them.

#### Not Started

`SmoothSort`/`PoplarHeapSort` below are also each a hard prerequisite for a shuffle (§2's
`SMOOTH`/`POPLAR`, which literally call these sorts' own heapify step) — not just their own tier,
they unblock a shuffle too. (`TriangularHeapSort`, the third sort in this cluster, is now shipped —
see Completed above.)

##### Easy

- [ ] BinomialSmoothSort — 54 lines
- [ ] BinomialHeapSort — 60 lines
- [ ] FlippedMinHeapSort — 64 lines
- [ ] BottomUpHeapSort — 66 lines
- [ ] LazyHeapSort — 75 lines
- [ ] TernaryHeapSort — 79 lines
- [ ] WeakHeapSort — 84 lines
- [ ] AsynchronousSort — 85 lines

##### Medium

- [ ] OutOfPlaceHeapSort — 102 lines
- [ ] MinMaxHeapSort — 123 lines
- [ ] ClassicTournamentSort — 140 lines
- [ ] TournamentSort — 156 lines

##### Hard

- [ ] SmoothSort — 205 lines (also a shuffle prerequisite — see note above)
- [ ] PoplarHeapSort — 209 lines (also a shuffle prerequisite — see note above)

### d. Distribution sorts (`sorts/distribute/`, 36)

#### Completed

- [x] RandomGuessSort (Bogo family) — deterministic substitute: borrows `OptimizedGuessSort`'s own
      odometer technique (ArrayV's own later, already-deterministic descendant of this algorithm)
      instead of re-deriving a different one, since it's the same `n^n` guess space either way.
- [x] OptimizedGuessSort (Bogo family) — already fully deterministic in ArrayV, faithful port. A
      base-`n` odometer over `n^n` index guesses (a bigger space than the `n!` permutation-walk
      family), validated at its own upper-bound size (8) to confirm practical runtime.
- [x] SmartGuessSort (Bogo family) — already fully deterministic in ArrayV, faithful port. Same
      odometer as `OptimizedGuessSort`, but skip-ahead-optimized (only resets the prefix before the
      first failing pair instead of restarting from position 0) — confirmed empirically dramatically
      cheaper in practice, hence the much larger `sizeRange` (19) than the plain odometer siblings.
- [x] GuessSort (Bogo family) — already fully deterministic in ArrayV, faithful port. Same odometer,
      but validates via an O(n^2) brute-force pair count instead of an adjacent-pair scan — the
      slowest member of the family per state checked, which set its own smaller `sizeRange` (7).
- [x] DeterministicBogoSort (Bogo family) — already fully deterministic in ArrayV (true to its
      name), faithful port. Heap's algorithm via forward recursion, the same technique `BozoSort`
      already ported just structured depth-up instead of k-down.
- [x] MedianQuickBogoSort (Bogo family) — deterministic substitute: sub-range lexicographic
      permutation walk (same technique `LessBogoSort`/`CocktailBogoSort` already use) checking a
      median-count split instead of full sortedness, in place of ArrayV's random reshuffle-until-split.
- [x] SelectionBogoSort (Bogo family) — deterministic substitute, and the cheapest rewrite in the
      whole cluster: the range's true minimum is always reachable in exactly one deterministic sweep
      (literally selection sort's own inner loop), so no repeated-retry technique is needed at all.
      Shipped with a much larger `sizeRange` (16...256) than a typical bogo variant, matching
      `ExchangeBogoSort`'s own precedent for "the deterministic substitute made this genuinely cheap."
- [x] SmartBogoBogoSort (Bogo family) — deterministic substitute: sub-range permutation walk of the
      whole range, retried after each recursive re-sort of the prefix, in place of ArrayV's random
      whole-range reshuffle.
- [x] QuickBogoSort (Bogo family) — deterministic substitute: sub-range permutation walk checking a
      partition around a tracked pivot *position* (updated through both the swap AND the reversal
      each permutation step performs, mirroring ArrayV's own per-swap pivot bookkeeping) in place of
      the random Fisher–Yates-with-pivot-tracking reshuffle.
- [x] MergeBogoSort (Bogo family) — deterministic substitute, and the one member needing a genuinely
      new primitive: after the two recursive halves are already sorted, walks every bitmask with the
      correct popcount (in place of ArrayV's random weave-until-sorted) to find the correct
      interleaving. Uses a real aux array for the pre-weave snapshot (matching `MergeSort.swift`'s
      own convention) instead of ArrayV's trick of reusing the main array itself as mask scratch space.

#### Not Started

##### Easy

- [ ] IndexSort — 64 lines
- [ ] SimplisticGravitySort — 64 lines
- [ ] ClassicGravitySort — 77 lines
- [ ] InPlaceLSDRadixSort — 87 lines

##### Medium

- [~] BogoBogoSort — 102 lines (Bogo family). **Deferred, not skipped** — unlike the other 12
      members of this cluster (all shipped this batch), its own "is it sorted" check is itself
      defined recursively via nested bogo-sorted copies at every recursion depth (the classic
      super-exponential joke algorithm — ArrayV itself caps it at size 5). A faithful deterministic
      port needs permutation walks nested at every recursion level, each with its own aux-array
      bookkeeping — real, disproportionate design work for one algorithm, the same kind of
      effort-tier surprise `FunSort`/`PancakeInsertionSort` already got flagged for. Worth a real
      pass later; not worth blocking or rushing the rest of the cluster for.
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

Move algorithms here when you finish them.

#### Not Started

##### Easy

- [ ] ImprovedInPlaceMergeSort — 92 lines (**not** ported — distinct from plain `InPlaceMergeSort` above)
- [ ] BufferedStoogeSort — 96 lines

##### Medium

- [ ] StacklessRotateMergeSort — 125 lines
- [ ] IterativeTopDownMergeSort — 137 lines (also a same-category prerequisite — see note above)
- [ ] AndreySort — 158 lines
- [ ] PDMergeSort — 183 lines

##### Hard

- [ ] NewShuffleMergeSort — 203 lines, and directly extends the not-yet-ported
      `IterativeTopDownMergeSort` above rather than just a shared template — port that one first

##### Very Hard

- [ ] LazyStableSort — 60 own + 780 `GrailSorting` template = 840 lines (Grail cluster — see note above)
- [ ] QuadSort — 51 own + 875 `QuadSorting` template = 926 lines (Quad cluster — see note above)

##### Tracked elsewhere

- [ ] TwinSort (ArrayV files it under `merge/`'s sibling `hybrid/` package per its template
      location; tracked once, under the hybrid section below — originally picked as this batch's hybrid/medium
      but swapped for IntroSort, see hybrid/ section)

### f. Miscellaneous sorts (`sorts/misc/`, 4)

#### Completed

Move algorithms here when you finish them.

#### Not Started

##### Medium (by line count — see caveat)

- [ ] PancakeInsertionSort — 128 lines, deferred (see substitution note above); still worth a real
      port later. Line count alone undersells this one — the held-value binary-search "monobound"
      helpers plus the direction-flip state machine make it feel more like a Hard port in practice.

### g. Concurrent sorts (`sorts/concurrent/`, 22)

#### Completed

Move algorithms here when you finish them.

#### Not Started

##### Easy

- [ ] BoseNelsonSortRecursive — 55 lines
- [ ] WeaveSortIterative — 63 lines
- [ ] CreaseSort — 65 lines
- [ ] DiamondSortIterative — 67 lines
- [ ] PairwiseMergeSortIterative — 67 lines
- [ ] FoldSort — 77 lines
- [ ] WeaveSortRecursive — 77 lines
- [ ] PairwiseMergeSortRecursive — 80 lines
- [ ] PairwiseSortRecursive — 81 lines

##### Medium

- [ ] MatrixSort — 120 lines

### h. Hybrid sorts (`sorts/hybrid/`, 41)

#### Completed

Move algorithms here when you finish them.

#### Not Started

##### Medium

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

##### Hard

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

##### Very Hard

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

### a. Completed

#### Completed

Move shuffles here when you finish them.

### b. Not Started

Every shuffle lives as one enum constant's method body inside ArrayV's single 1,484-line
`Shuffles.java`, not a separate file — "effective lines" below is that one method's own body
(`~/ArrayV`'s `utils/Shuffles.java`), since there's no shared shuffle template to inherit
complexity from. Shuffles compress into a much narrower range than sorts do: nearly all of them are
Trivial by the same thresholds §1 uses, so within that tier they're listed in ascending order rather
than subdivided further.

`HEAPIFIED`/`SMOOTH`/`POPLAR`/`TRI_HEAP` each call directly into a sort's own heapify step
(`MaxHeapSort.makeHeap`/`SmoothSort.smoothHeapify`/`PoplarHeapSort.poplarHeapify`/
`TriangularHeapSort.triangularHeapify`) rather than reimplementing it — `HEAPIFIED` shipped by reusing
`MaxHeapSort`'s own heapify step directly; `SMOOTH`/`POPLAR` remain blocked on their same-named sort
being ported first (see §1c), regardless of how trivial their own body looks. `TRI_HEAP` is now
unblocked — `TriangularHeapSort` shipped this batch — but still needs its own port, duplicating
`TriangularHeapSort.swift`'s `triangularRoot`/`siftDown`/heapify logic inline the way
`HeapifiedShuffle.swift` duplicates `MaxHeapSort`'s (see that sort's own doc comment).

`QSORT_BAD`/`PDQ_BAD`/`GRAIL_BAD`/`SHUF_MERGE_BAD` sound like they'd need their namesake sort
already ported (to reverse-engineer its worst case), but don't — each embeds its own self-contained
adversarial-input construction, independent of whether `LLQuickSort`(shipped)/`PDQBranchedSort`/
`GrailSort`/`NewShuffleMergeSort` exist as Swift code. `QSORT_BAD` shipped this batch; `PDQ_BAD`/
`GRAIL_BAD`/`SHUF_MERGE_BAD` remain (Easy/Hard tier, out of this batch's Trivial-only scope).

#### Trivial

- [ ] SMOOTH ("Smoothified") — 12 lines, but blocked on `SmoothSort` (§1c) — see note above
- [ ] POPLAR ("Poplarified") — 12 lines, but blocked on `PoplarHeapSort` (§1c) — see note above
- [ ] TRI_HEAP ("Triangular Heapified") — 19 lines, no longer blocked — `TriangularHeapSort` (§1c)
      shipped this batch — see note above

#### Easy

- [ ] BIT_REVERSE ("Bit Reversal") — 53 lines
- [ ] GRAIL_BAD ("Grailsort Adversary") — 55 lines — see adversary note above
- [ ] SHUF_MERGE_BAD ("Shuffle Merge Adversary") — 63 lines — see adversary note above
- [ ] BLOCK_REVERSE ("Block Reverse") — 68 lines

#### Hard

- [ ] PDQ_BAD ("PDQ Adversary") — 345 lines, embeds most of pdqsort's own logic — see adversary
      note above