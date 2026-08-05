Stackless Rotate Merge Sort is an in-place variant of [Merge Sort](https://en.wikipedia.org/wiki/Merge_sort)
that never allocates an auxiliary buffer and never recurses — every pass over the array is a plain
loop over doubling block widths, so no call stack (real or simulated) ever needs to grow past a
handful of frames. Like other in-place merge techniques, it replaces the classic merge step —
copying the smaller of two leading elements into a scratch array until one run is exhausted — with a
**block rotation**: swapping one contiguous span of elements with an adjacent span of a different
length until the two spans have traded places. A rotation of two adjacent blocks is itself built
without extra storage, by repeatedly swapping the smaller of the two blocks with an equal-sized
slice of the larger one and shrinking whichever block was just fully consumed, until one side runs
out.

The sort begins by presorting every adjacent pair, which is the same as saying it treats the array
as a row of already-sorted runs of length one and merges neighboring pairs of them into sorted runs
of length two. From there it works through doubling block widths — `2`, `4`, `8`, `16`, and so on —
and at each width `j` walks the array in strides of `2j`, treating each stride as two adjacent
sorted runs of length `j` that need to become one sorted run of length `2j`.

Locating where those two runs interleave is done with a technique sometimes called a **merge path**
or **co-rank** search: rather than asking "where does this particular value belong in the other
run?" (an ordinary binary search by value, the kind used in a textbook in-place merge), it asks "how
many elements from each run, taken from the front of one and the back of the other, add up to
exactly the `c` smallest elements of the combined run?" Concretely, to select the `c` smallest
elements out of two sorted runs of length `lenA` and `lenB`, the search tries a candidate split
count `r` — take `r` elements from the tail of one run and `c - r` from the head of the other — and
compares the two elements sitting at that boundary. If the element about to be included from one
side is larger than the element about to be excluded from the other, the split has taken too much
from the first side, so the search narrows toward a smaller `r`; otherwise it narrows toward a
larger one. Because the search only ever needs to try a split whose `r` is between `max(0, c -
lenB)` and `min(c, lenA)` — a split can never demand more elements than one run has to give, or
fewer than are needed once the other run is exhausted — it runs over whichever of the two runs is
shorter, keeping every individual search to `O(log(min(lenA, lenB)))` comparisons. Once the split
point is found, a single rotation moves the selected elements into place, with the correct relative
order of equal elements preserved by biasing the comparison toward whichever run started further to
the left — which is what keeps the sort stable.

A single rotation per block-pair is enough to put the *smallest* `j` elements of the combined `2j`
run in front, but it does not finish the merge: each resulting half can still contain one internal
seam, the point where a run that used to start at the very beginning of the block now picks up in
the middle of it. A second pass, working at successively finer granularities (`j / 2`, `j / 4`, and
so on down to `2`), scans for exactly that seam — the first place where ascending order breaks — and
repairs it with the same merge-path rotation, now selecting a smaller count for a smaller
sub-problem. By the time this finer pass reaches a granularity of `2`, only isolated adjacent pairs
can still be out of order, so a last pairwise-swap sweep — the same presorting step the sort started
with — cleans up whatever the coarser passes left behind.

Every element still only moves a bounded number of times as it works its way from its starting run
up through the doubling block widths to its final position, the same accounting that gives an
ordinary merge sort its running time, so Stackless Rotate Merge Sort keeps the familiar `O(n log n)`
time bound in the best, average, and worst case. Because it never copies data into a second array —
every rearrangement is a swap between two positions already inside the input — its auxiliary space
use is `O(1)`, and because its merge step is stable by construction, so is the sort as a whole.
