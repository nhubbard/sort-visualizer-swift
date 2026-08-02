Lazy Stable Sort is a simple in-place merge sort that skips the elaborate block-tagging and
key-collection machinery a full Grail Sort needs to run in constant extra space. It does its work
in two passes: first it walks the array in adjacent pairs, swapping any pair that's out of order
so the whole array becomes a sequence of sorted runs of length two. Then it repeatedly doubles the
size of the sorted runs it's working with — merging pairs of length-two runs into length-four
runs, then pairs of length-four runs into length-eight runs, and so on — until a single pass
covers the whole array.

Each of those merges is done by a binary-search-and-rotate routine that needs no scratch buffer
at all. To merge two adjacent sorted stretches, it binary-searches for where the midpoint of the
first stretch would land inside the second, rotates that chunk of the second stretch into place
using a series of block swaps, and then recurses on the two smaller merge problems left on either
side of the rotation. Because every step is just comparisons, swaps, and rotations on the array
itself, the whole sort runs in O(1) auxiliary space, at the cost of the extra log-factor work the
binary searches and rotations add on top of a standard merge.

Lazy Stable Sort is filed among merge sorts, and it earns the "stable" half of its name
honestly: because every binary search in the merge step breaks ties in favor of whichever run is
being treated as the "left" side, equal elements originating from the first of two runs always
stay ahead of equal elements from the second, so the original relative order of equal elements is
always preserved. That stability claim has been verified separately in this repository with a
dedicated stability fuzz test, not just assumed from the name.
