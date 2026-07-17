*From Wikipedia, the free encyclopedia*

The **Lomuto partition scheme** is one of the two classic ways to implement the partitioning step
of [Quick Sort](https://en.wikipedia.org/wiki/Quicksort), alongside
the [Hoare partition scheme](https://en.wikipedia.org/wiki/Quicksort#Hoare_partition_scheme) that Tony Hoare originally
described. Named after Nico Lomuto, it always chooses the last element of the current range as the pivot, then makes a
single left-to-right pass with one index tracking the boundary between elements already confirmed to be less than the
pivot and elements not yet examined. Every time the scan finds an element smaller than the pivot, it is swapped into
that boundary and the boundary advances by one. Once the scan reaches the end of the range, the pivot is swapped into
place immediately after the boundary, which is now exactly where the pivot belongs in the fully partitioned array.

Because it uses only a single moving pointer instead of two pointers converging from opposite ends, the Lomuto scheme is
generally considered easier to understand and to implement correctly than the Hoare scheme, and it is the version most
often taught in introductory algorithms courses. That simplicity comes at a cost in practice: Lomuto partitioning tends
to perform noticeably more swaps than Hoare partitioning on the same input, since it swaps on every element found to be
less than the pivot rather than only when two out-of-place elements are found from opposite directions.

A more serious drawback is Lomuto's behavior on already-sorted or reverse-sorted input. Because the pivot is always the
last element of the range with no randomization or median-of-three selection to guard against it, sorted or
nearly-sorted arrays produce maximally unbalanced partitions on every recursive call — one side of the partition is
empty and the other holds all the remaining elements — which drives the running time to the algorithm's O(n^2) worst
case and, in a naive recursive implementation, to O(n) recursion depth as well. Real-world Quick Sort implementations
typically guard against this by randomizing the pivot choice or selecting a median-of-three pivot before falling back to
Lomuto- or Hoare-style partitioning around it.

Like ordinary Quick Sort, a Lomuto-partitioned Quick Sort is an
in-place [divide-and-conquer algorithm](https://en.wikipedia.org/wiki/Divide-and-conquer_algorithm) and a comparison
sort. It is not a [stable sort](https://en.wikipedia.org/wiki/Sorting_algorithm#Stability): elements compared equal to
the pivot can still be reordered relative to one another as they are swapped into and out of the "less than" region
during partitioning.
