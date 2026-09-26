*From Wikipedia, the free encyclopedia*

Stooge sort is a recursive sorting algorithm. It is notable for its exceptionally
bad [time complexity](https://en.wikipedia.org/wiki/Time_complexity) of O(n^(log 3 / log 1.5)) = O(n^(2.7095...)). The
running time of the algorithm is thus slower compared to reasonable sorting algorithms, and is slower than bubble sort,
a canonical example of a fairly inefficient sort. It is however more efficient
than [Slowsort](https://en.wikipedia.org/wiki/Slowsort). The name comes
from [The Three Stooges](https://en.wikipedia.org/wiki/The_Three_Stooges).

The algorithm first swaps the values at the beginning and end when they are out of order. If the range contains at
least three elements, it recursively sorts the initial two thirds, then the final two thirds, and finally the initial
two thirds again.

It is important to get the integer sort size used in the recursive calls by rounding the 2/3 *upwards*, e.g. rounding
2/3 of 5 should give 4 rather than 3, as otherwise the sort can fail on certain data.
