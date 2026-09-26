Insertion sort is a simple sorting algorithm that builds the final sorted array one item at a time. It is much less
efficient on large lists than more advanced algorithms such as quicksort, heapsort, or merge sort. Its implementation
is simple; [Jon Bentley](https://en.wikipedia.org/wiki/Jon_Bentley_(computer_scientist)) has written both a three-line
C++ implementation and a five-line optimized version. It is efficient for small data sets and often faster in practice
than other simple quadratic algorithms such as selection sort or bubble sort.

Insertion sort is [adaptive](https://en.wikipedia.org/wiki/Adaptive_sort), so it is efficient for data that is already
substantially sorted. Its running time is O(kn) when each element is no more than k places away from its sorted position.
It is also [stable](https://en.wikipedia.org/wiki/Stable_sort), preserving the relative order of equal keys;
[in-place](https://en.wikipedia.org/wiki/In-place_algorithm), requiring only constant additional space; and
[online](https://en.wikipedia.org/wiki/Online_algorithm), allowing it to sort a list as the values arrive.

When people manually sort cards in a [bridge](https://en.wikipedia.org/wiki/Contract_bridge) hand, most use a method
that is similar to insertion sort.
