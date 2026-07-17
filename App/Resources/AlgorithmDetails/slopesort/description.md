*From Wikipedia, the free encyclopedia*

Slope Sort is a comparison-based exchange sort that, for every starting position from the second element onward, walks
an adjacent pair backward from that position all the way to the front of the array, swapping any two neighbors it finds
out of order along the way. Each outer pass begins one element further to the right and drags a "slope" of comparisons
behind it back to index zero, checking every adjacent pair between the current position and the start of the array
rather than stopping once the moving element has found a place to rest.

That last detail is what separates Slope Sort from [Insertion Sort](https://en.wikipedia.org/wiki/Insertion_sort), whose
structure it otherwise closely resembles. Insertion Sort's backward walk exits as soon as it finds a neighbor that is
not out of order, since at that point the element being inserted has reached its correct slot and everything to its left
is already sorted relative to it. Slope Sort has no such early exit: every single adjacent pair between the current
outer index and the front of the array is re-examined and possibly swapped on every single pass, regardless of whether
the elements involved are already in their correct relative order. The result is a sort that performs the same shape of
comparisons as Insertion Sort but without ever skipping work it has already effectively done.

This lack of an early exit is also what makes Slope Sort strictly quadratic in every case. Insertion Sort's near-linear
best case comes entirely from that early exit — an already-sorted array lets each outer pass terminate after a single
comparison. Slope Sort's inner loop always runs the full distance back to the front of the array no matter how the
elements are arranged, so a fully sorted input costs exactly as many comparisons and potential swaps as a reverse-sorted
one. Both its best and worst cases are therefore `O(n^2)`, with no data-dependent shortcut available.

Slope Sort belongs to ArrayV's "Exchange Sorts" family, the group of sorts that make progress purely by swapping pairs
of adjacent or nearby elements rather than by selecting, merging, or partitioning. Because it only ever swaps two
elements when the left one is strictly less than the right one — never when they are equal — two equal elements are
never reordered relative to each other, which makes Slope Sort a stable sort.
