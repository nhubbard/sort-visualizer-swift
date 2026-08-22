*From Wikipedia, the free encyclopedia*

Stable Selection Sort is a variant of ordinary [Selection Sort](https://en.wikipedia.org/wiki/Selection_sort) that
repairs its one significant weakness: the classic algorithm is not
a [stable sort](https://en.wikipedia.org/wiki/Sorting_algorithm#Stability). Both variants scan the unsorted suffix of
the array on each pass to find its minimum element, but they differ entirely in how that minimum is moved into place.

Plain Selection Sort swaps the found minimum directly with the element currently occupying the front of the unsorted
region. If one or more elements equal in value to the minimum happen to sit between its found position and that front
position, the swap leapfrogs the minimum past them, silently reordering equal elements relative to one another. Stable
Selection Sort avoids this by rotating the minimum into place instead: every element between the front of the unsorted
region and the minimum's found position is shifted one slot to the right, and only then is the minimum value written
into the now-vacated front slot. Because every equal-valued element in that span simply slides over rather than being
jumped, no two equal elements ever change their relative order, making the algorithm genuinely stable.

The comparison work is unchanged from plain Selection Sort: finding the minimum of an unsorted suffix of length k still
takes k - 1 comparisons, for the same O(n^2) total comparisons across all passes. What changes is the cost of placing
that minimum. A swap moves two elements with a single exchange, but the rotation used here writes one element per
position shifted, so on data where the minimum is frequently found far from the front of the unsorted region, this
variant performs strictly more write operations than its unstable sibling for the same asymptotic O(n^2) bound.

Because it never exchanges elements out of order and never allows one equal element to overtake another, Stable
Selection Sort preserves the relative order of equal keys throughout the sort, unlike the classic swap-based version it
is derived from.
