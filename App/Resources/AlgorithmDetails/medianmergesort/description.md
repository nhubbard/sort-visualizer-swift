Median merge sort combines partitioning with merging. It chooses a pivot from the first, middle,
and last elements, divides the current range into values on either side of that pivot, and fully
sorts the smaller partition with merge sort. It then repeats on the larger partition without
recursing into it. When the range becomes small, insertion sort finishes it. This keeps the
outer partition loop's call stack constant while spending the more expensive merge work on
the smaller side of each split.

The in-place variant uses the larger, not-yet-sorted partition to hold
values displaced by a swap-based merge of the smaller one. A second merge pass swaps those values
back, so no separate merge buffer is needed. If a split is extremely uneven, it gathers medians
of small groups before choosing the next pivot.

The partition swaps can change the relative order of equal elements, so the sort is not stable.
Balanced partitions take **O(n log n)** time. A long sequence of highly uneven partitions can
take **O(n²)** time; a median-of-medians fallback reduces that risk. Its swap-based merges use
**O(1)** auxiliary space.
