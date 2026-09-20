# Reference fidelity audit

The code samples under `App/Resources/AlgorithmDetails/<id>/` are meant to show the algorithm
implemented by the app's native Swift port, including deliberate deterministic substitutions.
A sorted-output sample test establishes output correctness only; it cannot establish that the
sample follows the same algorithm. This audit compares control flow and data movement against
the app's Swift implementation. Targeted execution remains a separate validation step.

All 169 algorithms outside the 13 Bogo/Bozo-named sorts received a read-only, major-phase and
complexity review of their ten reference sources. Twenty-two non-Bogo algorithms below were
verified and corrected; 2 have confirmed differences listed below; the other 145 have no
confirmed substitution from this structural review. Among those 145, exact equivalence remains
uncertain for the large GrailSort, PDQBranchedSort, PDQBranchlessSort, QuadSort, and
NewShuffleMergeSort implementations. The source review did not run all samples on boundary or
duplicate-heavy inputs and is not a proof of line-by-line equivalence.

## Verified and corrected

| Algorithm | Swift behavior checked against all ten language samples | Validation |
|---|---|---|
| FlanSort | Ninther pivot, three-way partition, gapped library sort, multiway heap merge, and input-seeded equal-gap choice | Ten sample tests; seeded random arrays at sizes 0–512 for several languages; native deterministic and instability tests |
| RemiSort | Stable table sort, cube-root run sizing, run-head heap, displacement buffer, and block permutation cycles | Ten sample tests; seeded random arrays at sizes 0–512 for several languages; native deterministic and stability tests |
| BogoSort | Finite lexicographic permutation walk and final descending-to-ascending reversal | Ten sample tests after replacing random shuffling |
| BubbleBogoSort | Deterministic adjacent-pair sweeps until a sweep makes no swap | Ten sample tests after replacing random pair selection |
| TimeSort | Explicit stable merge of a scratch copy followed by insertion cleanup | Ten sample tests after replacing shortcuts such as `Arrays.sort` |
| PancakeSort | Skips flips when the maximum is already at the end of the active prefix | Ten sample tests; corrected the skip condition in every reference language |
| ShellSort | Fixed gap sequence with swaps between elements one gap apart | Ten sample tests; 448 targeted Python cases across boundaries, sorted, reversed, and duplicate-heavy inputs |
| StablePermutationSort | Linear adjacent-value scan at each permutation leaf | Ten sample tests; 84 targeted Python cases including duplicate-heavy inputs |
| BitonicSortIterative | Network stages through `k < 2*n`, parity `m`, and guarded partner indices | Ten sample tests; 6,500 seeded Python cases across lengths 0–64 |
| DiamondSortRecursive | Pads the network length to a power of two and skips virtual elements | Ten sample tests; 6,500 seeded Python cases and 36 non-power-of-two cases each in C, C++, and JavaScript |
| RotateLSDRadixSort | Base-4 digit passes with in-place digit merges | Ten sample tests; 1,300 seeded Python cases around radix boundaries |
| LaziestSort | Sorts fixed blocks only while at least two remain, then sorts the whole suffix before backward merges | Ten sample tests; 1,008 boundary, sorted, reversed, and duplicate-heavy Python cases |
| SimplifiedLibrarySort | Rebalance factor 4, initial spine below 32, and binary insertion for smaller arrays | Ten sample tests; 840 targeted Python cases and 35 threshold cases each in C, C++, and JavaScript |
| LRQuickSort | Recurses into the smaller partition and loops over the larger one | Ten sample tests; 330 random Python cases and a 4,096-item middle-pivot killer with six peak recursive calls |
| MergeSort | Stable left-biased merge with indexed reads and linear merge work | Ten sample tests; tagged duplicate stability checks in Python, JavaScript, and Ruby |
| IterativeTopDownMergeSort | Reuses one `n`-element scratch buffer across proportional-slice merges | Ten sample tests; 3,870 tagged stable Python cases across lengths 0–128 |
| QuickSort | Fixed left pivot and two-pointer partition | Ten sample tests; 5,654 sorted, reversed, and duplicate-heavy Python cases across lengths 0–256 |
| LSDRadixSort | Stable radix-4 counting passes with reusable `n`-element output | Ten sample tests; 1,200 Python cases and larger-bucket cases in C, C++, and JavaScript through 256 items |
| DualPivotQuickSort | Thirds-based pivot candidates, adaptive divisor, and insertion sort on tiny ranges | Ten sample tests; 6,400 Python cases through 512 items |
| OptimizedDualPivotQuickSort | Adaptive thirds pivots, insertion sort for lengths below 27, and the late pivot-equals pass | Ten sample tests; 7,600 Python and 3,400 JavaScript cases through 512 items |
| BlockInsertionSort | Grail iterative binary-search-and-rotate merge and the app’s empty-input guard | Ten sample tests; 1,600 Python cases through 256 items |
| LazyStableSort | Grail iterative binary-search-and-rotate merge | Ten sample tests; 1,600 Python cases and 1,600 tagged stability cases through 256 items |
| UnstableGrailSort | Grail iterative binary-search-and-rotate merge | Ten sample tests; 1,600 Python cases through 256 items |
| RotateMSDRadixSort | Digit sort followed by the app’s stackless `i`/`b`/`q`/`m` bucket traversal | Ten sample tests; 3,400 Python and 1,300 JavaScript cases through 512 items |

