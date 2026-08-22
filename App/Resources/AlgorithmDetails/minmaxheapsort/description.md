Min-Max Heap Sort is a heap-based selection sort built on the
[min-max heap](https://en.wikipedia.org/wiki/Min-max_heap) (Atkinson, Sack, Santoro & Strothotte, 1986), a structure
that gets both the minimum *and* the maximum out of a single implicit array-backed tree at once. An ordinary binary
heap only enforces one invariant everywhere — every node is either always `<=` its children or always `>=` them — so
it only ever gives up one extreme value for free; finding the other one means a linear scan. A min-max heap instead
alternates which invariant applies from one level of the tree to the next: the root and every node at an even depth
must be less than or equal to *every* node beneath it, while every node at an odd depth must be greater than or equal
to everything beneath it. Because the root sits at depth zero, it's always the minimum. Because the maximum can never
live on a "less than or equal" level, it's forced down to depth one — meaning it's always sitting at one of the root's
two children, and finding it is just one comparison away.

Restoring that alternating invariant after a change is the one real twist compared to an ordinary heap's sift-down.
A node being pushed down has to compare itself not just against its two direct children, but against all four of its
grandchildren too — the grandchildren sit two levels down, which puts them back on the *same* kind of level (min or
max) as the node itself, so they're exactly where a same-direction violation would show up first. Whichever of those
up to six descendants is most extreme becomes the candidate: if it's a direct child, one comparison and at most one
swap settles things. If it's a grandchild, the value drops two levels in a single swap, and then the intermediate
node it jumped over gets one more check against its own now-closer neighbor, since a value that used to be a
harmless descendant of that node may have just become an immediate child that violates its rules. The process then
repeats from the grandchild's old position, so a badly-placed value can ride all the way down to a leaf, two levels
at a time.

Building the initial heap runs this operation bottom-up over every non-leaf index, same as any other heapsort. From
there, sorting is just repeated maximum-extraction: read off whichever of the root's (up to two) children holds the
larger value, swap it out to the current boundary of the shrinking heap, and push whatever landed at the vacated spot
back down to restore the invariant — extraction and repair together cost time proportional to the height of the tree,
which grows with the logarithm of the heap's size, the same as it would for an ordinary heap. Doing that once for
every element leaves the array sorted in ascending order using `O(n log n)` comparisons overall, with `heapify`
contributing a smaller `O(n)` term to the total, and needs nothing beyond a handful of index variables — no matter
how large the array gets, so the sort works in `O(1)` additional space, entirely in place.

Because the sort works by repeatedly relocating whichever value currently satisfies "most extreme," rather than by
tracking where equal values originally sat relative to one another, elements that compare equal can still end up
swapped past each other on the way down. Min-Max Heap Sort is therefore not a stable sort.
