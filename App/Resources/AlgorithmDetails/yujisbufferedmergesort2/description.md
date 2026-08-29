*From Wikipedia, the free encyclopedia*

Yuji's Buffered Merge Sort 2 is a recursive, in-place merge sort that never allocates a second
array to hold the values it is merging. Ordinary merge sort needs somewhere to put the combined
result while it is still reading from both halves it is merging, which is normally solved by
allocating an auxiliary buffer the size of the whole array. This algorithm instead carves that
buffer out of the very range it is sorting: at each level of recursion, it sets aside the upper
portion of the current range, sorts that portion first using an entirely separate iterative
routine, and then treats the now-sorted portion as a temporary buffer for merging the rest of the
range into place. Because the "buffer" is just part of the array wearing a different hat for a
while, and every element that moves into or out of it does so through a swap rather than an
overwrite, no element's value is ever discarded before something has taken its place, and no
second array is ever needed. This keeps the space complexity at O(1): only a small, fixed amount
of index bookkeeping accompanies the array itself, no matter how large the input.

Small ranges of sixteen elements or fewer are sorted directly with a binary insertion sort, which
also seeds every merge pass at the bottom of the recursion: each run of sixteen is put in order
this way before any merging begins. Above that size, the algorithm recursively splits its working
range roughly in half, builds a sorted buffer out of the upper portion, sorts the lower portion
by recursing into itself, and merges the two together using swaps instead of overwrites, so that
by the time the merge finishes, both the buffer region and the main region have traded places
correctly without any element ever being lost.

The merging itself alternates between two different strategies. The straightforward one walks
through the buffer and the remaining unsorted region side by side, comparing one element from
each at a time and swapping whichever is smaller into place, advancing one step at a time exactly
like a textbook merge. The second strategy, used once the buffer has grown large enough relative
to the region it is merging into, is a galloping merge: instead of comparing the next buffered
value against just the next unmerged value, it uses binary search to jump directly to the point
in the unmerged region where the buffered value belongs, moving every element in between into
place in one pass rather than one comparison at a time. This tends to pay off exactly when the
buffer side is relatively large, since a single binary search can then settle what would otherwise
take many one-at-a-time comparisons to resolve. Deciding which of the two strategies to use, and
which of two fixed memory offsets should be treated as the "active" region at each pass of the
buffer-building step, are both handled with compact bitwise arithmetic (a bitwise XOR that toggles
between exactly two known values) rather than an explicit branch, which keeps the bookkeeping
cheap without changing what the algorithm actually computes.

Because the algorithm always performs the same sequence of splits, buffer-building passes, and
merges regardless of how the input happens to be arranged, its running time does not depend on the
input's initial order: best, average, and worst case are all O(n log n). It is not stable,
however. The galloping merge breaks ties in favor of the buffer side whenever a buffered value is
equal to the next unmerged value, and that buffer was itself assembled by an earlier pass over
elements that originally came from both sides of the current split. An element that started out
after an equal element, but happened to land in the buffer while an equal element from the other
side did not, can therefore be swapped into the output ahead of it, so two equal elements are not
guaranteed to keep their original relative order.
