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
  per variant rather than re-deriving it. **Status: done, all members shipped** — `BogoBogoSort`
  (the last holdout, previously deferred over its nested-recursion-depth shuffle problem) turned out
  tractable by composing two already-proven techniques (`BogoSort`'s `next_permutation` walk for
  its outer reshuffle loop, `SmartBogoBogoSort`'s candidate-swap technique for its inner tail-fixup
  loop) independently at each recursion depth — see `BogoBogoSort.swift`'s own doc comment. Several
  members turned out to already be deterministic in ArrayV itself (no rewrite needed, just a
  faithful port); one (`SelectionBogoSort`) turned out to only need a single deterministic sweep,
  cheap enough to ship with a much larger `sizeRange` than a typical bogo variant.
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
- `IntroCircleSortIterative`/`IntroCircleSortRecursive` (hybrid) extend the already-small
  `IterativeCircleSorting`/`CircleSorting` templates (44/48 lines) — trivial once `CircleSort*` (already shipped) established the pattern.

### a. Exchange sorts (`sorts/exchange/`, 41)

All exchange sorts have been ported.

### b. Insertion sorts (`sorts/insert/`, 18)

All insertion sorts have been ported.

### c. Selection sorts (`sorts/select/`, 25)

All selection sorts have been ported.

### d. Distribution sorts (`sorts/distribute/`, 36)

All distribution sorts have been ported.

### e. Merge sorts (`sorts/merge/`, 19)

All merge sorts have been ported except `QuadSort`.

#### Not Started

##### Very Hard

- [ ] QuadSort — 51 own + 875 `QuadSorting` template = 926 lines (Quad cluster — see note above).
      Deliberately deferred (2026-08-05): the `QuadSorting` template is 875 lines of real, dense
      production code (Igor van den Hoven's actual quadsort — hand-unrolled 2-8 element sorting
      networks, parity-merge routines, a dedicated quad-merge/tail-merge pipeline), a genuinely
      multi-day undertaking rather than a "looks scary but resolves cleanly" case. Earmarked for a
      future batch covering all the largest remaining sorts across categories, alongside `FluxSort`
      (hybrid, the Quad cluster's other member).

### f. Miscellaneous sorts (`sorts/misc/`, 4)

All miscellaneous sorts have been ported.

### g. Concurrent sorts (`sorts/concurrent/`, 22)

All concurrent sorts have been ported.

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

All 45 shuffles have been ported.

`HEAPIFIED`/`SMOOTH`/`POPLAR`/`TRI_HEAP` each call directly into a sort's own heapify step
(`MaxHeapSort.makeHeap`/`SmoothSort.smoothHeapify`/`PoplarHeapSort.poplarHeapify`/
`TriangularHeapSort.triangularHeapify`) rather than reimplementing it — the latter three needed a
small refactor of their host sort (extracting a dedicated public heapify-only entry point) before
their shuffle could call it directly, the same shape `SmoothSort`/`PoplarHeapSort` already had.

`QSORT_BAD`/`PDQ_BAD`/`GRAIL_BAD`/`SHUF_MERGE_BAD` sound like they'd need their namesake sort
already ported (to reverse-engineer its worst case), but don't — each embeds its own self-contained
adversarial-input construction, independent of whether `LLQuickSort`/`PDQBranchedSort`/`GrailSort`/
`NewShuffleMergeSort` exist as Swift code.