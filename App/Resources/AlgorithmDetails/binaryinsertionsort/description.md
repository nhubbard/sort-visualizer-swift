*From Wikipedia, the free encyclopedia*

Binary Insertion Sort is a variant of [insertion sort](https://en.wikipedia.org/wiki/Insertion_sort) that uses
a [binary search](https://en.wikipedia.org/wiki/Binary_search_algorithm) to locate the correct position to insert each
element into the already-sorted portion of the array, rather than scanning linearly from the end of that run. This
reduces the number of comparisons needed to find the insertion point from O(n) to O(log n) per element.

The algorithm still processes the array from left to right, growing a sorted prefix one element at a time. For each new
element, it binary searches the sorted prefix to find the index at which the element belongs, then shifts every element
from that index up to the new element's original position one slot to the right to make room. Because the search only
narrows down *where* to insert, and shifting the intervening elements is still a linear operation, the total number of
element moves remains O(n^2) in the worst case — the same as ordinary insertion sort.

Care must be taken during the binary search to preserve stability: when the element being inserted is equal to an
element already in the sorted prefix, the search must continue toward the right half so the new element is placed
after — never before — elements that compare equal to it. Done this way, Binary Insertion Sort preserves the relative
order of equal elements, just like standard insertion sort.

Because comparisons are relatively cheap for primitive types but expensive for complex objects, Binary Insertion Sort is
most useful when the cost of a comparison meaningfully outweighs the cost of a move — for example, when sorting objects
using an expensive comparator. On small arrays, it remains a common building block inside hybrid sorts such as Timsort,
which switches to it for short runs.
