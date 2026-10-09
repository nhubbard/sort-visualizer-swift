Buffer partition merge sort is an in-place hybrid of selection, insertion sort, and merge sort. It
first sorts the upper half of the array while using the lower half as a swap buffer. It then uses
quickselect to isolate a smaller partition from the unsorted prefix, sorts that partition into the
buffer, and merges it forward into the sorted suffix. This process moves the buffer toward the
front until the remaining prefix is small enough for binary insertion sort.

Median-of-three pivot selection handles ordinary partitions. If a split is severely unbalanced,
the algorithm gathers medians from groups of five before selecting another pivot. The final two
runs are combined with rotations, so the app implementation allocates no auxiliary array.
Partition swaps and buffer exchanges can change the relative order of equal elements.

Buffer partition merge sort takes **O(n log n)** time and uses **O(1)** auxiliary space. The
reference implementations use short insertion-sorted runs and a conventional merge buffer. They
retain the partitioned-run schedule while omitting the app implementation's swap-buffer index
management.
