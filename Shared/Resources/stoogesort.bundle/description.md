*From Wikipedia, the free encyclopedia*

Stooge sort is a recursive sorting algorithm. It is notable for its exceptionally bad [time complexity](https://en.wikipedia.org/wiki/Time_complexity) of O(n^(log 3 / log 1.5)) = O(n^(2.7095...)). The running time of the algorithm is thus slower compared to reasonable sorting algorithms, and is slower than bubble sort, a canonical example of a fairly inefficient sort. It is however more efficient than [Slowsort](https://en.wikipedia.org/wiki/Slowsort). The name comes from [The Three Stooges](https://en.wikipedia.org/wiki/The_Three_Stooges).

The algorithm is defined as follows:

* If the value at the start is larger than the value at the end, swap them.
* If there are 3 or more elements in the list:
    * Stooge sort the initial 2/3 of the list
    * Stooge sort the final 2/3 of the list
    * Stooge sort the initial 2/3 of the list again

It is important to get the integer sort size used in the recursive calls by rounding the 2/3 *upwards*, e.g. rounding 2/3 of 5 should give 4 rather than 3, as otherwise the sort can fail on certain data.
