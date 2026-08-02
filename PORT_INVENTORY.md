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
- **The Grail cluster**: `BlockInsertionSort` (insert), `GrailSort` (hybrid), `OptimizedLazyStableSort`
  (files under `sorts/hybrid/` but tracked under merge — its own `setCategory("Merge Sorts")` call
  says so, see that entry's own note), and `LazyStableSort` (merge) all extend `GrailSorting`
  (780 lines). **Status: done, all 4 shipped** — the "port the template once, then all four
  wrapper algorithms are comparatively small" prediction held up, confirmed genuine (non-decorative)
  reuse for all four by reading every Java source before porting, unlike the `MultiWayMergeSorting`
  cluster's cautionary tale below.
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

- [x] BlockInsertionSort — faithful port, first member of the Grail cluster shipped (see
      `GrailSortingTemplate`, `TEMPLATE_PORT_REFERENCE.md` §6). Doesn't call `commonSort`'s block-
      merge machinery at all — a natural-run-detecting insertion sort built from just
      `mergeWithoutBuffer` plus its own `insert1`/`insert2` shift-based placement for short runs.
      ArrayV's own override of `grailRotate` (`Rotations.holyGriesMills`) turned out functionally
      identical to the shared `rotate` (same block-swap-of-the-smaller-side technique, just with an
      added length-1 fast path) — reused the shared one directly rather than duplicating an
      equivalent override. Real mutations mix `engine.swap` and `engine.setValue`, so the standard
      swap-tape-shadow stability test can't fully observe this one (confirmed: 31/50 spurious
      failures) — verified genuinely stable instead via a from-scratch Python simulation
      threading a parallel original-index array through every swap and write (2,000 trials, zero
      wrong results, zero instability).

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

- [x] BinaryQuickSortIterative — faithful port. Shares `BinaryQuickSortingTemplate` (ported as a
      Swift namespace-of-static-functions, the first "shared template" in this codebase — see
      `TEMPLATE_PORT_REFERENCE.md` §1) with `BinaryQuickSortRecursive`: a bit-based Hoare partition
      driven by an explicit FIFO task queue instead of the call stack. Fuzzed unstable (no
      tie-break in a pure bit partition).
- [x] BinaryQuickSortRecursive — faithful port, same `BinaryQuickSortingTemplate` partition as
      `BinaryQuickSortIterative` above, driven by real recursion instead of a task queue. Fuzzed
      unstable, independently confirmed rather than assumed from its sibling's result.
- [x] ShatterSort — **not a faithful port.** ArrayV's own `ShatterSorting` template buckets by
      `value / num` and finishes each bucket via a `value % num` residue-placement trick — both
      assume the array holds a permutation of `0..<length` (true for every ArrayV array, false
      here: `NativeAlgorithmCorrectnessTests` fuzzes `Int.random(in: 0...1000)` regardless of array
      size). A literal port would compute out-of-range bucket indices and silently drop duplicate
      values via residue collisions. Fixed by bucketing on a range-normalized index
      (`(value-minValue)*shatters/(maxValue-minValue+1)`) and replacing the residue trick with a
      plain insertion-sort finish over each bucket's real size — genuinely just the textbook bucket
      sort definition, not a special ArrayV trick, so this is a return to the standard algorithm
      rather than a loss of fidelity. Validated in Python first (~6,600 trials) before porting, then
      re-confirmed with a dedicated 1,400-trial wide-range + duplicate-heavy fuzz test in the real
      engine. See `TEMPLATE_PORT_REFERENCE.md` §2 for the full writeup. Verified stable by
      construction (bucket index is a deterministic, order-preserving function of value alone) —
      no dedicated swap-tape stability test, since every real mutation is `engine.setValue`
      (bucket flatten), the same structural situation `StableQuickSort` hit.