## Confirmed non-Bogo mismatches (unfixed)

The following findings compare the app's Swift implementation with all ten language samples in
each named reference folder. They are source-inspection findings; the samples have not been
changed as part of this audit.

| Algorithm | App Swift implementation | Reference samples | Impact |
|---|---|---|---|
| DropMergeSort | Uses `PDQSortingTemplate.sortBranched` for the early fallback and the dropped tail | Use a simple three-way quicksort for both paths | Loses PDQSort's worst-case `O(n log n)` bound; reference quicksort can take `O(n²)` |
| MergeInsertionSort | Iterative, in-place block swaps and block search; `O(1)` auxiliary space | Recursive tagged Ford–Johnson construction with a chain, partner map, and pending list | Different data movement and `O(n)` auxiliary storage instead of the app's in-place approach |

Key source locations: `Modules/BuiltInAlgorithms/Sources/Hybrid/DropMergeSort.swift` and
`App/Resources/AlgorithmDetails/dropmergesort/`; `Hybrid/MergeInsertionSort.swift` and
`mergeinsertionsort/`.

## Expected Bogo-family divergence

Source scans find randomness in samples for `BozoSort`, `CocktailBogoSort`,
`ExchangeBogoSort`, `LessBogoSort`, `MedianQuickBogoSort`, `MergeBogoSort`, `QuickBogoSort`,
`RandomGuessSort`, `SelectionBogoSort`, and `SmartBogoBogoSort`; their Swift ports may use finite,
deterministic substitutes. The app needs a finite recording process, so this divergence is
expected. The decision to align these examples with the Swift behavior or label their difference
is deferred; it is outside the current non-Bogo audit.

Direct inspection confirms the divergence is real, not merely suspicious imports:
`BozoSort` uses a finite Heap-permutation walk in Swift instead of random index swaps;
`ExchangeBogoSort` uses an ordered pair scan instead of a random exchange loop;
`CocktailBogoSort`, `LessBogoSort`, `MedianQuickBogoSort`, `QuickBogoSort`, and
`SmartBogoBogoSort` advance permutations within a chosen range; `MergeBogoSort` enumerates
weave choices; `RandomGuessSort` enumerates guesses with a base-`n` counter; and
`SelectionBogoSort` selects a minimum with a deterministic scan.

## Remaining validation

The five large implementations named above need detailed control-flow comparison across every
language. Targeted sample runs, duplicate-heavy inputs, non-power-of-two lengths, and larger
arrays are needed to validate the 8 findings and look for additional edge-case discrepancies.
In particular, the PDQ samples contain partition, partial-insertion, and heap-fallback machinery;
the Grail samples contain block-building and combining machinery; and the QuadSort samples retain
their parity and merge phases. Presence of those phases and source length alone do not prove
equivalence. The project must not describe the corpus as fully verified until that validation is
complete.
