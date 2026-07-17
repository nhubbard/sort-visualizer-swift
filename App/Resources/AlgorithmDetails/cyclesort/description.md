*From Wikipedia, the free encyclopedia*

Cycle Sort is an in-place, unstable sorting algorithm, a comparison sort that is theoretically optimal in terms of the
total number of writes to the original array, unlike any other in-place sorting algorithm. It is based on the idea that
the permutation to be sorted can be factored into cycles, which can individually be rotated to produce a sorted array.

Cycle Sort works by determining, for each element, its final position in the sorted output by counting how many elements
are smaller than it. If the element is already at that position, it is skipped; otherwise, the algorithm follows the
cycle it belongs to, writing each element directly to its final resting place exactly once and picking up whatever value
was displaced to continue the cycle. Because no element is ever written more than a single time, Cycle Sort minimizes
the number of writes to the underlying array, which makes it attractive when writes are far more costly than reads, such
as when sorting values stored in flash memory or EEPROM, where every write shortens the medium's lifespan.

Since elements are rotated directly to distant positions rather than shifted or exchanged with their neighbors, Cycle
Sort does not preserve the relative order of equal elements, so it is not a stable sort. It runs in O(n^2) time in the
best, average, and worst cases alike, because it must scan the remaining unsorted portion of the array to locate each
element's correct position even when the array is already sorted. Its only extra memory requirement is a handful of
scalar variables, giving it O(1) auxiliary space.
