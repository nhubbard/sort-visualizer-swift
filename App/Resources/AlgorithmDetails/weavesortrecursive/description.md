The recursive form of Weave Sort — see this codebase's iterative version for the general
background on [sorting networks](https://en.wikipedia.org/wiki/Sorting_network) this algorithm
belongs to. Rather than five nested loops, this construction is built from two mutually recursive
functions. The first, given a range and a stride, compares mirrored pairs walking inward from both
ends of the range and then recurses into its own first and second halves — folding the range onto
itself, much like a halving merge step. The second function recurses into two interleaved
half-length copies of itself at double the stride *before* running the first function over the
whole range — interleaving two half-size sorted structures together at wider spacing and only then
reconciling them, which is the "weave" the algorithm's name describes.

Like its iterative counterpart, this recursive form conceptually builds its network over the next
power of two at or above the real array's length, skipping any comparator whose target index would
fall past the end of the real array — a real array's length is rarely an exact power of two, and
this padding trick is what lets a fixed-size network construction cover arbitrary input sizes. The
two implementations are more alike than their very different code shapes suggest: measuring the
number of comparisons each one performs across a wide range of array sizes shows they use exactly
the same total, at every size tested.

Like other fixed comparator networks, this one's total comparator count depends only on the
(padded) length of the input, so its best-case, average-case, and worst-case running times are
identical, landing at O(n log²n). Every comparator only ever swaps on a strict "greater than" test,
and this network never lets two equal elements cross paths without an intervening comparison
establishing their order, so it is a stable sort.
