*From Wikipedia, the free encyclopedia*

[Cocktail Shaker Sort](https://en.wikipedia.org/wiki/Cocktail_shaker_sort), also known as bidirectional bubble sort,
cocktail sort, shaker sort, ripple sort, shuffle sort, or shuttle sort, is an extension
of [Bubble Sort](https://en.wikipedia.org/wiki/Bubble_sort) that sweeps forward through the unsorted portion of the
array carrying the largest remaining value to the end, then immediately sweeps backward carrying the smallest remaining
value to the beginning. The Unoptimized Cocktail Shaker Sort is a deliberately naive variant of that same idea: it
performs the identical forward-then-backward double sweep, but without either of the two adaptive tricks that make the
ordinary version fast on nearly-sorted input.

A standard Cocktail Shaker Sort keeps track of whether a pass made any swaps at all, and stops the moment a full
forward-and-backward pass makes none — that is what gives it a best-case running time of O(n) on already-sorted input. A
further-optimized variant goes one step beyond that by also shrinking the scanned range on each side by however many
trailing elements were confirmed already in order, so later passes never re-check ground they have already covered. This
unoptimized variant does neither. Its outer loop simply runs a fixed number of times — half the array's length — no
matter what the data looks like, and each pass always scans the exact same shrinking-by-one-per-side range that the loop
counter dictates, regardless of whether the array became fully sorted three passes ago or is still in complete disarray.
There is no swap-tracking flag anywhere in the algorithm, so nothing can ever cause it to finish early.

That single omission has a real asymptotic cost, not just a slower constant factor: because the number of outer passes
and the size of each pass's scanned range are both fixed by the loop counter rather than by anything the algorithm
observes about the data, even a fully sorted input still forces every comparison in every pass to run to completion.
Best case, average case, and worst case are therefore all O(n^2) — a strictly worse best case than either the plain or
optimized Cocktail Shaker Sort, both of which enjoy an O(n) best case on sorted input. This is precisely what the "
Unoptimized" name is calling out: the two mechanisms that give its siblings their favorable best case are exactly the
two mechanisms this variant lacks.

Like its siblings, Unoptimized Cocktail Shaker Sort is stable: every swap decision uses a strict comparison (an element
only moves past its neighbor when it is *strictly* greater, or *strictly* less, never on a tie), so two equal-valued
elements can never cross past one another. It sorts in place and needs no auxiliary storage beyond a couple of loop
counters, giving it O(1) space complexity.
