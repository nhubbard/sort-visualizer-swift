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

- [x] CompleteGraphSort — faithful port of the sorting network (recursive `split` compare-swapping
      across a doubling stride). `compSwap` only swaps on a strict `>`, never a tie, but fuzzing
      shows that alone doesn't preserve relative order — 50/50 randomized duplicate-heavy trials
      found reordering, confirming this is not a stable sort (ArrayV itself makes no stability
      claim for it).
- [x] StableQuickSort — faithful port of Rodney Shaghoulian's O(n)-extra-space partition: a single
      left-to-right scan appends each element to a "less than pivot" or "not less than pivot" list
      in encounter order, then writes `leftList + pivot + rightList` back. No in-place swaps at all
      (every array mutation is a plain write), so the standard swap-tape-shadow stability fuzz test
      other algorithms in this batch use doesn't apply — genuinely stable by construction instead
      (a single order-preserving scan into order-preserving lists cannot reorder ties), verified by
      reading the mechanism rather than by fuzzing swaps that never happen. No dedicated stability
      test, matching the existing `CountingSort`/`SimplifiedLibrarySort`/`CycleSort` precedent for
      write-only algorithms.
- [x] ForcedStableQuickSort — faithful port of the median-of-three Hoare quicksort forced stable via
      an external `key` array (`Writes.createExternalArray` mirrored as an aux handle + shadow
      `[Int]`, the same pattern `MergeSort`/`SimplifiedLibrarySort` already use) swapped in lockstep
      with every real swap, tie-breaking on `key`'s original order. Fuzzed genuinely stable — the
      whole point of the "forced" in its name holds up.
- [x] TableSort — same median-of-three Hoare quicksort shape as `ForcedStableQuickSort`, but
      quicksorts an index permutation `table` instead of the real array, applying the finished
      permutation at the end. **Port decision**: ArrayV's own final-apply step is write-only (a
      held temp value walked around each cycle via `Writes.write`), which would emit zero `.swap`
      operations on the real array in a literal port — making the swap-tape-shadow stability fuzz
      test blind to this algorithm (the shadow would never move, trivially "passing" regardless of
      ground truth). Ported the apply step as a swap-based cycle-follow instead (`swap(a1,a2),
      swap(a2,a3), ..., swap(a(k-1),ak)` for a cycle `(a1->a2->...->ak)`), which produces an
      identical final array to the write+temp version — verified by hand before porting — in
      exchange for a working stability test. Fuzzed genuinely stable.
- [x] FunSort — 88 lines. Previously "Decision required" (skipped in an earlier batch as
      not-portable-as-a-faithful-translation) — revisited on request to fix rather than skip, and
      to make it stable while at it. ArrayV's
      own convergence check (`Reads.compareIndices(array, pos, i, ...) != 0`, a plain *value*
      comparison) treats "the binary search landed on *some* index holding an equal value" as
      sufficient to mark index `i` permanently settled, even when that index isn't `i`'s own
      eventual home — on duplicate-heavy input this left the array genuinely **unsorted** (not
      merely unstable) ~87% of the time (confirmed via a faithful Python re-implementation: 1,749/
      2,000 randomized trials, sizes 2–24, values drawn from a small range). A **second, previously
      latent** defect surfaced while designing the fix: ArrayV's own swap rule has a silent no-op
      case (`pos == i + 1` triggers neither of its two swap conditions) that never surfaced because
      the value-equality bug always terminated first — fixing defect #1 alone would have exposed
      defect #2 as a genuine infinite loop. **The fix**: compare elements by a tie-free composite
      key of `(value, originalIndex)` instead of value alone (a `key` array in the same style as
      `ForcedStableQuickSort`/`TableSort`'s external index arrays above), so "the search finds `i`
      itself" becomes a well-defined fixed point instead of a value-equality shortcut, and the
      `pos == i + 1` gap gets an explicit forced swap instead of a no-op. Tie-breaking by original
      index also makes the sort genuinely stable as a side effect, for free. Validated by fuzzing
      the exact design in Python first (~7,700 randomized trials — duplicate-heavy and all-distinct,
      sizes 2–256, plus adversarial already-sorted/reverse-sorted/all-equal inputs — zero wrong
      results, zero non-termination, zero instability) before porting to Swift, then re-confirmed
      with a dedicated 1,400-trial duplicate-heavy fuzz test and a stability fuzz test in the real
      engine.

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

Move algorithms here when you finish them.

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