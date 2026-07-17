*From Wikipedia, the free encyclopedia*

Swapless Bubble Sort is a variant of [Bubble Sort](https://en.wikipedia.org/wiki/Bubble_sort) that produces the exact
same comparisons and the same final ordering, but never calls a two-element swap. Instead of exchanging `array[j]` and
`array[j + 1]` whenever they are out of order, it carries the larger of the two compared values forward in a single
local variable and repeatedly overwrites one array slot at a time with whichever value belongs there. By the end of a
pass, every element that a classic bubble sort would have swapped has instead been moved into place through a chain of
single-element writes.

Concretely, each pass holds a "carried" value, starting with the first element of the unsorted region. As it walks
rightward, it compares the carried value against the next array element: if the carried value is strictly greater, the
smaller element is written one slot to the left and the carried value keeps moving right; otherwise, the carried value
is written into place and the array element it just lost to becomes the new carried value. The pass finishes by writing
whatever value it is still carrying into the newly-shrunk boundary, the same position where the largest unsorted element
would have landed after a normal bubble sort pass.

This restructuring matters on systems, cost models, or visualizations where a swap and a write are not equivalent
operations — a swap is conventionally two writes performed together, while this technique achieves the same
rearrangement using no more than one write per comparison. Since it only ever moves a value when the carried value
compares strictly greater than the value it is being measured against, equal elements are never reordered relative to
one another, so the algorithm remains stable, just like the ordinary bubble sort it re-expresses.

Asymptotically, Swapless Bubble Sort behaves identically to Bubble Sort: each pass still shrinks to the position of the
last shift, giving a best case of O(n) on already-sorted input, and both the average and worst cases remain O(n^2),
since the number of out-of-order relationships to resolve in an arbitrary permutation does not change just because the
underlying primitive changed from a swap to a write.
