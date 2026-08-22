Pairwise Merge Sort is a [sorting network](https://en.wikipedia.org/wiki/Sorting_network) — a
comparator-based sort whose sequence of compare-and-swap operations is fixed in advance and never
depends on the data being sorted, only on how many elements there are. It has no dedicated
Wikipedia article of its own under this exact name; it belongs to the same broad family as
Batcher's odd-even mergesort and the (differently-constructed) pairwise sorting network published
by Ian Parberry, all built from comparators designed to be independently evaluable and therefore
suitable for parallel or pipelined hardware.

This iterative construction conceptually pads the real array length up to the next power of two,
with every comparator bounds-checked against the real length so any comparison that would touch
padding is simply skipped. It runs in two passes: a first pass performs a single odd-even sweep at
half the padded size, comparing elements that far apart; a second pass repeats a doubling-merge
shape, combining pairs of already-sorted blocks two at a time as the block size grows from two up
toward the full padded length.

Like other fixed comparator networks, this one's total comparator count depends only on the
(padded) length of the input, so its best-case, average-case, and worst-case running times are
identical, landing at O(n log²n) — measuring the number of comparisons this network performs across
a wide range of array sizes shows it uses exactly the same total as this codebase's recursive
Pairwise Merge Sort and Pairwise Sort implementations, despite each using a different loop or
recursion shape to get there. Every comparator only ever swaps on a strict "greater than" test, and
this network never lets two equal elements cross paths without an intervening comparison
establishing their order, so it is a stable sort.
