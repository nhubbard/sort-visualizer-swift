*From Wikipedia, the free encyclopedia*

The Bose-Nelson algorithm, described by R. C. Bose and R. J. Nelson in 1962, is a classic recursive
construction for building a [sorting network](https://en.wikipedia.org/wiki/Sorting_network) — a
comparator-based sort whose sequence of compare-and-swap operations is fixed in advance and never
depends on the data being sorted, only on how many elements there are. This recursive form is the
algorithm's original, direct presentation: split the input in half, recursively build a network for
each half, and merge the two already-sorted halves together with a further recursive sequence of
comparators.

The merge step is where the real recursive structure lives. Merging two runs of arbitrary lengths
bottoms out at three small cases — a run of one element against another single element, one against
two, or two against one — each resolved with a couple of direct comparisons. Any larger pair of runs
is split again: the first run in half, and the second run at a point chosen based on whether the
first run's length is even or odd, so that the two halves stay balanced regardless of how the
lengths divide. Three recursive sub-merges follow, two covering disjoint halves and a third
re-merging across the boundary between them, weaving the whole thing back together into one sorted
run. Because this merge operates on run lengths and starting offsets directly, it works on any
input size without needing to pad the array up to a power of two first — a contrast with several
other sorting-network constructions, which only cover sizes that are an exact power of two unless
extended with a padding trick.

The Bose-Nelson network is more economical than some of its better-known contemporaries: it
requires on the order of n^1.585 comparators (that unusual exponent is log base 2 of 3, falling out
of the three-way recursive merge above), fewer than the roughly n log²n comparators a Batcher-style
network needs for large inputs, though still more than an asymptotically optimal O(n log n) network
would use. Like other fixed comparator networks, its comparator count depends only on the input's
length, so best-case, average-case, and worst-case running time are identical. Every comparator
only ever swaps on a strict "greater than" test, and unlike some other networks in this family, no
two equal elements are ever left to cross paths indirectly through a shared comparator partner, so
this construction is a stable sort.
