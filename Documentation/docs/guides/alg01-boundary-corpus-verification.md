# ALG-01 boundary corpus verification

Date: 2026-10-04. `AlgorithmBoundaryCorpusTests` exercises the 196 built-in sorting algorithms
through `RecordingEngine.record(into:)` and compares the entire result with Swift's independent
`sorted()` output. Exact output equality checks both ordering and preservation of the input
multiset. Input seeds derive from each algorithm ID and size, so every failure is reproducible.

For the ordinary sorting algorithms, sizes are drawn from the current default-operation-cap
selectable range: its minimum, the next two sizes, its maximum and the size below it, plus
15/16/17, 31/32/33, and 63/64/65 where those fall within the range. Every chosen size gets a
seeded permutation and duplicate-heavy values. The minimum and maximum also get ascending,
descending, and all-equal values. The default operation cap is 300,000.

The impractical category gets those four input shapes at its minimum selectable size. Its
randomized and combinatorial implementations can take unbounded time at larger sizes, so the
boundary matrix deliberately does not run them at their maximum. `IndexSort` has its own
documented input domain: consecutive-value permutations. It gets seeded permutations with
both positive and negative bases at its selectable boundaries. The generic duplicate input
would violate that algorithm's precondition, so it is not sent to Index Sort.

There were no platform skips. The test ran successfully on both Mac Catalyst and an iPad mini
simulator. The matrix's required lane is Catalyst; the iPad result gives an additional check of
the shared Swift implementation.

| Platform | Result bundle | Result |
| --- | --- | --- |
| Mac Catalyst | `/private/tmp/alg01-boundary-final.xcresult` | 3 tests passed; 0 failed or skipped |
| iPad mini simulator | `/private/tmp/alg01-boundary-ipad-final.xcresult` | 3 tests passed; 0 failed or skipped |
