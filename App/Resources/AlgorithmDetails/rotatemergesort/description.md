*From Wikipedia, the free encyclopedia*

Rotate Merge Sort is a variant of [Merge Sort](https://en.wikipedia.org/wiki/Merge_sort) that merges two sorted runs
entirely in place, without allocating an auxiliary buffer to hold either run while the merge is in progress. Where a
classic merge steps through both runs in lockstep, copying the smaller of the two leading elements into a temporary
array, Rotate Merge Sort instead finds, via [binary search](https://en.wikipedia.org/wiki/Binary_search_algorithm), the
single point at which the two runs interleave, and then performs a **block rotation** — swapping one contiguous span of
elements with an adjacent equal-length span — to move both runs into their combined sorted order in a single step. The
two smaller regions left on either side of the rotation, each still containing an unmerged remainder of both runs, are
then merged the same way, recursively.

The rotation itself is also implemented without extra storage: a rotation of two adjacent blocks is built out of
repeated block-swaps between the smaller of the two blocks and an equal-sized slice of the larger one, shrinking
whichever block was just fully consumed until one side is exhausted. Because the split point on each merge is located by
binary search rather than by a linear scan, and each element still only moves a bounded number of times across the whole
merge, the total work stays proportional to what an ordinary merge would do — giving Rotate Merge Sort the same O(n log
n) running time as textbook Merge Sort, while using only O(1) auxiliary space beyond the recursion itself.

This distinguishes it from simpler in-place merge techniques, which typically shift each out-of-place element one
position at a time to make room for it — a strategy that can degrade to quadratic time in the worst case, since a single
misplaced element may need to be walked across an entire run. Rotate Merge Sort avoids this by always moving whole
blocks at once and by using binary search to decide where those blocks belong, rather than discovering it through
element-by-element comparisons.

To remain a [stable sort](https://en.wikipedia.org/wiki/Sorting_algorithm#Stability), the binary search that locates
each split point uses a comparison biased by which of the two runs the search value originated from: a value taken from
the left run is placed ahead of any equal elements already in the right run, while a value taken from the right run is
placed behind any equal elements already in the left run — so an element that started out on the left never ends up
ordered after an equal element that started out on the right.
