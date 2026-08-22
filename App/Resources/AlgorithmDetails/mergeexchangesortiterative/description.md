*From Wikipedia, the free encyclopedia*

Batcher's Merge-Exchange Sort, also called Batcher's odd-even mergesort, is
a [sorting network](https://en.wikipedia.org/wiki/Sorting_network): a fixed sequence of compare-and-swap operations
between predetermined pairs of positions, applied in the same order regardless of the values being sorted. It was
introduced by Ken Batcher in 1968, alongside the related bitonic mergesort network, and was one of the first known
sorting methods to achieve O(n log^2 n) comparisons using only a data-independent wiring of comparators, which made it
attractive for hardware sorting circuits and parallel machines where every processing element could execute the same
instruction stream at the same time.

The network is built recursively out of an odd-even merge: two already-sorted sequences are merged by separately merging
their even-indexed and odd-indexed elements, then cleaning up the result with a final pass of compare-exchanges between
adjacent pairs. Because every comparator's two positions are fixed in advance, no branching on data values is required
to decide *which* elements to compare next, only whether to swap the pair once compared, which is exactly the "
oblivious" property that makes sorting networks well suited to hardware pipelines, GPUs, and SIMD execution.

The iterative formulation implemented here reproduces the same comparator sequence as the recursive definition, but
generates it directly from a set of integer parameters that step through the network's merge distances and phases,
avoiding explicit recursion. Because the comparator selection is driven by simple bit masks and arithmetic on the
distance between compared positions rather than by splitting the array into power-of-two halves, the same construction
produces a correct network even when the number of elements being sorted is not a power of two.

As with other sorting networks, Batcher's merge-exchange network is not a stable sort, since a comparator may exchange
two elements that started out equal, and it is not adaptive: an already-sorted array and a reverse-sorted array of the
same length are run through exactly the same O(n log^2 n) comparisons.
