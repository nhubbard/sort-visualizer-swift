Pattern-Defeating Quick Sort (pdqsort) is a quicksort variant designed by Orson Peters that keeps
ordinary quicksort's excellent average-case speed while closing off the handful of input shapes
that make plain quicksort slow. Its pivot choice adapts to the size of the range being sorted:
short ranges use a plain median of three elements, but once a range grows past a threshold the
algorithm instead samples nine points spread across the range, reduces them to three candidates
via three separate median-of-three comparisons, and takes the median of those three candidates as
the final pivot. This "pseudomedian of nine" is far more resistant to adversarial or accidentally
unlucky orderings than sampling just three points would be.

Before committing to a full partition pass, pdqsort also checks whether the data handed to it is
already close to sorted. If a partition turns out to already be correctly split around the chosen
pivot on the very first pass, the algorithm tries a cheap, bounded insertion sort on each side
instead of recursing further, bailing out immediately if that insertion sort would have to move
more than a handful of elements. This lets already-sorted or nearly-sorted input finish in
close to linear time rather than paying for a full recursive partitioning it doesn't need.

A separate fast path watches for ranges containing many elements equal to the pivot. Once the
algorithm notices that everything to the left of the current range is already known to be no
larger than the range itself, and the new pivot compares equal to that boundary, it switches to a
partition scheme that groups equal elements to the left of the pivot rather than the right and
skips recursing into that now-settled left side entirely. This keeps runs of heavily duplicated
values from being needlessly re-partitioned over and over, which is exactly the case that trips up
naive quicksort implementations the worst.

Finally, pdqsort guards against the classic O(n²) quicksort worst case with a bad-partition
counter. Whenever a partition comes out highly unbalanced, the algorithm scrambles a few elements
near the split point to break up adversarial patterns like organ-pipe orderings, and decrements an
allowance that started at roughly the base-2 logarithm of the array's size. If that allowance ever
runs out, the algorithm gives up on quicksort for that range entirely and finishes it with
heapsort, which guarantees O(n log n) time regardless of input. Between its quicksort-style
partitioning, its insertion-sort base case for small ranges, and its heapsort escape hatch, pdqsort
is best classified as a hybrid sort. Its partitioning crosses elements freely without any tie
breaking, so like ordinary quicksort it is not a stable sort.
