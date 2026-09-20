# Reference fidelity audit

The code samples under `App/Resources/AlgorithmDetails/<id>/` are meant to show the algorithm
implemented by the app's native Swift port, including deliberate deterministic substitutions.
A sorted-output sample test establishes output correctness only; it cannot establish that the
sample follows the same algorithm. This audit compares control flow and data movement against
the app's Swift implementation. Targeted execution remains a separate validation step.

All 169 algorithms outside the 13 Bogo/Bozo-named sorts received a read-only, major-phase and
complexity review of their ten reference sources. Nine non-Bogo algorithms below were
verified and corrected; 15 have confirmed differences listed below; the other 145 have no
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

## Confirmed non-Bogo mismatches (unfixed)

The following findings compare the app's Swift implementation with all ten language samples in
each named reference folder. They are source-inspection findings; the samples have not been
changed as part of this audit.

| Algorithm | App Swift implementation | Reference samples | Impact |
|---|---|---|---|
| DropMergeSort | Uses `PDQSortingTemplate.sortBranched` for the early fallback and the dropped tail | Use a simple three-way quicksort for both paths | Loses PDQSort's worst-case `O(n log n)` bound; reference quicksort can take `O(n²)` |
| MergeInsertionSort | Iterative, in-place block swaps and block search; `O(1)` auxiliary space | Recursive tagged Ford–Johnson construction with a chain, partner map, and pending list | Different data movement and `O(n)` auxiliary storage instead of the app's in-place approach |
| DualPivotQuickSort | Selects pivots near the thirds, adapts the divisor, and insertion-sorts tiny ranges | Selects the endpoint pivots with no adaptive divisor or insertion cutoff | Different partition and base-case behavior; no overall asymptotic difference established |
| OptimizedDualPivotQuickSort | Adaptive divisor and insertion-sort cutoff through 27 elements, plus a pivot-equals pass | No adaptive divisor; insertion cutoff at 24 elements and a different equal-elements pass | Different behavior around the cutoff and duplicate-heavy partitions; no overall asymptotic difference established |
| QuickSort | Fixed left pivot and its own two-pointer partition | Several different partition schemes; JavaScript even chooses a random pivot | Different pivot behavior and comparison/swap sequence; no overall asymptotic difference established |
| BlockInsertionSort | Merges long runs through Grail's iterative binary-search-and-rotate `mergeWithoutBuffer` | Replaces that helper with recursive divide-and-rotate merging | Different merge work sequence and `O(log n)` recursion stack where Swift's helper uses `O(1)` auxiliary stack |
| LazyStableSort | Uses Grail's iterative binary-search-and-rotate merge | All ten references use recursive divide-and-rotate merging | Different merge sequence and `O(log n)` recursion stack instead of Swift's `O(1)` helper stack |
| LaziestSort | Binary-insertion-sorts fixed blocks until fewer than two blocks remain, then sorts the whole remaining suffix before backward merges | All ten references sort every fixed-size block separately before backward merges | Different initial run boundaries and work sequence; no overall asymptotic change established |
| IterativeTopDownMergeSort | Allocates one `n`-element scratch array once and reuses it | All ten references allocate/copy left and right arrays on every merge | Same `O(n)` peak extra space, but `O(n log n)` aggregate allocation rather than Swift's one `O(n)` allocation |
| LRQuickSort | Recurses only into the smaller partition and loops over the larger | All ten references recurse into both partitions | Reference stack can grow to `O(n)` on adversarial input; Swift bounds it to `O(log n)` |
| LSDRadixSort | Stable radix-4 counting passes with an `n`-element output buffer | C, C++, C#, Go, Java, Kotlin, and Swift use radix-10 buckets capped at ten entries each; JavaScript loops once per maximum *value* rather than per digit; Python uses floating-point division for pass termination; Ruby uses ordinary decimal counting passes | Several samples change the work bound or fail for valid larger inputs; JavaScript is `O(n·maxValue)` and also returns a new array |
| MergeSort | Stable left-biased merge with indexed reads and `O(n log n)` work | Python, Go, and JavaScript choose the right run on ties; JavaScript and Ruby remove the first array element repeatedly during merge | Tie-order differs; repeated front removal can add substantial copying, including quadratic work in the Ruby recursive merge |
| SimplifiedLibrarySort | Uses rebalance factor 4, computes an initial spine below 32 elements, and binary-insertion-sorts arrays shorter than 32 | All ten references use factor 2 and a one-element initial spine | Different rebalance schedule and small-input algorithm |
| RotateMSDRadixSort | Splits the zero-digit region with `dist` and iteratively traverses digit buckets | All ten references use a conventional recursive bucket descent after digit sorting | Substantial control-flow difference; no overall asymptotic difference established |
| UnstableGrailSort | Uses an iterative binary-search-and-rotate merge helper during its Grail phases | All ten references replace that helper with recursive divide-and-rotate merging | Different merge sequence and `O(log n)` helper stack instead of Swift's `O(1)` auxiliary stack |

Key source locations: `Modules/BuiltInAlgorithms/Sources/Hybrid/DropMergeSort.swift` and
`App/Resources/AlgorithmDetails/dropmergesort/`; `Hybrid/MergeInsertionSort.swift` and
`mergeinsertionsort/`; `Exchange/DualPivotQuickSort.swift` and `dualpivotquicksort/`;
`Hybrid/OptimizedDualPivotQuickSort.swift` and `optimizeddualpivotquicksort/`;
`Exchange/QuickSort.swift` and `quicksort/`.

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
arrays are needed to validate the 15 findings and look for additional edge-case discrepancies.
In particular, the PDQ samples contain partition, partial-insertion, and heap-fallback machinery;
the Grail samples contain block-building and combining machinery; and the QuadSort samples retain
their parity and merge phases. Presence of those phases and source length alone do not prove
equivalence. The project must not describe the corpus as fully verified until that validation is
complete.
