Median merge sort combines partitioning with merging. It chooses a pivot from the first, middle,
and last elements, divides the current range into values on either side of that pivot, and fully
sorts the smaller partition with merge sort. It then repeats on the larger partition without
recursing into it. When the range becomes small, insertion sort finishes it. This keeps the
outer partition loop's call stack constant while spending the more expensive merge work on
the smaller side of each split.

The app's implementation is in-place: the larger, not-yet-sorted partition temporarily holds
values displaced by a swap-based merge of the smaller one. A second merge pass swaps those values
back, so no separate merge buffer is needed. If a split is extremely uneven, it gathers medians
of small groups before choosing the next pivot. The reference examples below keep the same
partition-and-sort-the-smaller-side structure, but use a conventional scratch array for merge
sort to make the central idea easier to read across languages.

The partition swaps can change the relative order of equal elements, so the sort is not stable.
Balanced partitions take **O(n log n)** time. A long sequence of highly uneven partitions can
take **O(n²)** time; the app's median-of-medians fallback reduces that risk. The app's merges use
**O(1)** auxiliary space, while these shorter reference examples use **O(n)** scratch space.
