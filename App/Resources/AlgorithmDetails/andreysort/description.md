Andrey Sort, devised by Andrey Astrelin, is one of the earliest widely-circulated demonstrations
that an in-place merge sort could run in O(n log n) time using only O(1) extra memory, no
heap-allocated scratch array, no linked-list tricks, just reuse of the array's own trailing
space as a rotating buffer. For small ranges (below length 12) it simply falls back to an ordinary
selection sort, repeatedly finding the minimum of the unsorted remainder and swapping it to the
front. The interesting behavior only shows up above that threshold.

For larger ranges, the algorithm picks a block size, roughly the square root of the range's
length, rounded to a nearby power of two. It then builds up sorted runs of doubling size within a
portion of the array whose length is an exact multiple of that block size, using a technique
usually called a "backward merge": two already-sorted runs are merged not from their fronts into
a separate destination, but from their *tails*, moving right to left into a small trailing region
that briefly serves as scratch space. Because a run's own vacated tail becomes the buffer for the
next run, there is never a moment where the algorithm needs more working memory than the input
already provides. Once several same-sized blocks exist, a second technique takes over: the
algorithm selection-sorts the blocks by comparing only their leading elements, physically swapping
whole blocks into position, and backward-merges each selected block into the growing sorted
region behind it. Any leftover elements that do not fit evenly into a block are handled by
recursing on that remainder and merging it back in at the end.

Complexity-wise, Andrey Sort is O(n log n) in the best, average, and worst cases, with O(1)
auxiliary space, the same asymptotic guarantees as a textbook merge sort, but without paying for
a second array. That combination made it historically significant: it is an early, working proof
of concept for the "block merge sort" family, and it directly influenced the design of later,
more refined in-place merge sorts that built on the same backward-merge and block-selection ideas.

This version has a limitation on inputs containing many duplicate values. The block-selection step
chooses which block to move by comparing only the first element of each block. Two blocks can share
a first value while requiring different interleaving based on later values, and the algorithm has
no fallback for that case. Later block merge sorts avoid this ambiguity by extracting distinct key
values from the array before comparing blocks.
