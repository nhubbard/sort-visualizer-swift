Slowsort is a recursive sorting algorithm based on the principle called multiply and surrender, a reversal of the
divide-and-conquer method used by algorithms such as Merge Sort and Quick Sort. It sorts two halves recursively,
places their maximum at the end, and repeats most of the work on a slightly smaller range. It was described as an
example of inefficient algorithm design.

The recursive step, slowSort(A, i, j), splits the range [i, j] at its midpoint m, recursively sorts [i, m] and
[m + 1, j], and then compares only the two "boundary" elements A[m] and A[j], swapping them if A[m] is strictly
larger. This settles the maximum of the two halves into the last position, j, but instead of stopping there, the
algorithm then recurses on [i, j − 1], redoing nearly the entire sort to place the next-largest element, and so on. The
result is a recursive restatement of selection sort, where finding "the maximum of the remaining range" is itself
accomplished by a wasteful divide-and-conquer tournament rather than a simple linear scan.

Slowsort's recurrence, T(n) = 2T(n ÷ 2) + T(n − 1) + O(1), resolves to
O(nˡᵒᵍ ⁿ), an exponent that grows with the input size itself, so the algorithm is asymptotically worse than any
fixed polynomial (quadratic, cubic, or otherwise), yet still faster than a factorial-time brute force. This makes it
substantially slower in practice than [Stooge Sort](https://en.wikipedia.org/wiki/Stooge_sort), another deliberately
inefficient recursive sort with which it is often compared. Stooge Sort's exponent, log(3) ÷ log(1.5) ≈ 2.71, is fixed
and merely polynomial, while Slowsort's keeps climbing as the input grows.

Slowsort is an intentionally inefficient algorithm used to illustrate the consequences of overlapping recursive work.
