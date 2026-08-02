Twin Sort is an adaptive bottom-up merge sort by Igor van den Hoven. It works in two phases: a
run-detection pre-pass that walks the array looking for descending pairs, and a merge phase that
combines the runs left behind by that pre-pass. Ascending pairs are skipped two at a time without
being touched, while a descending pair marks the start of a run that's tracked until it turns back
upward, then reversed in place so the whole stretch becomes ascending. If that tracking ever runs
off the end of the array and the entire range turns out to have been one single descending run, the
algorithm reverses it and returns immediately, skipping the merge phase altogether — for already
reverse-sorted or nearly reverse-sorted input, this makes the whole sort a single linear pass.

Assuming the array wasn't just one big reversed run, the second phase is a bottom-up merge that
doubles its block size on every pass, starting from pairs of single runs and working up until one
pass covers the whole array. Unlike a textbook merge sort, it merges each pair of blocks from their
tail ends inward rather than from their heads outward: it copies the right-hand block into a scratch
buffer, then walks backward from the last elements of both the left block and the buffered right
block, writing the larger of the two into the back of the destination range on each step. A pair of
blocks that's already fully in order relative to each other is detected with a single comparison of
their boundary elements and skipped without doing any merge work at all, and a partially-overlapping
tail is trimmed before the copy so the buffer only ever needs to hold half of the elements being
merged rather than a full copy of the array. That scratch buffer, sized to half the input, is
allocated once up front and reused across every pass of the merge.

Twin Sort belongs with ArrayV's merge sorts: every comparison-driven step is a movement of whole
runs or blocks that were already known to be internally sorted, never a value swapped past an
unrelated value the way a partitioning or exchange sort would. It is a genuinely stable sort. The
run-detection phase only ever reverses strictly-decreasing runs — a run that included a tie would
have stopped at the tie, since a tie fails the "descending" test — so reversal never crosses two
equal elements past each other. The merge phase's tail-inward comparisons consistently favor
whichever element came from the position that preserves encounter order, so equal elements are
never swapped out of their original relative order there either. This was confirmed in this
codebase by simulating the algorithm with a parallel array of original indices carried alongside the
values and checking that indices of equal-valued elements never invert.
