Forced Stable Quick Sort is an ordinary in-place quicksort — median-of-three pivot selection
followed by a Hoare-style partitioning scan — with one addition bolted on to make it stable. Quick
sort's usual weakness is that swapping elements to partition the array can reorder equal keys
relative to one another, so this variant carries a second, parallel array of each element's
original index alongside the data being sorted. Every swap performed on the main array is mirrored
on that index array, so at any point during the sort each element still "remembers" where it
started out.

Comparisons are routed through that memory: when two elements are equal, the algorithm breaks the
tie by comparing their original indices instead of treating them as interchangeable. The element
that started out earlier in the array is always considered the lesser of the two, so equal elements
can never cross past each other during partitioning, no matter how the pivot choices or swaps play
out. Everything else about the algorithm — recursing on the two partitions produced by each pivot,
falling back to a direct comparison-and-swap once a subrange shrinks to two or three elements — is
standard textbook quicksort.

Sorted order is still produced purely by swapping elements past one another rather than by any
auxiliary merging or counting step; the index array only rides along to arbitrate ties and never
itself moves data into new slots. Despite quicksort's reputation for being unstable, this
construction really does preserve the relative order of equal elements.
