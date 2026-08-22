*From Wikipedia, the free encyclopedia*

Diamond Sort is a [comparator network](https://en.wikipedia.org/wiki/Sorting_network) in the same
broad family as Batcher's Bitonic Sort and the Bose-Nelson sort: algorithms whose sequence of
compare-and-swap operations is fixed in advance rather than adapted to the data being sorted, and
which were originally designed with the expectation that their comparisons could run independently
of one another, and therefore in parallel.

This iterative construction conceptually pads the real array length up to the next power of two and
sweeps through doubling block sizes. Within each block, the width of the comparator window ramps up
from nothing toward a quarter of the block size and back down again — tracing the diamond shape the
algorithm is named for — comparing adjacent pairs across that widening-then-narrowing span as the
block size itself doubles at each level. A final half-size pass after the main sweep repeats the
same widen-then-narrow shape one level down, to finish reconciling the last block boundary. Every
comparator bound here is clamped directly against the real array length, so this construction sorts
correctly at any input size, not just at exact powers of two.

That general correctness comes at a real cost, though: despite living among sorting networks that
scale far more efficiently, measuring the number of comparisons this particular construction
performs shows it lands almost exactly on n(n-1)/2 — the same comparator count an ordinary quadratic
sort would use, and dramatically more than the n log²n or better a well-designed comparator network
typically achieves. Its best, average, and worst-case running times are identical regardless, since
the comparator schedule depends only on the array's length. Every comparator only ever swaps on a
strict "greater than" test, and this construction never lets two equal elements cross paths without
an intervening comparison establishing their order, so it is a stable sort.
