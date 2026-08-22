*From Wikipedia, the free encyclopedia*

Double Insertion Sort is a variant of [Insertion Sort](https://en.wikipedia.org/wiki/Insertion_sort) that builds its
sorted region from the middle of the array outward in both directions at once, rather than growing a single sorted run
from one end. It begins by comparing the two elements straddling the array's midpoint and swapping them into order if
needed, establishing a two-element sorted "seed" at the center.

From there, each iteration absorbs one additional element from each side of the growing sorted region — the element
immediately to its left and the element immediately to its right — and inserts both into their correct positions within
the region, shifting existing elements one slot at a time to make room. Because two new elements are placed per
iteration, the sorted region expands symmetrically toward both ends of the array as the algorithm progresses, until it
spans the entire array (with a single leftover element, when the array's length is odd, handled by a final insertion
pass).

Like standard Insertion Sort, Double Insertion Sort is an
in-place [comparison sort](https://en.wikipedia.org/wiki/Comparison_sort) that never requires more than a constant
amount of auxiliary storage, and its worst-case and average-case running time remains quadratic in the size of the
input. It offers no asymptotic advantage over ordinary Insertion Sort; its interest is chiefly as a novelty illustrating
how the same shifting technique can be organized around a growing bidirectional window instead of a single advancing
boundary.

Because every element is moved into place through a sequence of single-slot shifts rather than long-distance swaps, and
because equal elements are always shifted past on one side of the growing region but stopped short on the other, Double
Insertion Sort preserves the relative order of equal elements and is therefore
a [stable sort](https://en.wikipedia.org/wiki/Sorting_algorithm#Stability).
