Stable Quick Sort is a variant of Quick Sort built to fix the one property ordinary Quick Sort gives
up in exchange for sorting in place: the relative order of equal elements. Where a classic Lomuto or
Hoare partition swaps elements directly within the array as it scans, this version never swaps at
all. Instead, each partitioning step walks the range once from left to right and copies every
element (other than the pivot itself, always taken as the first element of the range) into one of
two temporary lists — one for elements smaller than the pivot, one for everything else — in the
exact order it encountered them.

Once the scan finishes, the range is rebuilt by writing the smaller-list back first, then the
pivot, then the rest, so the pivot lands at the boundary between the two groups exactly as it would
in a normal partition. The two halves on either side of that boundary are then partitioned the same
way, recursively, until the whole array is sorted.

Because neither temporary list ever changes the order its elements arrived in, and the write-back
step preserves that same order, two elements that compare equal to each other can never cross one
another during a partition. That guarantee holds at every level of the recursion, which makes the
sort as a whole genuinely stable — not just approximately or usually, but by construction. The price
for that guarantee is memory: each partitioning step allocates two new lists sized to the range being
partitioned, so the algorithm uses O(n) auxiliary space per level rather than the O(1) extra space a
swap-based partition needs, on top of the usual O(log n) of recursive call stack.

Its running time follows the same pattern as any single-pivot Quick Sort that always chooses the
first element as its pivot: O(n log n) on average, but O(n^2) in the worst case on adversarial
inputs, such as an already-sorted or reverse-sorted array, that repeatedly produce maximally
unbalanced partitions.
