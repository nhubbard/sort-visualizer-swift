# Reference fidelity audit

The code samples under `App/Resources/AlgorithmDetails/<id>/` are meant to show the algorithm
implemented by the app's native Swift port, including deliberate deterministic substitutions.
A sorted-output sample test establishes output correctness only; it cannot establish that the
sample follows the same algorithm. This audit therefore compares control flow and data movement
against the app's Swift implementation, then runs larger duplicate-heavy and boundary inputs.

## Verified and corrected

| Algorithm | Swift behavior checked against all ten language samples | Validation |
|---|---|---|
| FlanSort | Ninther pivot, three-way partition, gapped library sort, multiway heap merge, and input-seeded equal-gap choice | Ten sample tests; seeded random arrays at sizes 0–512 for several languages; native deterministic and instability tests |
| RemiSort | Stable table sort, cube-root run sizing, run-head heap, displacement buffer, and block permutation cycles | Ten sample tests; seeded random arrays at sizes 0–512 for several languages; native deterministic and stability tests |
| BogoSort | Finite lexicographic permutation walk and final descending-to-ascending reversal | Ten sample tests after replacing random shuffling |
| BubbleBogoSort | Deterministic adjacent-pair sweeps until a sweep makes no swap | Ten sample tests after replacing random pair selection |
| TimeSort | Explicit stable merge of a scratch copy followed by insertion cleanup | Ten sample tests after replacing shortcuts such as `Arrays.sort` |

## Remaining review

The other reference samples have **not** yet passed a structural fidelity review. In particular,
source scans still find randomness in samples for `BozoSort`, `CocktailBogoSort`,
`ExchangeBogoSort`, `LessBogoSort`, `MedianQuickBogoSort`, `MergeBogoSort`, `QuickBogoSort`,
`RandomGuessSort`, `SelectionBogoSort`, and `SmartBogoBogoSort`; their Swift ports may use finite,
deterministic substitutes. Each needs an algorithm-specific comparison rather than a blanket
translation or a check that both versions happen to sort the displayed input.

Direct inspection confirms that these ten are fidelity defects, not merely suspicious imports:
`BozoSort` uses a finite Heap-permutation walk in Swift instead of random index swaps;
`ExchangeBogoSort` uses an ordered pair scan instead of a random exchange loop;
`CocktailBogoSort`, `LessBogoSort`, `MedianQuickBogoSort`, `QuickBogoSort`, and
`SmartBogoBogoSort` advance permutations within a chosen range; `MergeBogoSort` enumerates
weave choices; `RandomGuessSort` enumerates guesses with a base-`n` counter; and
`SelectionBogoSort` selects a minimum with a deterministic scan. The reference samples
must reproduce each corresponding Swift path, including its stopping condition.

The PDQ samples warrant a separate structural review of branched and branchless partitioning,
pattern detection, partial insertion, and heap fallback. Their current files are substantially
longer than the earlier simplified samples, but line count alone is not proof of fidelity.

A complete audit must inspect every remaining algorithm and each language sample, then run the
sample tests and targeted inputs. The project must not describe the remaining corpus as verified
until that work is done.