- [x] SimpleShatterSort — same `ShatterSortingTemplate` fix as `ShatterSort` above, just reached via
      repeated shrinking-granularity bucket passes instead of one pass. Same validation, same
      stable-by-construction reasoning.

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
- [ ] StacklessAmericanFlagSort — 144 lines
- [ ] AmericanFlagSort — 155 lines
- [ ] RotateMSDRadixSort — 164 lines

### e. Merge sorts (`sorts/merge/`, 19)

#### Completed

- [x] TwinSort — faithful port of Igor van den Hoven's adaptive bottom-up merge sort. Really does
      live in ArrayV's `sorts/merge/` package (this doc's own prior "tracked elsewhere, files under
      hybrid/" note was mistaken — confirmed directly from `TwinSort.java`'s own `package
      io.github.arrayv.sorts.merge;` declaration this batch). Shares `TwinSortingTemplate` (see
      `TEMPLATE_PORT_REFERENCE.md` §3) — a run-detection pre-pass (`twinSwap`, reversing strictly
      descending runs) followed by a tail-inward bottom-up merge (`tailMerge`). The densest index
      arithmetic in this template-porting batch; the standard swap-tape-shadow stability test can't
      observe most of `tailMerge`'s moves (pure `engine.setValue`, same limitation
      `StableQuickSort`/`ShatterSortingTemplate` hit), so stability was verified by simulating the
      exact algorithm in Python with a parallel original-index array instead (6,000 randomized
      duplicate-heavy trials, zero instability) — genuinely stable, confirmed rather than assumed.
- [x] LazyStableSort — faithful port, second member of the Grail cluster shipped. One-line wrapper
      calling `GrailSortingTemplate.lazyStableSort` directly — the simple O(n log n) alternate
      path independent of the block-merge machinery (pairwise compare-swap, then doubling
      `mergeWithoutBuffer`). Every real mutation is `engine.swap`, so the standard swap-tape-shadow
      stability test applies directly here (unlike `BlockInsertionSort`/`OptimizedLazyStableSort`
      below) — fuzzed genuinely stable.
- [x] OptimizedLazyStableSort — third member of the Grail cluster shipped. Files under ArrayV's
      `sorts/hybrid/` package but calls `this.setCategory("Merge Sorts")` in its own constructor —
      tracked here under Merge sorts to match that real category string, the same
      package-vs-`setCategory` correction `TwinSort` needed above (this doc's own prior tracking
      had it filed under Hybrid instead). **Genuinely overrides** `grailLazyStableSort` (not just a
      thin wrapper) with a different construction: natural-run-detecting insertion sort over fixed
      16-element chunks, then doubling `mergeWithoutBuffer` (reused from the template unmodified).
      **Real bug found and fixed**: ArrayV's own `insertionSort` reads two elements unconditionally
      before any bounds check; for array lengths not a multiple of 16 the final chunk can be
      exactly 1 element wide (confirmed crash at `n = 17`, a `[16, 17)` tail chunk reading one past
      the valid range) — fixed with a guard, since a single-element range is already trivially
      sorted and needs no comparison at all. Found via a dedicated extra-scrutiny duplicate-heavy
      fuzz test across sizes 16-256 (not just the generic suite's single per-algorithm trial),
      matching the scrutiny this whole batch of dense template ports got throughout. `insertionSort`'s
      shifts use `engine.setValue`, so stability was verified via Python simulation (2,000 trials,
      zero instability) rather than the swap-tape-shadow technique, same as `BlockInsertionSort`.

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

- [ ] QuadSort — 51 own + 875 `QuadSorting` template = 926 lines (Quad cluster — see note above)

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

- [x] UnstableGrailSort — faithful port of Astrelin's classic in-place block-merge sort (the
      unstable variant — no per-block original-stream tracking, see the `GrailSort` entry once
      that lands for the stable version that adds exactly that tracking). `UnstableGrailSortingTemplate`
      (see `TEMPLATE_PORT_REFERENCE.md` §4) is genuinely a pure pass-through for this one
      concrete algorithm — the entire algorithm lives in the template, the wrapper is a one-line
      `commonSort` call. Passed the generic correctness suite (including duplicate-heavy) on the
      first try despite being the densest index arithmetic ported so far in this batch; a dedicated
      stability test at `sizeRange.lowerBound` (16) would have been a false negative (`commonSort`'s
      own `len <= 16` base case is a trivially-stable plain insertion sort that never touches the
      block-merge machinery at all) — tested at size 64 instead, confirming genuinely unstable as
      the name claims (never assumed from the name outright).
- [x] PDQBranchedSort — faithful port of Orson Peters' pattern-defeating quicksort, branch-based
      partition variant. `PDQSortingTemplate` (see `TEMPLATE_PORT_REFERENCE.md` §5) is the
      cleanest reuse case in this whole batch — confirmed by research that neither
      `PDQBranchedSort` nor `PDQBranchlessSort` shadows or reimplements anything, both are pure
      configuration wrappers (a `branchless` flag) around one shared `pdqLoop`. Passed the generic
      correctness suite on the first try. Same `sizeRange.lowerBound`-is-a-trivial-base-case
      pitfall as `UnstableGrailSort` above applies here too (`insertSortThreshold` is 24, above
      this batch's usual 16-element lower bound) — dedicated stability test run at size 64 instead,
      confirming genuinely unstable (no tie-break anywhere in the Hoare-style partition).
- [x] PDQBranchlessSort — same `PDQSortingTemplate` as `PDQBranchedSort` above, using the
      block-quicksort-style branchless partition (Edelkamp & Weiss) instead of the plain
      Hoare-style one — the densest, most index-arithmetic-heavy code in this whole batch of
      template ports (block-scan offset bookkeeping, cyclic vs. swap-based offset application).
      Passed the generic correctness suite on the first try despite that density. Confirmed
      unstable independently of its sibling's result, same size-64 rationale.
- [x] GrailSort — faithful port (in-place mode only — ArrayV exposes a 32-item static buffer and a
      dynamic `sqrt(n)` buffer as user-selectable runtime alternatives; no algorithm in this
      codebase takes a runtime configuration parameter, so in-place is the one shipped, matching
      every other port). Last and largest member of the Grail cluster — the full `commonSort`
      block build/combine machinery (`GrailSortingTemplate`, `TEMPLATE_PORT_REFERENCE.md` §6),
      genuinely reused verbatim (a one-line wrapper). Two simplifications versus ArrayV's own
      template, both because in-place mode makes them provably dead code: ArrayV's own "XBuf"
      method family (only reachable with a real external buffer, which in-place mode never
      supplies) wasn't ported at all, and `buildBlocks` without XBuf turned out textually identical
      to `UnstableGrailSortingTemplate.buildBlocks` — reused rather than re-transcribed. Passed the
      generic correctness suite (including duplicate-heavy) on the first try despite being the
      densest translation in this whole batch. Dedicated stability test run at size 64 (not
      `sizeRange.lowerBound`, same trivial-base-case pitfall as `UnstableGrailSort`) — confirmed
      genuinely stable, the key-array/stream-fragment tracking `combineBlocks` adds over the
      unstable sibling's plain first/last-element comparison earns the name honestly.

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
- [ ] BufferPartitionMergeSort — 290 lines
- [ ] OptimizedRotateMergeSort — 305 lines
- [ ] RemiSort — 270 own + 82 `MultiWayMergeSorting` template = 352 lines (MultiWayMerge cluster —
      see note above)
- [ ] EctaSort — 362 lines

##### Very Hard

- [ ] SqrtSort — 425 lines
- [ ] FlanSort — 367 own + 82 `MultiWayMergeSorting` template = 449 lines (MultiWayMerge cluster —
      see note above)
- [ ] SynchronousSqrtSort — 190 own + 352 `BlockMergeSorting` template = 542 lines (BlockMerge
      cluster — see note above)
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