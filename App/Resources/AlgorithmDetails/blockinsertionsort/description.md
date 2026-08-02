Block Insertion Sort is a natural-run-aware variant of insertion sort: rather than always
inserting one element at a time, it first scans ahead from its current position to find how far
the array is already ordered. A stretch that's already non-decreasing is taken as-is, while a
strictly decreasing stretch is detected and reversed in place, turning it into a non-decreasing
run too. Either way, the result is a "natural run" — a maximal already-sorted stretch starting
where the scan began.

What happens next depends on how long that run is. A run of a single element is inserted into the
already-sorted prefix with a classic one-at-a-time shift. A run of exactly two elements is
inserted with a small hand-unrolled routine that shifts both elements into place in one pass
instead of scanning the prefix twice. Runs of three or more elements are folded into the sorted
prefix using the same binary-search-and-rotate merge technique used elsewhere in this codebase's
family of in-place merge sorts: it binary-searches for where the run's elements belong relative to
the existing prefix and rotates them into position, without needing any scratch buffer. The scan
then continues from the end of that run to find the next one, repeating until the whole array has
been consumed.

Because runs are merged in using a binary search that always favors the earlier-encountered
elements when values tie, and because the single/pair insertion routines only ever shift elements
strictly greater than the one being placed, Block Insertion Sort preserves the original relative
order of equal elements and is a genuinely stable sort. That claim has been checked in this
repository with a from-scratch simulation that tracks a parallel array of original indices
alongside the values, since this algorithm's move pattern is a mix of shifts, reversals, and
rotations rather than a purely swap-based scheme, making a simpler swap-counting stability check
insufficient on its own.
