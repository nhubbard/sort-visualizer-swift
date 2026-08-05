Rotate MSD Radix Sort is a most-significant-digit-first radix sort that never allocates a bucket
array. An ordinary MSD radix sort distributes a range of the array into one bucket per digit
value, then recurses into each bucket to distribute it again by the next digit — the buckets
themselves are usually built as separate lists, or at least as an O(n) scratch array that elements
get copied through. This variant replaces that distribution step with the same block-rotation
machinery used by its LSD counterpart: to group a range by its current digit, it treats each
possible digit value as already being "sorted" on its own, then merges those trivial one-digit
runs back together two at a time, using binary search to find where one run's digit values stop
being less than the midpoint digit value and a rotation — swapping two adjacent blocks past each
other with no auxiliary storage — to interleave the two runs in the correct order. The result is
an ordinary in-place merge sort whose comparison key is a single digit rather than the whole
value, so it only ever needs to distinguish `base` possible outcomes at a time instead of the full
range of the data.

Because that rotation-based digit-sort works on any contiguous range and any single digit place,
it slots directly into the most-significant-digit recursion: sort a range by its current digit,
then use the same binary search that guided the rotations to locate where each digit value's
elements begin and end, and recurse into every resulting bucket one digit place lower. A bucket
that has been fully distinguished from the values around it — either because every element left
in it is identical, or because its digit place has counted down past zero — stops recursing, the
same early-exit MSD radix sort gets from processing digits most-significant-first in general:
once two keys disagree in an earlier digit, no later digit can change their relative order, so
there's nothing left to compare within that bucket.

Because every relocation happens through swaps of one array against itself rather than through
copies into a second array, the whole sort runs in O(1) auxiliary space, matching its LSD
counterpart. The trade is time: locating each digit boundary costs a binary search, and every
rotation still has to physically move every element in the smaller of the two blocks being
swapped, so a single digit-sorting pass over a range of `n` elements costs O(n log n) rather than
the O(n) a bucket-counting pass would. With `d` digit places to work through, the whole sort costs
O(d × n log n) time against O(1) extra space, and because the underlying rotations never reorder
two elements that compare equal on the digit being examined, the sort remains stable.
