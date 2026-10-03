Stooge sort is a recursive sorting algorithm with
[time complexity](https://en.wikipedia.org/wiki/Time_complexity) O(nˡᵒᵍ ³ ⁄ ˡᵒᵍ ¹·⁵), approximately O(n²·⁷⁰⁹⁵). Its
running time is slower than bubble sort but faster
than [Slowsort](https://en.wikipedia.org/wiki/Slowsort). The name comes
from [The Three Stooges](https://en.wikipedia.org/wiki/The_Three_Stooges).

The algorithm first swaps the values at the beginning and end when they are out of order. If the range contains at
least three elements, it recursively sorts the initial two thirds, then the final two thirds, and finally the initial
two thirds again.

The recursive range size must be calculated by rounding two thirds *upwards*. For example, two thirds of 5 must be
rounded to 4 rather than 3; otherwise, the algorithm can fail on some inputs.
