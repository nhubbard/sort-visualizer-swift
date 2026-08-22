*From Wikipedia, the free encyclopedia*

Classic 3-Smooth Comb Sort is a variant of [Shellsort](https://en.wikipedia.org/wiki/Shellsort) built around a very
specific choice of gap sequence: every 3-smooth number below the array's length, used in strictly decreasing order. A
positive integer is 3-smooth if its only prime factors are 2 and 3 — that is, it can be written as `2^a * 3^b` for some
non-negative integers `a` and `b`, a family that includes 1, 2, 3, 4, 6, 8, 9, 12, 16, 18, 24, and so on. The algorithm
walks every candidate gap from `length - 1` down to `1`, discards any gap that isn't of this form, and for each gap that
survives, performs a single comparison-and-swap pass over the whole array: comparing the element `gap` positions back
against the current element, swapping them if the earlier one is strictly greater.

What sets this apart from an ordinary Comb Sort or a general Shellsort is that only *one* pass is ever performed at each
surviving gap — there is no repeated sweeping at the same gap until nothing moves, and no adaptive shrink factor
recomputed from how many swaps just happened. That single-pass-per-gap structure is not a shortcut that merely happens
to work well in practice; it is provably sufficient to fully sort any input. V. Pratt proved exactly this result in his
1972 Stanford PhD dissertation, *Shellsort and Sorting Networks*: running one comparison pass per 3-smooth gap, in
decreasing order, down to a final pass at gap 1, always leaves the array completely sorted, for any starting arrangement
of the data. Because the entire sequence of comparisons and swaps is fixed in advance and never depends on the values
being sorted, this makes Classic 3-Smooth Comb Sort a genuine sorting network rather than a heuristic — a rare property
for a Shellsort variant to have.

The running time follows directly from counting how many 3-smooth numbers lie below the array's length `n`. For each of
the `O(log n)` powers of 2 that stay below `n`, there are `O(log n)` powers of 3 that can be paired with it and still
keep the product under `n`, giving `Θ(log² n)` distinct 3-smooth gaps in total. Each of those gaps costs a single pass
of `Θ(n)` comparisons, so the overall running time is `Θ(n log² n)` — and because the algorithm is a fixed sorting
network, this bound holds identically in the best, average, and worst case; the data being sorted has no influence on
how much work is done. No recursion or auxiliary storage is used anywhere in the algorithm, so it runs in `O(1)`
additional space beyond the array itself.

Classic 3-Smooth Comb Sort is not a [stable sort](https://en.wikipedia.org/wiki/Sorting_algorithm#Stability). A pass at
any gap greater than 1 compares and swaps elements that sit far apart in the array without ever directly comparing the
elements sitting between them at that gap, so two equal-valued elements can each be relocated by different passes and
end up crossing paths without the two ever being compared against one another. This is the same instability every other
gap-based exchange sort has — ordinary Comb Sort and Shellsort included — and it holds here despite the algorithm's gap
sequence being a mathematically precise sorting network rather than a heuristic one.
