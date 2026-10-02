Iterative Bitonic Sort is a [sorting network](https://en.wikipedia.org/wiki/Sorting_network)
construction based on [Ken Batcher](https://en.wikipedia.org/wiki/Ken_Batcher)'s bitonic merge.
It forms successively larger bitonic sequences by comparing pairs whose indices differ at one
binary position. The outer loop doubles the sequence length; an inner loop halves the comparison
distance at each stage. Comparator directions alternate between ascending and descending until
the final stage produces ascending order. Comparisons whose partner index lies beyond the actual
array length are omitted, allowing the iterative construction to handle lengths that are not
powers of two.

The comparator schedule depends only on the array length, so the network performs the same
comparisons for every input order. For *n* elements it uses O(*n* × log²(*n*)) comparators and has
O(log²(*n*)) parallel depth. Its compare-and-swap stages can move equal elements past each other,
so the sort is not stable.
