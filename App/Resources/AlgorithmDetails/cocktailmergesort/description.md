*From Wikipedia, the free encyclopedia*

Cocktail Merge Sort is a hybrid sorting algorithm that
combines [Cocktail Shaker Sort](https://en.wikipedia.org/wiki/Cocktail_shaker_sort) with the run-merging strategy
popularized by [Timsort](https://en.wikipedia.org/wiki/Timsort). Rather than sorting the entire array with one
technique, it splits the array into small fixed-length chunks — sized using Timsort's standard "minimum run length"
calculation — and sorts each chunk in place with Cocktail Shaker Sort. Once every chunk is individually sorted, the
algorithm repeatedly merges adjacent sorted runs together, doubling the merged run length on each pass, until the whole
array is one sorted run.

This is, in effect, a drop-in replacement for the insertion sort that Timsort ordinarily uses to build its initial runs.
Cocktail Shaker Sort is a perfectly serviceable way to sort a small chunk of elements, and swapping it in does not
change the overall shape of the algorithm: build small sorted runs cheaply, then merge them. Because the run length is
bounded by a small constant regardless of the input size, the run-building phase contributes only a modest, roughly
linear amount of work in most practical cases, while the merge phase still does the heavy lifting at O(n log n).

Cocktail Merge Sort exists primarily as a novelty and teaching example rather than as a genuine improvement over either
of its component algorithms. Cocktail Shaker Sort alone already comfortably handles small runs, and standard merge sort
variants already produce O(n log n) behavior without introducing extra bookkeeping to first shake each chunk into order.
The combination is nonetheless illustrative: it shows how an exchange sort and a merge sort can be composed at different
size scales, with the exchange sort acting as a "base case" specialist and the merge acting as the algorithm's
asymptotic backbone.

Because both of its component techniques are stable — Cocktail Shaker Sort never reorders equal adjacent elements it
does not need to move, and the merge step always prefers an element from the earlier run when two elements compare
equal — the composed algorithm preserves the relative order of equal elements as well.
