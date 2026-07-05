*From Wikipedia, the free encyclopedia*

Insertion sort is a simple sorting algorithm that builds the final sorted array one item at a time. It is much less efficient on large lists than more advanced algorithms such as quicksort, heapsort, or merge sort. However, insertion sort provides several advantages:

1. Simple implementation: [Jon Bentley](https://en.wikipedia.org/wiki/Jon_Bentley_(computer_scientist)) has authored a three-line C++ implementation, and a five-line optimized version.
2. Efficient for (quite) small data sets, much like other quadratic sorting algorithms
3. More efficient in practice than most other simple quadratic (i.e., O(n²)) algorithms such as selection sort or bubble sort
4. [Adaptive](https://en.wikipedia.org/wiki/Adaptive_sort), i.e., efficient for data sets that are already substantially sorted: the time complexity is O(kn) when each element in the input is no more than k places away from its sorted position
5. [Stable](https://en.wikipedia.org/wiki/Stable_sort); i.e., does not change the relative order of elements with equal keys
6. [In-place](https://en.wikipedia.org/wiki/In-place_algorithm); i.e., only requires a constant amount O(1) of additional memory space
7. [Online](https://en.wikipedia.org/wiki/Online_algorithm); i.e., can sort a list as it receives it

When people manually sort cards in a [bridge](https://en.wikipedia.org/wiki/Contract_bridge) hand, most use a method that is similar to insertion sort.