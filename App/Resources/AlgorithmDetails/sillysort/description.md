Silly Sort was written by Tom Duff as an entry in the long-running "algorithms that are worse than
they have any right to be" genre, and is hosted at
[home.tiac.net/~cri_d/cri/2001/badsort.html](http://home.tiac.net/~cri_d/cri/2001/badsort.html). It
sorts a range `[i, j]` by splitting it at the midpoint `m`, recursively "silly-sorting" both
halves, comparing only the first elements of the two halves (`array[i]` and `array[m + 1]`) and
swapping them if they're out of order, and then — instead of stopping there — recursively
silly-sorting almost the *entire* remaining range, `[i + 1, j]`.

That last step is what makes this algorithm interesting rather than just quadratic: two half-size
recursive calls followed by one call on a range that's only one element smaller than the whole
thing is precisely the same recurrence shape as [Slowsort](https://en.wikipedia.org/wiki/Slowsort)'s
"multiply and surrender" strategy, `T(n) = 2T(n/2) + T(n - 1) + O(1)`. Solving that recurrence gives
`O(n^(log n))`, an exponent that keeps growing with the input size rather than staying fixed the
way a merge sort's or even a Stooge sort's does — the same asymptotically terrible territory
Slowsort occupies, arrived at independently by a different-looking recursive structure.

Because the compare-and-swap step operates on two elements — `array[i]` and `array[m + 1]` — that
are generally far apart in the array rather than adjacent, Silly Sort does not preserve the
original relative order of equal elements and is not a stable sort.
