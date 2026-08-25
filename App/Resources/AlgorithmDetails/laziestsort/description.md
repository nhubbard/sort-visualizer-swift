*From Wikipedia, the free encyclopedia*

Laziest Stable Sort is a stable merge sort, created by aphitorite, that sorts entirely in place:
it needs no second array of any size, unlike an ordinary [merge
sort](https://en.wikipedia.org/wiki/Merge_sort), which needs scratch space as large as the input
itself to combine two sorted runs. It reaches this by replacing every step a textbook merge would
normally hand off to a scratch buffer with a rotation performed directly on the array instead —
the "laziest" of the title refers to how little work the merge step does whenever it can get away
with leaving elements exactly where they already are.

The sort begins with a block pre-sort, the same idea an [optimized bottom-up merge
sort](https://en.wikipedia.org/wiki/Merge_sort) uses to skip its cheapest merge passes: the array
is split into consecutive blocks and each block is sorted independently with a [binary insertion
sort](https://en.wikipedia.org/wiki/Insertion_sort#Variants), which finds every element's
insertion point by binary search but always chooses the position just after any equal element
already placed, so it never moves one equal element ahead of another. The block size itself is
chosen adaptively — sixteen, or the integer square root of the whole array's length, whichever is
larger — so that on bigger inputs the pre-sort produces fewer, larger starting runs, which means
less work later for the merge phase to do. If the whole array is sixteen elements or smaller to
begin with, this single insertion-sort pass covers the entire array directly and the sort stops
there, since a merge phase would have nothing left to combine.

Once every block is sorted, the merge phase combines them back to front: the final block starts
out as the one sorted run already in place, and each step folds the block immediately before it
into that run, so the sorted region always grows from the point nearest the end of the array
backward toward the start. Merging a block into the run beside it walks one pointer through the
block's own not-yet-placed elements and a second pointer through the run's not-yet-consumed
elements. Whenever the block's current element is no larger than the run's, it is already exactly
where the final sorted order needs it, and the block's pointer simply advances past it without
moving anything. Whenever the block's current element is strictly larger, every run element up to
some point must be smaller than it and needs to end up first — an [exponential
search](https://en.wikipedia.org/wiki/Exponential_search), also called a galloping search, finds
that boundary by doubling its step size until it overshoots and then narrowing the overshoot with
an ordinary binary search, confined to only the part of the run not yet consumed rather than the
whole array. Once the boundary is found, the two neighboring stretches — the block's remaining
elements and the smaller run elements just found — are swapped end for end in a single rotation,
which moves the whole smaller stretch ahead of the block's remainder in one operation rather than
shifting each of its elements into place individually.

A rotation of two adjacent stretches is itself done without any second array, by repeatedly
swapping the smaller of the two stretches whole against an equal-sized piece of the other; that
swap always finishes off one of the two remaining pieces completely, leaving a smaller version of
the same two-stretch problem behind, until eventually one piece shrinks to nothing and the
rotation is done.

Because the block pre-sort never places an element ahead of one that compares equal to it, and the
merge phase only ever moves elements in response to a strictly-greater comparison, never a tied
one, Laziest Stable Sort never reorders two elements that started out equal — making it a stable
[comparison sort](https://en.wikipedia.org/wiki/Comparison_sort). Its time complexity is
[O(n log n)](https://en.wikipedia.org/wiki/Time_complexity), and because every merge step moves
data by rotating the array in place rather than copying it into a second buffer, it needs no
auxiliary array at all — a genuinely in-place bound that most merge sort variants, which trade
rotations for the simplicity of a full-sized scratch buffer, don't share.
