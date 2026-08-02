Optimized Lazy Stable Sort is a lighter-weight relative of Grail Sort that skips the block-key
buffer machinery entirely. Where Grail Sort spends real effort scanning for distinct values to
build a movement-tracking key region before it ever starts merging, this algorithm dispenses with
all of that: there's no key buffer, no block selection sort, and no marker element to carry through
swaps. It simply chops the array into small fixed-size chunks, gets each chunk into order on its
own, and then relies on repeated merging to combine those chunks into a fully sorted array.

Each 16-element chunk is sorted with a small insertion sort that first checks whether the chunk
already starts as a run: an ascending-or-equal run is left as-is and simply extended as far as it
goes, while a strictly descending run is detected and then reversed in place as a shortcut, since
reversing is cheaper than re-inserting every element one at a time. Whatever's left after that
initial run is folded in with ordinary insertion-sort shifts. Once every chunk is locally sorted,
the algorithm merges them together in passes of doubling size — first pairs of 16-element chunks,
then 32-element runs, then 64, and so on — using the same in-place, rotation-based merge technique
(binary-search-driven rotations with no auxiliary array) that Grail Sort uses for its own merging.

Categorically this is a merge sort: once the small chunks are locally ordered, the rest of the work
is pure doubling merge passes, with no partitioning or comparison-based block reordering involved.
It preserves the relative order of equal elements throughout — the chunk-level insertion sort never
reorders equal elements relative to each other, and the shared rotation-based merge always resolves
ties by keeping the earlier-encountered element first — so it is a genuinely stable sort, a claim
that's been verified elsewhere in this codebase with a from-scratch simulation that runs the same
algorithm shape against a parallel array of original indices and confirms no equal-valued pair ever
crosses out of its original order.
