*From Wikipedia, the free encyclopedia*

Library Sort, also called gapped insertion sort, is a [comparison sort](https://en.wikipedia.org/wiki/Comparison_sort)
that takes its name from the way librarians shelve books: rather than packing volumes together with no room to spare, a
librarian leaves empty gaps along the shelf so that a newly-acquired book can usually slot into the right place without
having to shift every book that follows it. The algorithm was formally analyzed by Michael A. Bender, Martín
Farach-Colton, and Miguel Mosteiro, who showed that maintaining such gaps turns the O(n^2) worst case of
ordinary [insertion sort](https://en.wikipedia.org/wiki/Insertion_sort) into an expected O(n log n) running time,
matching comparison-based sorts like [Quick Sort](https://en.wikipedia.org/wiki/Quicksort)
and [Merge Sort](https://en.wikipedia.org/wiki/Merge_sort) while still inserting elements one at a time.

The algorithm builds up a sorted "spine" of elements and periodically absorbs a batch of further elements from the
unsorted remainder. Each element in a batch is placed with a binary search against the spine to determine which of the
spine's gaps it belongs in — before the first spine element, between two spine elements, or after the last one — without
yet touching the array. Once a batch has been fully classified, a rebalancing step lays every element back out with
fresh gaps sized to how many batch elements landed in each one, so that the spine (now larger) again has room to absorb
the next batch cheaply. Because a batch's elements are only known to belong to the same gap, not to be in order relative
to one another, each gap's batch elements still need a short local sort once they are placed — but this touches only the
handful of elements sharing that gap, not the whole array.

Because every comparison during classification only ever decides that a new element goes strictly before or after an
existing one, without displacing elements already known to be equal to it, Library Sort preserves the relative order of
equal elements and is a [stable sort](https://en.wikipedia.org/wiki/Sorting_algorithm#Stability). Its expected O(n log
n) running time comes at the cost of the O(n) extra memory used to hold the gapped layout during a rebalance, and —
unlike an in-place sort — its performance depends on gaps being resized often enough that no single batch ever grows
large enough to fall back toward quadratic behavior.
