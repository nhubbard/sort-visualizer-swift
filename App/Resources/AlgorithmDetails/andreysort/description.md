Andrey Sort, devised by Andrey Astrelin, is one of the earliest widely-circulated demonstrations
that an in-place merge sort could run in `O(n log n)` time using only `O(1)` extra memory — no
heap-allocated scratch array, no linked-list tricks, just clever reuse of the array's own trailing
space as a rotating buffer. For small ranges (below length 12) it simply falls back to an ordinary
selection sort, repeatedly finding the minimum of the unsorted remainder and swapping it to the
front. The interesting behavior only shows up above that threshold.

For larger ranges, the algorithm picks a block size, roughly the square root of the range's
length, rounded to a nearby power of two. It then builds up sorted runs of doubling size within a
portion of the array whose length is an exact multiple of that block size, using a technique
usually called a "backward merge": two already-sorted runs are merged not from their fronts into
a separate destination, but from their *tails*, moving right to left into a small trailing region
that briefly serves as scratch space. Because a run's own vacated tail becomes the buffer for the
next run, there's never a moment where the algorithm needs more working memory than the input
already provides. Once several same-sized blocks exist, a second technique takes over: the
algorithm selection-sorts the blocks by comparing only their leading elements, physically swapping
whole blocks into position, and backward-merges each selected block into the growing sorted
region behind it. Any leftover elements that don't fit evenly into a block are handled by
recursing on that remainder and merging it back in at the end.

Complexity-wise, Andrey Sort is `O(n log n)` in the best, average, and worst cases, with `O(1)`
auxiliary space — the same asymptotic guarantees as a textbook merge sort, but without paying for
a second array. That combination made it historically significant: it's an early, working proof
of concept for the "block merge sort" family, and it directly influenced the design of later,
more refined in-place merge sorts that built on the same backward-merge and block-selection ideas.

That said, this earlier version has a genuine, known limitation worth being upfront about: the
block-selection step decides which block to move next by comparing only each block's *first*
element, then relocates the entire block on the strength of that one comparison. With mostly
distinct keys, that shortcut is safe. With heavily duplicated input, it isn't — two blocks can
share a leading value while still needing to be interleaved differently once you look past the
first element, and the algorithm has no fallback for that case. It is not an implementation slip;
it is a structural gap in the original design, at a modest and narrow failure rate, that shows up
only when many equal keys are present. This is precisely the weakness that later members of the
same lineage — most notably the more advanced block-merge sorts that followed it — were built to
close, typically by pulling a small set of distinct "key" values out of the array up front so that
block comparisons are never ambiguous. Andrey Sort remains a faithful, working example of the
core technique; it just predates the fix for its one edge case.
