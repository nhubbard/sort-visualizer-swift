*From Wikipedia, the free encyclopedia*

Quadsort is a stable, bottom-up merge sort created by Igor van den Hoven in 2020. Rather than
splitting the input in half and recursing, it starts from the smallest already-sorted runs and
merges its way up: first sorting each small group of elements in place, then repeatedly combining
groups of four already-sorted runs into one larger run — the "quad" in its name — until a single
pass covers the whole array.

Its distinguishing technique is the parity merge: to combine two equal-length sorted runs into one
twice their size, it fills the merged output from both ends toward the middle at the same time,
rather than scanning from front to back alone. One direction compares elements ascending from the
front of each run, the other compares descending from the back. Because the two runs are the same
length, this always finishes exactly in the middle with no gap or overlap, and it does the same
amount of comparison work in roughly half the sequential passes a single-direction merge would
need. Ties are broken consistently in both directions — the front-to-back pass favors the earlier
run, and the back-to-front pass only favors it on a strict inequality — which is what keeps the
whole sort stable despite merging in two directions simultaneously.

Because it recognizes and skips merge work on runs that are already in the correct relative order,
quadsort is adaptive: partially-sorted or reverse-sorted input finishes with substantially fewer
comparisons than fully randomized input of the same size. Like other merge sorts, it needs a
scratch buffer roughly the size of its input, so it is not an in-place algorithm. It is still a
[comparison sort](https://en.wikipedia.org/wiki/Comparison_sort), though, so its worst case remains
O(n log n) — the same bound any general-purpose comparison-based sort is stuck with.
