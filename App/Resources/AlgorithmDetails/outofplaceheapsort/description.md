Out-of-place heap sort is a heap-based selection sort that keeps the classic two-phase shape of ordinary
heapsort — build a max-heap, then repeatedly pull off the maximum — but changes where the sorted result
actually accumulates. Instead of shrinking the heap by one slot and swapping the extracted maximum out to
the boundary of the array it came from, this variant writes each extracted value into a separate output
array and leaves a sentinel behind in its place, so the heap being sorted and the array holding the answer
are never the same piece of memory.

The heap is built with the same bottom-up optimization used by other heapsort variants: for each candidate
root, a descent phase always follows whichever child is larger, without ever comparing against the value
actually being sifted, all the way down to a leaf. Only once that leaf is reached does the search climb back
up the same path — now comparing the real value at each ancestor — to find exactly the level where it
belongs, and a final pass of swaps threads it into place while shifting everything above it up by one level.
This costs roughly one comparison per level instead of two, since the expensive descent is unconditional and
only the climb needs to check the value actually being placed.

Extraction works differently from ordinary heapsort's swap-and-shrink. Each round reads the current root —
always the largest value remaining, by the heap invariant — into the appropriate output slot, then
overwrites that root position with a sentinel marking it as spent. A dedicated repair step then sinks that
sentinel down the tree: at each level it looks at both children, and whichever one is not itself a spent
sentinel and is the larger of the two takes the sentinel's place, continuing until the sentinel reaches a
position with no living child left to displace. Because a spent sentinel never wins the comparisons that
decide where it travels, the invariant that the root always holds the current maximum among elements not yet
extracted survives every single extraction, all the way down to the last one.

Both phases together run in O(*n* log *n*) time, the same bound as ordinary heapsort, since each sift or
sentinel-sink still only touches O(log *n*) levels and there are O(*n*) of them across the whole sort. What
differs is space: because the sorted output accumulates in its own array rather than overwriting the input
as it shrinks, this algorithm needs O(*n*) auxiliary storage on top of the input, rather than the O(1) extra
space ordinary in-place heapsort gets away with. It is also not a stable sort — nothing about how heap
positions get chosen, or how a sentinel travels once it starts sinking, preserves the relative order of
equal elements, so two equal values can easily land in the output in the opposite order from how they
appeared in the input.