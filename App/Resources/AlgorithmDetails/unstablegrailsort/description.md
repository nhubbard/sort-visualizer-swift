Grail Sort, devised by Andrey Astrelin, is an in-place merge sort that achieves O(n log n) worst-case
time while using only O(1) extra memory, no matter how large the input gets. It gets there with a
"block merge" technique: the array is first chopped up and locally sorted into small fixed-size
blocks, those blocks are rearranged by repeatedly swapping small chunks of the array into place
(a rotation-based trick that stands in for the scratch buffer a normal merge sort would allocate),
and then whole blocks are merged together in passes of doubling size until the array is fully
sorted. Because every step works by shuffling elements that are already in the array rather than
copying them out to auxiliary storage, the whole sort never allocates memory proportional to the
input size.

This is the "unstable" member of the Grail Sort family. A companion "stable" version exists that
tags each block with which side of a merge it originally came from and threads that bookkeeping
through every merge step so that equal elements never cross past each other out of their original
order — at the cost of noticeably more bookkeeping and a bit more overhead. This version skips all
of that: when it needs to decide the relative order of two same-sized blocks during the combine
phase, it compares only the first element of each block, and if those are equal it falls back to
comparing the last element of each block. There is no tie-break based on where a block originally
sat in the array, so whenever two blocks contain equal keys the algorithm is free to reorder them,
and it does. The net result sorts correctly but does not preserve the relative order of equal
elements, which is what earns it the "unstable" name.

Like most block-merge sorts, Grail Sort doesn't fit neatly into a single traditional family — it
borrows the divide-and-conquer merge structure of merge sort, the run-detection and block-building
ideas common to hybrid sorts like Timsort, and in-place rotation techniques more commonly seen in
specialized array-rearrangement algorithms. It's best categorized as a hybrid sort: a purpose-built
combination of ideas assembled specifically to get merge sort's guaranteed O(n log n) behavior
without merge sort's usual O(n) space cost.
