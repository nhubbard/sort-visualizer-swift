Weave Sort is a [sorting network](https://en.wikipedia.org/wiki/Sorting_network) — a comparator-based
sort whose sequence of compare-and-swap operations is fixed in advance and never depends on the data
being sorted, only on how many elements there are. It has no dedicated Wikipedia article of its own;
it originates as a community-contributed sorting-visualizer network rather than a textbook
algorithm, but it belongs to the same broad family as Batcher's odd-even mergesort and bitonic
networks: constructions whose comparators were designed to be independently evaluable, and
therefore suitable for parallel or pipelined hardware.

This iterative implementation conceptually builds its network over the next power of two at or
above the real array's length — a real array's length is rarely an exact power of two, and every
comparator whose target index would fall past the end of the real array is simply skipped, a common
technique for adapting a fixed-size network construction to arbitrary input sizes. The comparator
schedule itself comes from five nested loops whose index arithmetic doubles and interleaves at each
level, weaving together comparator pairs at growing strides — the "weave" the name refers to.

Like other fixed comparator networks, this one's total comparator count depends only on the
(padded) length of the input, so its best-case, average-case, and worst-case running times are
identical, landing at O(n log²n) — the same asymptotic class as Batcher's own constructions. Every
comparator only ever swaps on a strict "greater than" test, and this particular network never lets
two equal elements cross paths without an intervening comparison establishing their order, so it is
a stable sort.
