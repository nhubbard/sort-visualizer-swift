# ALG-02 stability and variant metadata verification

Date: 2026-10-04. The corpus checks all algorithms currently marked stable at their minimum
selectable size and at 32 and 64 elements when selectable, with three deterministic,
duplicate-heavy seeds. For algorithms whose recordings change the main array only by swaps, the
test replays those swaps over an array of original positions. It then checks that each group of
equal final values retains increasing original positions. For value-moving algorithms, a second
test encodes `(key, original position)` into each value and uses the recorder's debug comparison
key override to compare keys alone. Four swap-only algorithms with their own value-and-position
tie handling are checked by the swap-tape method because the comparison override changes their
normal control flow.

The identity audit found eleven incorrect `stable: true` declarations. Bubble Sort used the
recorder's default `>=` comparison and swapped equal neighbors. Its comparison now uses strict
`>`, matching the stable Bubble Sort behavior described in the app. Nine sorting networks and
swap-based merges, plus Patience Sort, remain behaviorally unstable and
now declare `stable: false`. Nine network/merge descriptions that claimed stability were
corrected and the packed algorithm-details archive was source-verified. The corpus pins a
repeatable equal-key reordering witness for each corrected unstable declaration.

The corrected algorithms are Recursive Bose-Nelson Sort, Buffered Stooge Sort, Crease Sort,
Fold Sort, both Pairwise Merge Sort variants, Recursive Pairwise Sort, both Weave Sort variants,
and Patience Sort. The iterative/recursive variant metadata check covers 11 paired variants
and asserts matching category, selectable range, and stability declaration. AlgorithmKit's
size-step and operation-estimate tests also passed. These tests provide empirical evidence for
the sampled input shapes; they do not constitute a proof of stability for every possible input.

| Target | Result bundle | Result |
| --- | --- | --- |
| BuiltInAlgorithms, Catalyst | `/private/tmp/alg02-catalyst-final.xcresult` | 8 tests passed; 0 failed or skipped |
| BuiltInAlgorithms, iPad mini simulator | `/private/tmp/alg02-ipad-final.xcresult` | 7 tests passed; 0 failed or skipped |
| AlgorithmKit, Catalyst | `/private/tmp/alg02-metadata.xcresult` | 6 tests passed; 0 failed or skipped |

The algorithm-detail corpus audit checked 196 algorithms and 197 descriptions. The pack step
verified the archive's outer header, SHA-256 digest, zstd checksum, and source manifest. The
engine access audit checked 248 Swift sources with zero direct reads.
