*From Wikipedia, the free encyclopedia*

Hybrid Comb Sort is a variant of [Comb Sort](https://en.wikipedia.org/wiki/Comb_sort) that abandons Comb Sort's
shrinking-gap technique partway through and finishes the sort with a single pass
of [Insertion Sort](https://en.wikipedia.org/wiki/Insertion_sort) instead. It keeps Comb Sort's early advantage — using
a large gap to move far-apart out-of-order elements toward their final positions in only a few passes — while avoiding
the tail end of the algorithm, where the gap has shrunk so small that each remaining pass behaves almost exactly like a
slow, single-pass bubble sort.

Ordinary Comb Sort starts with a gap equal to the length of the array and shrinks it every pass by a fixed factor,
conventionally about 1.3, comparing and swapping elements that are `gap` positions apart until the gap reaches 1, at
which point it continues making adjacent-element passes until an entire pass completes with no swaps. That tail — every
pass from the point the gap first drops below some small constant onward — contributes very little additional benefit
over what a plain Insertion Sort would already do given the same partially-ordered array, since by then most
long-distance disorder has already been resolved by the larger gaps.

Hybrid Comb Sort exploits this by tracking the gap on every pass and checking, before each individual comparison,
whether the gap has fallen to or below a small threshold — the smaller of 8 or roughly one thirty-second of the array's
length. The moment that happens, it immediately switches strategies: it collapses the gap to zero, performs one complete
Insertion Sort pass over the entire array from the very first element to the last, and stops using the comb-gap
technique for the rest of the sort. Because the array is already substantially ordered by that point, this finishing
pass runs efficiently, with each element typically needing to move only a short distance to reach its correct position.

Because the switch to Insertion Sort is only a late-stage refinement and does not change how the earlier large-gap
passes reorder elements, Hybrid Comb Sort shares Comb Sort's own asymptotic behavior — it is not a stable sort, since a
large early gap can still swap two equal elements out of their original relative order well before the Insertion Sort
finish ever runs. The hybrid strategy improves Comb Sort's practical running time on the passes it would otherwise have
spent grinding through an already-small gap, without changing its worst-case or average-case complexity class.
