*From Wikipedia, the free encyclopedia*

Fluxsort is a stable, hybrid quicksort/mergesort created by Igor van den Hoven — the same author
behind quadsort — as a fast, stable alternative to the classic introsort family of quicksorts.
Where an ordinary quicksort partitions its array in place and gives up stability to do it, fluxsort
borrows mergesort's trick of writing into a second buffer during partitioning, which lets it
preserve the original relative order of equal elements while still keeping quicksort's
divide-and-conquer recursion structure and its typically low overhead.

Each partitioning step samples a handful of elements from the range being sorted and takes their
median as the pivot, rather than committing to a single fixed element. A single bad pivot on one
range doesn't force a bad pivot on every range, which is what makes the algorithm adaptive to the
data it is actually sorting rather than to its position in the array. The range is then scanned
once: every element no larger than the pivot is written back into the array itself, and every
element larger than the pivot is written into the scratch buffer instead; the buffered elements are
then copied back immediately after the in-place ones, leaving two contiguous partitions in the
original array to recurse into separately. Because ties are resolved in favor of the in-place side
and the scan visits elements strictly in their original order, two elements that compare equal are
never reordered relative to each other — which is what keeps the sort stable despite partitioning
through an auxiliary buffer rather than swapping in place.

Recursion bottoms out once a range shrinks below a small size threshold, at which point it is
finished off with a single insertion-sort pass rather than partitioned any further, since insertion
sort's low overhead dominates on small ranges. Fluxsort's combination of mergesort-style buffered
partitioning and sampled, adaptive pivot selection bounds its worst case the same way a
median-of-medians quicksort does, giving it
[O(n log n)](https://en.wikipedia.org/wiki/Comparison_sort) time in both the average and worst
case — though, like mergesort, it needs scratch space proportional to the size of its input rather
than sorting fully in place.
