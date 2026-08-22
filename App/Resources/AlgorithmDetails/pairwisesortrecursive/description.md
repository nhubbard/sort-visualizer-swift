Recursive Pairwise Sort is a [sorting network](https://en.wikipedia.org/wiki/Sorting_network) — a
comparator-based sort whose sequence of compare-and-swap operations is fixed in advance and never
depends on the data being sorted, only on how many elements there are. Despite the similar name, it
is a distinct construction from this codebase's iterative Pairwise Sort rather than a recursive
restatement of the same algorithm — the two were authored independently and produce different
comparator schedules, and, notably, different stability behavior.

The recursion threads an explicit stride ("gap") through itself rather than padding the array to a
power of two: each call does one comparator pass at twice the current gap, starting one gap-width
into its own range, then recurses twice at double the gap value — routing to one of two different
range boundaries depending on whether the current range's element count is even or odd, so that
both recursive calls stay correctly aligned regardless of how the count divides. A closing pass of
comparisons at decreasing power-of-two multiples of the gap reconciles elements that were left out
of alignment by the recursive splits, before the call returns. Every loop bound here is written
directly against the real range boundaries the recursion computes for itself, so no separate
padding step or out-of-range guard is needed.

Like other fixed comparator networks, this one's total comparator count depends only on the length
of the input, so its best-case, average-case, and worst-case running times are identical, landing
at O(n log²n) — measuring the number of comparisons this construction performs across a wide range
of array sizes shows it uses exactly the same total as this codebase's Pairwise Merge Sort
implementations, despite being a structurally distinct construction from either. Every comparator
only ever swaps on a strict "greater than" test, and this particular construction never lets two
equal elements cross paths without an intervening comparison establishing their order, so — unlike
the iterative Pairwise Sort in this codebase — it is a stable sort.
