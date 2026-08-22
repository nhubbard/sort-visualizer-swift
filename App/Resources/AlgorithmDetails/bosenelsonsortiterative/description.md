*From Wikipedia, the free encyclopedia*

A [sorting network](https://en.wikipedia.org/wiki/Sorting_network) is a comparator-based sorting algorithm whose
sequence of compare-and-swap operations is fixed in advance and does not depend on the input data — the same wires fire
in the same order no matter what values are being sorted. This data-independence is what made sorting networks
attractive for hardware implementation and parallel execution: every comparator can, in principle, be evaluated at a
predetermined time regardless of the outcome of any other comparator, since the *positions* being compared never change,
only the *values* found there.

The Bose-Nelson algorithm, described by R. C. Bose and R. J. Nelson in 1962, is a classic recursive construction for
building such a network: it splits an input in half, recursively builds networks to sort each half, and then merges the
two sorted halves together with a further sequence of comparators. Together with Ken Batcher's later odd-even mergesort
and bitonic mergesort networks, it is one of the best-known methods for generating sorting networks of low comparator
count, and it predates Batcher's constructions by several years.

This iterative variant unrolls the recursive comparator structure into three nested loops, generating the same fixed
comparator sequence without recursion. Because a real array's length is rarely an exact power of two, the network is
conceptually built over the next power of two at or above the array's length, and every comparator whose target index
would fall past the end of the real array is simply skipped — a common technique for adapting a fixed-size network
construction to arbitrary input sizes.

Like other sorting networks, Bose-Nelson sort is not a comparison sort in the adaptive sense: its comparator count
depends only on the (padded) length of the input, so its best, average, and worst-case running times are identical. It
is not a stable sort, since comparators may swap equal elements past one another during the merge step.
