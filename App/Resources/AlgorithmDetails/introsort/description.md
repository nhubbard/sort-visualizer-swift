*From Wikipedia, the free encyclopedia*

Introsort or introspective sort is a hybrid sorting algorithm that provides both fast average performance and an optimal
worst-case performance. It begins with [quicksort](https://en.wikipedia.org/wiki/Quicksort) and switches
to [heapsort](https://en.wikipedia.org/wiki/Heapsort) when the recursion depth exceeds a level based on (the logarithm
of) the number of elements being sorted, and also switches
to [insertion sort](https://en.wikipedia.org/wiki/Insertion_sort) when the number of elements is below some threshold.
This combines the good practical performance of quicksort with the optimal worst-case running time of heapsort, and the
low overhead of insertion sort for small arrays. It was designed
by [David Musser](https://en.wikipedia.org/wiki/David_Musser), who introduced it in a 1997 paper.

Quick Sort alone has a worst-case running time of O(n²), which occurs on certain pathological inputs, such as arrays
that are already sorted or contain many repeated elements combined with a poor choice of pivot. Introsort avoids this by
monitoring the recursion depth of the quicksort partitioning process. If the depth exceeds a limit, typically twice
the [floor](https://en.wikipedia.org/wiki/Floor_and_ceiling_functions) of
the [binary logarithm](https://en.wikipedia.org/wiki/Binary_logarithm) of the number of elements, the algorithm abandons
quicksort for that partition and instead sorts it with heapsort, which guarantees O(n log n) performance regardless of
input. Because this fallback triggers only rarely, in the common case Introsort runs with the same low constant factors
and cache-friendly behavior as ordinary quicksort.

As a further optimization, once a partition becomes smaller than a fixed size threshold, Introsort stops recursing
altogether and finishes the sort with a single pass of insertion sort over the whole array. This is a common refinement
to quicksort implementations because insertion sort has less overhead than quicksort or heapsort on very small
partitions, and it can operate efficiently on a mostly-sorted array where every element is already close to its final
position.

Because it combines strong average-case speed with a guaranteed O(n log n) worst case and small memory overhead,
Introsort (or a close variant of it) is used as the sorting algorithm in a number of widely used standard library
implementations, including the `std::sort` function found
in [SGI's STL](https://en.wikipedia.org/wiki/Standard_Template_Library) and many derived C++ standard library
implementations, as well as .NET's `Array.Sort` method.
