*From Wikipedia, the free encyclopedia*

Binary Gnome Sort, as implemented here, processes the array from left to right, growing a sorted prefix one element at a
time. For each new element it performs a [binary search](https://en.wikipedia.org/wiki/Binary_search_algorithm) over the
already-sorted prefix to find the exact index at which the element belongs, then shifts every element from that index up
to the new element's original position one slot to the right (via a series of adjacent swaps) to make room. This is the
same technique used by [Binary Insertion Sort](https://en.wikipedia.org/wiki/Insertion_sort#Variants): using a binary
search to locate the insertion point reduces the number of comparisons needed per element from O(n) to O(log n), though
the total number of element moves remains O(n^2) in the worst case, since shifting the intervening elements is still a
linear operation.

Care must be taken during the binary search to preserve stability: when the element being inserted is equal to an
element already in the sorted prefix, the search continues toward the right half so the new element is placed after —
never before — elements that compare equal to it. Done this way, this algorithm preserves the relative order of equal
elements.

Despite its name, this particular "gnome sort" variant has nothing to do
with [gnome sort](https://en.wikipedia.org/wiki/Gnome_sort)'s classic technique of repeatedly comparing an element with
its predecessor and stepping backward through a swap when the pair is out of order (the "garden gnome sorting flower
pots" mental model). The name comes from ArrayV, the reference project this port is taken from, which historically
grouped this binary-search-driven shifting insertion under its "Optimized Gnome Sort" family and files it among its
Exchange Sorts, even though the algorithm it actually implements is structurally indistinguishable from Binary Insertion
Sort. This description reflects the algorithm ArrayV actually wrote, not an invented gnome-sort mechanism.
