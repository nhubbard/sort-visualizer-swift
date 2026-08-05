Merge sort is a [comparison-based](https://en.wikipedia.org/wiki/Comparison_sort),
[divide-and-conquer](https://en.wikipedia.org/wiki/Divide-and-conquer_algorithm) sorting algorithm: split the input
into two halves, sort each half, then merge the two sorted halves back together in linear time. The classic
"top-down" formulation expresses this literally as recursion — a `sort` routine calls itself on the left half and the
right half of the range it was handed, splitting at the true midpoint each time, until it bottoms out at ranges of
length zero or one, which are trivially already in order.

Iterative Top-Down Merge Sort computes that exact same top-down, true-midpoint recursion, but without ever calling
itself. It walks the recursion tree level by level using plain arithmetic in place of function calls.

To see how, first notice how many leaves the top-down tree would have if it kept splitting all the way down to
length-one ranges: it's the smallest power of two that is at least as large as the array's length, `n`. Call that
count `subarrayCount`. Every level of the tree, from the leaves back up to the root, has a number of slices that is
itself a power of two — `subarrayCount`, then `subarrayCount / 2`, then `subarrayCount / 4`, and so on down to `1` at
the root.

The algorithm starts at the finest level and works upward. On each pass it merges adjacent pairs of slices to
produce the next, coarser level, then halves `subarrayCount` and repeats until a single slice — the whole sorted
array — remains. The detail that keeps this equivalent to genuine recursion, even when `n` is not a power of two, is
how each slice's boundaries are located: rather than a fixed width, slice `i` out of `subarrayCount` slices runs from
index `n * i / subarrayCount` up to `n * (i + 1) / subarrayCount`, using integer division. Because these boundaries
scale with `n` instead of staying a fixed width, they land on precisely the same split points a recursive
true-midpoint merge sort would choose, remainder and all — a slice that "should" have fractional size rounds the
same way on both sides of the matching recursive split, so the same elements always end up adjacent at every level.
No separate cleanup pass is needed for a leftover remainder, which is what sets this technique apart from the more
common bottom-up (doubling-width) iterative merge sort, where run widths double by a fixed amount on every pass and
a short leftover run at the array's tail has to be carried forward untouched and merged in later.

Each individual merge is the ordinary two-pointer routine: repeatedly compare the next unconsumed element of the
left slice against the next unconsumed element of the right slice, copy the smaller one out to a temporary buffer,
and advance that slice's pointer; once one side is exhausted, copy the remainder of the other side across
unchanged. Taking from the left slice whenever the two compared elements are equal — rather than the right — is what
keeps the algorithm [stable](https://en.wikipedia.org/wiki/Sorting_algorithm#Stability): equal elements never cross
past one another during a merge, so their relative order survives intact.

Like any merge sort, this variant runs in `O(n log n)` time in the best, average, and worst cases: there are
`O(log n)` passes, and each pass does `O(n)` total comparison-and-copy work spread across all of its merges. It
needs an auxiliary buffer proportional to `n` to hold each merge's output before it is copied back, so it is not an
in-place algorithm, and as established above, it is stable.
