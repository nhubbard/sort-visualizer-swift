*From Wikipedia, the free encyclopedia*

Block-Swap Merge Sort is a variant of [Merge Sort](https://en.wikipedia.org/wiki/Merge_sort) that merges two sorted runs
entirely in place, without allocating an auxiliary buffer and without performing a general rotation either. Where a
classic merge steps through both runs in lockstep, copying the smaller of the two leading elements into a temporary
array, Block-Swap Merge Sort instead uses [binary search](https://en.wikipedia.org/wiki/Binary_search_algorithm) to find
how many elements at the tail of the left run are out of order relative to the elements at the head of the right run,
and then exchanges those two equal-length spans directly, one element at a time.

The key observation that makes this work is that exchanging two blocks of the *same* length is already a complete
rearrangement of those `2m` elements into sorted relative order — no general-purpose rotation machinery is needed,
because the binary search is specifically designed to find a split where both sides being swapped are guaranteed to be
the same size. After one such block-swap, the newly-relocated elements from the left run are not yet in their final
position among the rest of the right run, so the algorithm recurses to merge that leftover portion, then shrinks its own
problem to whatever remains of the original left run and searches again. This repeats until a search finds nothing left
to swap, at which point the two runs are fully merged.

Because the split point on each step is found by binary search rather than a linear scan, and every element crosses the
boundary between the two runs via a block-swap at most once, the total work across a full merge is still proportional to
the size of the two runs being merged — giving Block-Swap Merge Sort the same O(n log n) running time as textbook Merge
Sort in the best, average, and worst cases, while using no auxiliary array at all. The only extra memory it consumes is
the call stack of its own recursive merge step, which stays logarithmic in the size of the array.

Block-Swap Merge Sort is also a [stable sort](https://en.wikipedia.org/wiki/Sorting_algorithm#Stability): the binary
search that decides how many elements to swap only advances when an element from the left run is *strictly* greater than
its counterpart from the right run, so two elements that compare equal — one from each run — are never pulled across the
boundary relative to one another. The left run's copy of a tied value therefore always keeps resting ahead of the right
run's copy, exactly the convention that keeps an ordinary two-way merge stable.

This distinguishes it from simpler in-place merging techniques, such as repeatedly swapping an out-of-order element and
then shifting it one position at a time into place, which can degrade to quadratic running time in the worst case and
often lose stability in the process. By always moving whole same-length blocks at once, and by using binary search to
decide exactly how many elements need to move rather than discovering it through element-by-element shifting, Block-Swap
Merge Sort keeps both the speed and the stability of a textbook merge while eliminating its memory requirement.
