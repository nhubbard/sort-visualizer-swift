*From Wikipedia, the free encyclopedia*

Improved Block Selection Merge Sort is a bottom-up merge sort that sorts entirely in place, without
ever allocating a second array to merge into. Like any bottom-up merge sort, it treats the array as
a sequence of already-sorted runs whose length starts at one element and doubles on every pass:
first it merges adjacent single elements into sorted pairs, then merges adjacent pairs into sorted
groups of four, and so on, until one pass merges the whole array as two halves. What sets this
algorithm apart is what happens immediately before each of those merges.

An ordinary in-place merge has to shift individual elements to make room for one another, and that
shifting is the expensive part of merging two runs without extra memory: in the worst case, an
element from the back of one run has to travel past every element of the other run to reach its
final position. Before running that expensive exact merge, this algorithm first runs a much cheaper
approximate pass over the same two runs. It divides each run into fixed-size blocks and performs a
selection sort on those blocks as whole units — comparing each block's representative element
(its first, or, when two blocks tie on that, its last) against the others, then swapping entire
blocks into place with a chain of element-by-element swaps rather than any shifting. Because a block
moves as a single unit, one comparison and one swap can relocate many elements at once, at a small
fraction of the cost a real merge would pay to move them individually. This coarse block-selection
pass runs at successively finer granularities — starting with blocks sized near the square root of
the run length, then re-deriving a smaller block size from that same square-root rule, and repeating
until the block size drops to sixteen elements or fewer. By the time the real, exact merge finally
runs, the two runs are already arranged in roughly the right order, so the element shifting the
merge still has to do only ever covers short distances, keeping the overall cost close to what an
ideal in-place merge sort could achieve.

The block-selection pass is also the reason this algorithm is not stable. Considered on its own, the
final merge step's comparisons are all strict "greater than" checks, which would ordinarily preserve
the relative order of equal elements — a hallmark of a stable merge. But by the time that merge
runs, the block-selection pass has already moved entire blocks of elements around, and it decides
which block goes first purely by comparing each block's representative element against another
block's. Two blocks whose representative elements happen to be equal can still be swapped as whole
units, and every element inside a swapped block — including ones that share a value with elements
still sitting in a different, not-yet-repositioned block — moves along with it. That reordering
happens at the block level, before the strict, otherwise order-preserving element-level merge ever
gets a chance to compare those elements directly. The net effect is that equal elements can and do
end up in a different relative order than they started in, even though no single step in the
algorithm's final merge phase ever looks unstable by itself.

Because every block move and every merge step operates by swapping or rotating elements already
inside the array, the algorithm needs no auxiliary buffer proportional to the input size, giving it
O(1) auxiliary space. Its running time is O(n log n) in the best, average, and worst cases alike:
the outer doubling structure guarantees O(log n) passes regardless of the input's initial order, and
within each pass the coarse block-selection work and the fine-grained merging work both stay linear
in the size of the array, so no particular arrangement of the input — sorted, reverse-sorted, or
random — changes the overall shape of the algorithm's cost.
