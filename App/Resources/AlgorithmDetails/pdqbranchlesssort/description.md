Branchless Pattern-Defeating Quick Sort is the same pdqsort design as its branch-based sibling,
down to the pivot selection and the fast paths described below, but it replaces the inner
partitioning loop with a block-based scheme built for modern, deeply pipelined CPUs. Its pivot
choice still adapts to the size of the range being sorted: short ranges use a plain median of
three elements, while larger ranges sample nine points spread across the range, reduce them to
three candidates via three separate median-of-three comparisons, and take the median of those
three candidates as the final pivot. This "pseudomedian of nine" resists adversarial or
accidentally unlucky orderings far better than sampling just three points would.

The same up-front checks apply before any heavy partitioning work happens. If a range turns out to
already be correctly partitioned around the chosen pivot on the first pass, the algorithm tries a
cheap, bounded insertion sort on each side instead of recursing further, bailing out immediately if
that would require moving more than a handful of elements. And once the algorithm notices that
everything to the left of the current range is already known to be no larger than the range
itself, and the new pivot compares equal to that boundary value, it switches to a partition scheme
that groups equal elements to the left of the pivot and skips recursing into that now-settled left
side entirely, which keeps heavily duplicated runs of values from being re-partitioned over and
over.

What sets this variant apart is how its main partition step compares elements against the pivot.
Ordinary quicksort partitioning walks two pointers toward each other, branching on every single
comparison to decide whether to advance a pointer or perform a swap — a pattern that modern CPUs
predict poorly, stalling the pipeline on almost every iteration for anything but very orderly
input. This branchless partition instead scans a fixed-size block of elements from each end of the
range in a tight, predictable loop, recording the offsets of any elements that landed on the wrong
side of the pivot into two small scratch arrays rather than acting on each one immediately. Once
both blocks have been scanned, the recorded offsets are used to swap every mismatched pair between
the two blocks in a second, equally predictable loop, and the block boundaries slide inward before
the next pair of blocks is scanned. Because none of these loops need to branch on the comparison
result to decide what to do next, the CPU's branch predictor stays out of the picture almost
entirely, which is what gives this partitioning scheme its name.

Both variants guard against the classic O(n²) quicksort worst case the same way, with a
bad-partition counter that scrambles a few elements near the split point whenever a partition
comes out highly unbalanced, and falls back to heapsort for that range entirely if the count of
bad partitions ever exceeds an allowance based on the base-2 logarithm of the array's size. Between
its quicksort-style partitioning, its insertion-sort base case for small ranges, and its heapsort
escape hatch, this is still fundamentally a hybrid sort — the branchless partition changes how the
comparisons are carried out, not the overall shape of the algorithm. Its partitioning crosses
elements freely without any tie breaking, so like the branch-based variant it is not a stable sort.
