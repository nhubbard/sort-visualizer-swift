Crease Sort is a [sorting network](https://en.wikipedia.org/wiki/Sorting_network) — a comparator-based
sort whose sequence of compare-and-swap operations is fixed in advance and never depends on the
data being sorted, only on how many elements there are. It has no dedicated Wikipedia article of its
own; it originates as a community-contributed sorting-visualizer network rather than a textbook
algorithm, but it belongs to the same broad family as Batcher's odd-even mergesort and bitonic
networks, whose comparators were designed to be independently evaluable and therefore suitable for
parallel or pipelined hardware.

Its comparator pattern reads like a sheet of paper being folded down repeatedly — the "crease" the
name refers to. Each pass first compares every adjacent pair of elements, then a second pass
compares pairs separated by a shrinking distance, starting from the largest power of two under the
array's length and halving down toward some floor value. Once that floor itself reaches zero, the
whole thing has run its course. Unlike several sibling networks in this codebase, every loop bound
here is written directly in terms of the real array length rather than a padded power of two, so no
separate out-of-range guard is needed on any individual comparator.

Like other fixed comparator networks, this one's total comparator count depends only on the length
of the input, so its best-case, average-case, and worst-case running times are identical, landing
at O(n log²n) — measuring the number of comparisons this network performs across a wide range of
array sizes shows it uses exactly the same total as this codebase's Weave Sort networks, despite a
very different loop structure. Every comparator only ever swaps on a strict "greater than" test,
and this network never lets two equal elements cross paths without an intervening comparison
establishing their order, so it is a stable sort.
