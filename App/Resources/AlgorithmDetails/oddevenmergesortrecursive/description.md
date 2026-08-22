*From Wikipedia, the free encyclopedia*

The odd–even mergesort is a [sorting network](https://en.wikipedia.org/wiki/Sorting_network) devised
by [Ken Batcher](https://en.wikipedia.org/wiki/Ken_Batcher). It is a comparison-based algorithm, but unlike a
general-purpose [comparison sort](https://en.wikipedia.org/wiki/Comparison_sort) such
as [Quick Sort](https://en.wikipedia.org/wiki/Quicksort), the sequence of comparisons it performs is fixed in advance
and does not depend on the data being sorted — only on the number of elements, `n`. Every input of a given size is run
through exactly the same wiring of compare-and-swap operations, called comparators, each of which examines a pair of
positions and swaps them if they are out of order. Because the schedule of comparisons is data-independent, many
comparators can be evaluated at the same time, which makes Batcher's network a natural fit for hardware sorting
circuits, [SIMD](https://en.wikipedia.org/wiki/Single_instruction,_multiple_data) instructions, and other parallel
architectures where a fixed, predictable pattern of operations is far more valuable than raw sequential speed.

This **recursive** variant expresses the network directly as it is usually described in the literature: the input is
split into two halves, each half is sorted recursively, and the two sorted halves are then combined with a recursive *
*odd–even merge**. The merge step takes a starting position, a halfway point, the length of the piece being merged, and
a comparison distance that doubles at each level of recursion; it recursively merges the odd-indexed and even-indexed
subsequences of its input before finishing with a single pass of comparators that fixes up the handful of pairs left out
of order by the split. Sorting the two halves and merging them together in this divide-and-conquer fashion mirrors the
structure of [Merge Sort](https://en.wikipedia.org/wiki/Merge_sort), but with a merge step whose comparator wiring is
fixed ahead of time rather than adapting to the data.

This particular formulation, adapted from a page by H.W. Lang and generalized in a later rewrite credited to Piotr
Grochowski, differs from the textbook version of Batcher's network in one important respect: the classic construction
only works cleanly on inputs whose length is a power of two, and non-power-of-two inputs are traditionally handled by
padding the array out to the next power of two with sentinel values. Here, the halfway point, merge length, and starting
offsets used at each level of recursion are instead tracked and adjusted directly — branching on the parity of a couple
of derived quantities at each step — so that the same recursive merge produces a correct sorting network for an array of
*any* length, without ever needing to pad it.

Because it is built from a fixed collection of pairwise comparators rather than adapting to the data, the recursive
odd–even mergesort performs O(log²n) sequential comparison stages regardless of the values being sorted, which is
asymptotically worse per-processor than the O(log n) depth achieved by more specialized parallel sorting networks, but
its appeal lies in the predictability and parallelizability of its comparator schedule rather than in raw efficiency on
a single processor.
