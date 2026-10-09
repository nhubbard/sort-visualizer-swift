Merge sort is a stable comparison sort that recursively divides an array into two halves and merges the ordered halves
back together. A range containing fewer than two elements is already ordered. For a larger range, the algorithm sorts
its left and right halves separately, then repeatedly takes the smaller next element from the fronts of the two halves.
Any elements remaining in one half are copied after the other half is exhausted.

The merge writes the ordered result into temporary storage before copying it back to the array. When the next values
in the two halves are equal, the value from the left half is taken first. This preserves the input order of equal
elements, making this variant [stable](https://en.wikipedia.org/wiki/Sorting_algorithm#Stability). The repeated
halving gives the recursion logarithmic depth, and merging all ranges at any one depth examines a linear number of
elements. Best, average, and worst-case time are therefore O(n log n). The temporary merge storage requires O(n)
additional space.
