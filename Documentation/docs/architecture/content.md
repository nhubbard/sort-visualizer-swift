# Content layer

This layer consists of `BuiltInAlgorithms` and `BuiltInVisualizers`. Every type in these modules is
a leaf conformance to a protocol defined in the engine layer. Adding a new algorithm, shuffle, or
visualizer requires one new file plus registration at a few call sites. See
[Adding a sorting algorithm](../guides/adding-an-algorithm.md),
[Adding a shuffle](../guides/adding-a-shuffle.md), and
[Adding a visualizer](../guides/adding-a-visualizer.md) for the exact steps. This page describes
what already exists.

## `BuiltInAlgorithms`

`BuiltInAlgorithms` depends only on `AlgorithmKit`. It ships 167 `SortAlgorithm` conformances and
44 `ShuffleAlgorithm` conformances, organized under `Modules/BuiltInAlgorithms/Sources/` by
`AlgorithmCategory`.

| Category | Count | Contents |
|---|---:|---|
| `Exchange` | 34 | Bubble, comb, gnome, and quicksort variants: algorithms that sort primarily by swapping pairs |
| `Selection` | 25 | Selection sort and its heap variants: binary, ternary, base-N, smooth, weak, poplar, binomial |
| `Distribution` | 21 | Radix (LSD, MSD, in-place, rotate, stackless), counting- and pigeonhole-style sorts, flash sort |
| `Impractical` | 21 | Bogo and Bozo and their composed variants, Stooge, Guess, Hanoi Sort |
| `Concurrent` | 18 | Bitonic, odd-even/pairwise merge, Bose–Nelson: sorting-network algorithms, run sequentially (see below) |
| `Merge` | 17 | Classic and in-place merge sort variants, strand sort, Andrey sort |
| `Insertion` | 16 | Insertion sort and its tree-backed relatives: AA-tree, AVL-tree, red-black-tree, splay-tree, patience, library sort |
| `Hybrid` | 10 | Introsort, Grail sort, PDQ sort (branched and branchless), weave-merge: algorithms that combine strategies |
| `Miscellaneous` | 3 | Pancake sort and its relatives |
| `Quick` | 2 | Ternary-partition quicksort variants |

Six shared `Templates/` base types (`GrailSortingTemplate`, `PDQSortingTemplate`, and four others)
back multiple concrete algorithms each. This mirrors ArrayV's own `sorts/templates/` base classes.
Porting a shared template once reduces the cost of every algorithm that depends on it.

Porting from ArrayV is ongoing. Not every ArrayV algorithm has a Swift counterpart yet. See
[Port status](../reference/port-status.md) for current progress.

### Shuffles are tapes too

Every shuffle in `Shuffles/` (44 total, ranging from naive random shuffles to structured ones like
radix, bitonic, merge, BST-traversal, and Sierpinski-curve shuffles) is a `ShuffleAlgorithm` that
records against the same `RecordingEngine` a sort uses, starting from a sorted identity array. No
separate shuffle engine exists. This is why "watch a fractal shuffle un-scramble the array" works
as a real feature: it is a tape, replayed the same way any sort's tape is replayed.

### No `*Parallel` variants

ArrayV ships `*Parallel` versions of several sorting-network algorithms, including Bitonic and
Odd-Even Merge. This app does not port them. `RecordingEngine`'s tape is a single deterministic
writer. A "parallel" port would re-record the identical compare-and-swap sequence as the
already-shipped sequential version, under a different name. Real thread interleaving has no
meaning in a single-writer model. Porting these variants would add duplicate content, not new
algorithmic behavior.

### Deterministic recording constrains ports

A tape is recorded once and replayed deterministically. An algorithm that relies on open-ended
randomness (`java.util.Random`, an unseeded shuffle-until-sorted loop) cannot be ported literally.
`BogoSort` and its relatives are rewritten as deterministic permutation walks instead. See
`BogoSort.swift`'s doc comment for the technique.

This constraint is also why every ported algorithm must be fuzzed before it's trusted. ArrayV's
name or comment for an algorithm is not proof of correctness. Two examples confirm this:

- `FunSort` (ArrayV's own class) leaves duplicates unsorted on most fuzz runs.
- `StablePermutationSort` claims to be stable but is not, on a large fraction of runs.

Both ship in this app with their measured behavior documented, not the assumption inherited from
ArrayV. See [Adding a sorting algorithm](../guides/adding-an-algorithm.md) for the fuzzing step.

## `BuiltInVisualizers`

`BuiltInVisualizers` depends only on `VisualizationKit`. It ships 15 `Visualizer` conformances,
each a pure function from `VisualizationContext` to `[DrawCommand]`:

`BarGraphVisualizer`, `RainbowVisualizer`, `ScatterPlotVisualizer`, `SineWaveVisualizer`,
`ColorCircleVisualizer`, `SpiralVisualizer`, `SpiralDotsVisualizer`, `WaveDotsVisualizer`,
`PixelMeshVisualizer`, `HoopStackVisualizer`, `HanoiTowersVisualizer`, and the four-member
Disparity family (`DisparityBarGraphVisualizer`, `DisparityCircleVisualizer`,
`DisparityChordsVisualizer`, `DisparityDotsVisualizer`).

The Disparity family maps each value's displacement from its sorted position onto color, angle, or
shape, using a `sin(π(value - index)/n)`-style formula. It does not use the value directly. Two
design questions about this family were resolved by reading ArrayV's source:

- **Required data.** The Disparity visualizers need only each value's current index to compute
  displacement. An earlier design draft assumed they would need a new `originalIndices` field,
  tracking each value's home index as a first-class engine concept. ArrayV's own formula uses only
  the array's ordinary current index, which every `Visualizer` already receives. These visualizers
  shipped as ordinary conformances, with no new engine features.
- **Hanoi Towers is not a literal ArrayV port.** No `SortOperation` carries peg semantics, so a
  literal replay of `HanoiSort`'s peg-moving logic would violate the rule that a visualizer cannot
  know how the algorithm works. `HanoiTowersVisualizer` instead splits the array into visual towers
  by current index, not by value. This makes it an ordinary, index-derived `Visualizer`
  conformance. The tower-lift-and-carry animation lives in the Metal renderer
  (`MetalHanoiTowersRenderer`; see [Features & app target](features.md)), driven by the same raw
  `SortOperation`s every other visualizer's renderer receives.

### The one style that hasn't been built

ArrayV includes a 15th style, CustomImage, which remaps a user-supplied image per array
permutation. This app has not built it. Its UI and remapping cost were judged disproportionate to
its value relative to the other 15 styles. See
[History](../architecture/history.md#whats-still-open).

## Categories come from ArrayV's own declarations

`AlgorithmCategory` mirrors ArrayV's `Sort.setCategory(...)` calls exactly, including cases where
that call disagrees with ArrayV's file layout. `HanoiSort` lives under ArrayV's `sorts/insert/`
directory, but its own `setCategory("Impractical Sorts")` call assigns it to Impractical. This app
files it as `.impractical` to match the declaration, not the directory.
