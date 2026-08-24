# Port status

Porting content from [ArrayV](https://github.com/gouravkhunger/ArrayV) is ongoing, with no fixed
end date. This page tracks what's shipped and what remains, and the team keeps it current as
algorithms move from one list to the other. See
[Adding a sorting algorithm](../guides/adding-an-algorithm.md) for the porting process.

## Sorting algorithms

ArrayV defines 208 sorting-algorithm classes across nine categories, plus 21 shared template base
classes ported only through their concrete subclasses.

Twelve of the 208 classes are `*Parallel` variants (Bitonic, Odd-Even Merge, and similar
sorting-network algorithms with a parallel counterpart). The project declines these outright,
rather than tracking them as pending. `RecordingEngine`'s tape is a single deterministic writer, so
a "parallel" port would re-record the identical compare-and-swap sequence as the already-shipped
sequential version, under a different name. Real thread interleaving has no meaning in a
single-writer model. Porting these variants would add duplicate content, not new algorithmic
behavior.

This leaves 196 candidates. 170 are shipped. 26 remain, in one category.

### By category

| Category | Status |
|---|---|
| Exchange (41) | All ported |
| Insertion (18) | All ported |
| Selection (25) | All ported |
| Distribution (36) | All ported |
| Merge (19) | All ported |
| Miscellaneous (4) | All ported |
| Concurrent (22) | All ported |
| Hybrid (41) | 15 ported, 26 remaining |

### Remaining work

The list groups remaining work by how complex the ArrayV Java source is, not by category or
alphabetical order. The line count cited per algorithm is "effective lines": the algorithm's own
class, plus, when it extends a shared template rather than the bare base class, that template's
line count. Inherited template logic is real complexity a port must understand and translate.

**Medium** (101–200 effective lines):

- `MergeInsertionSort`, `OptimizedDualPivotQuickSort`,
  `OptimizedBottomUpMergeSort`, `LaziestSort`, `StacklessDualPivotQuickSort`,
  `StacklessHybridQuickSort`, `DropMergeSort`, `OptimizedWeaveMergeSort`,
  `ImprovedBlockSelectionSort`.

**Hard** (201–400 effective lines, or a same-category prerequisite not yet ported):

- `YujisBufferedMergeSort2`, `MedianMergeSort`, `LazierestSort`, `CircularGrailSort`
  (self-contained despite the name; it does not extend `GrailSorting`), `FifthMergeSort`,
  `BufferPartitionMergeSort`, `OptimizedRotateMergeSort`, `RemiSort` (270 own plus 82 for the
  shared `MultiWayMergeSorting` template), `EctaSort`.

**Very Hard** (400+ effective lines, or extending one of the largest remaining templates):

- `SqrtSort`, `FlanSort` (367 own plus 82 for `MultiWayMergeSorting`), `SynchronousSqrtSort` (190
  own plus 352 for `BlockMergeSorting`), `AdaptiveGrailSort` (915 lines, self-contained despite the
  name), `TimSort` (a 45-line wrapper over the 950-line `TimSorting` template), `ChaliceSort` (767
  own plus 352 for `BlockMergeSorting`), `WikiSort` (a 75-line wrapper over the 1068-line
  `WikiSorting` template), and `KotaSort` (a 33-line wrapper over the 1142-line `KotaSorting`
  template, the largest template in ArrayV's `sorts/` tree).

Several of these algorithms share one large template or one unported prerequisite. Porting the
shared piece once reduces the cost of every sibling in that cluster:

- **MultiWayMerge cluster**: `FlanSort` and `RemiSort` (both Hybrid) both extend
  `MultiWayMergeSorting` (82 lines). This template is much smaller than `QuadSorting`, so this pair
  costs less than the members' own size alone suggests.
- **BlockMerge cluster**: `ChaliceSort` and `SynchronousSqrtSort` (both Hybrid) both extend
  `BlockMergeSorting` (352 lines).

The rest of the Hybrid backlog is deferred as a policy, not scheduled piecemeal, earmarked for a
future batch covering the largest remaining sorts across every category.

### Completed clusters

Two large clusters were tackled as a unit and have shipped in full, validating the
port-the-shared-template-once strategy:

- **Bogo/Guess family**, spread across the Exchange and Distribution categories: all extend
  `BogoSorting` (261 lines). The real blocker for this cluster was never the template. It was the
  same problem `BogoSort` and `BozoSort` solved first: `RecordingEngine` cannot pre-record an
  open-ended random search, so each variant needed a deterministic permutation walk instead (see
  `BogoSort.swift`'s doc comment). Applying this established pattern to each variant, rather than
  re-deriving it, shipped the whole family, including `BogoBogoSort` — the last holdout — which
  turned out tractable by composing two already-proven techniques at each recursion depth
  independently.
- **Grail cluster**: `BlockInsertionSort` (Insertion), `GrailSort` (Hybrid),
  `OptimizedLazyStableSort` and `LazyStableSort` (both Merge, even though the first's Java source
  file lives under ArrayV's `sorts/hybrid/`, since its `setCategory("Merge Sorts")` call places it
  in Merge) all extend `GrailSorting` (780 lines). All four shipped, confirming genuine,
  non-decorative reuse of the shared template across all four ports.
- **PDQ cluster**: `PDQBranchedSort` and `PDQBranchlessSort` (both Hybrid) both extend
  `PDQSorting` (570 lines). Both shipped.
- **Circle cluster**: `IntroCircleSortIterative` and `IntroCircleSortRecursive` (both Hybrid)
  extend the small `IterativeCircleSorting`/`CircleSorting` templates (44/48 lines). Both shipped,
  each inlining its own routine rather than sharing a dedicated template file — small enough not to
  be worth extracting, matching how the already-shipped `CircleSort` family itself is structured.
- **Quad cluster**: `QuadSort` (Merge) shipped, along with the `QuadSorting` template (875 lines)
  it extends — Igor van den Hoven's actual quadsort, dense and hand-unrolled, a multi-day
  undertaking on its own. `FluxSort` (Hybrid), the cluster's other member, has since shipped too;
  porting it only needed its own 202 lines built on top of the already-shipped, already-tested
  template plus one new template entry point (`sort(_:using:start:length:)`, ArrayV's
  `quadSortSwap`) for reusing a caller-supplied scratch buffer across recursive partition calls.

A retired scratch document, previously kept at `Documentation/TEMPLATE_PORT_REFERENCE.md`, carried
hand-transcribed Java-to-pseudocode notes for six templates: `BinaryQuickSortingTemplate`,
`ShatterSortingTemplate`, `TwinSortingTemplate`, `UnstableGrailSortingTemplate`,
`PDQSortingTemplate`, and `GrailSortingTemplate`. Every algorithm built on those six templates has
shipped, so the team retired that document instead of carrying it forward. It does not cover any of
the templates listed above as still open (`MultiWayMergeSorting`, `BlockMergeSorting`,
`TimSorting`, `WikiSorting`, `KotaSorting`) — nor `QuadSorting`, which has since shipped without
one. A similar transcription pass is worth doing again before tackling the remaining open
templates, given how dense and index-arithmetic-heavy this style of algorithm tends to be.

## Shuffles

ArrayV's `Shuffles.java` enum lists 45 cases, flat with no subdirectories. This app ships 46
shuffles today, all complete. This project's original set of 5 shuffles did not map one-to-one
onto ArrayV's list when shuffles were first ported, which accounts for the difference.

Notes on specific shuffles:

- `HeapifiedShuffle`, `SmoothifiedShuffle`, `PoplarifiedShuffle`, and `TriangularHeapifiedShuffle`
  each call directly into a sort's own heapify step (`MaxHeapSort.makeHeap`,
  `SmoothSort.smoothHeapify`, `PoplarHeapSort.poplarHeapify`, `TriangularHeapSort.
  triangularHeapify`) rather than reimplementing it. Three of these four sorts needed a small
  refactor first, extracting a dedicated public heapify-only entry point, before their shuffle
  could call it directly.
- `QuicksortAdversaryShuffle`, `PDQAdversaryShuffle`, `GrailsortAdversaryShuffle`, and
  `ShuffleMergeAdversaryShuffle` sound like they need their namesake sort already ported, to
  reverse-engineer its worst case. They do not. Each embeds its own self-contained adversarial-input
  construction, independent of whether the named sort exists as Swift code.

## Visualizers

This app ships 15 visualizers. 14 are direct ports of ArrayV styles. The 15th,
`HanoiTowersVisualizer`, is this project's own addition: a dramatized, index-based layout inspired
by the idea of Hanoi towers, not a literal port of any specific ArrayV visualizer (see
[Content layer](../architecture/content.md#the-one-style-that-hasnt-been-built)). ArrayV's own
CustomImage style — a user-supplied image remapped per array permutation — is the one ArrayV style
with no counterpart here. See [History](../architecture/history.md#whats-still-open).
