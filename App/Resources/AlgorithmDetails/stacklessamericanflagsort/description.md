American flag sort is a most-significant-digit radix sort that distributes elements into their
buckets in place, without allocating a separate output array the way a typical bucket-based radix
pass does. A single counting pass tallies how many elements fall into each digit bucket for the
current digit position, and those counts are turned into a starting offset for each bucket within
the range being sorted. Elements are then moved into place by following displacement cycles: the
algorithm picks up whichever value currently sits at a bucket's next free slot, writes it into the
free slot belonging to its own digit, picks up whatever value it just displaced, and keeps chasing
that value forward until the chain of displacements finally closes back on the slot it started
from. Repeating this for every bucket places every element from the current range into its correct
digit bucket, all within the original array. Once a digit has been fully distributed this way, each
bucket is a narrower range that can then be distributed again by the next digit down, the same way
an ordinary most-significant-digit radix sort recurses, until a digit place runs out or a bucket
has shrunk to a single element.

This variant reaches the same result without ever calling itself. Rather than recursing into each
bucket's sub-range and unwinding back out again, it walks the same conceptual recursion tree
iteratively using a small amount of state: a pair of numbers tracking the start and end of whatever
range is currently active, and a running digit place. After distributing a range, the algorithm
always steps immediately into that range's first bucket next, rather than working through the
buckets in array order — a preorder, depth-first descent, just with an explicit pair of counters
standing in for the call stack a recursive version would otherwise build up. When a descent finally
bottoms out because there is no digit place left to test, a separate counter that mirrors how many
bucket boundaries have already been fully walked is advanced and inspected to find the next sibling
bucket still waiting to be visited, climbing back up through however many levels have already been
exhausted before dropping back down into fresh, unvisited territory. A short scan then widens the
active range to catch every remaining element that belongs to that sibling but was never grouped
into it when the range was first split.

The net effect is identical to the ordinary recursive in-place radix distribution: every element
ends up sorted by comparing digit by digit from the most significant digit down. The difference is
that the traversal never grows a call stack proportional to the number of digit places or bucket
ranges involved — the same stack-free tree-walk trick that lets a most-significant-bit binary
partition sort avoid recursion generalizes cleanly here to an arbitrary number of buckets per
digit, instead of just two.

Like other digit-distribution sorts, this technique is not stable: cycle-following moves values by
leapfrogging them directly into their final slots rather than preserving encounter order, so two
elements with equal keys can still end up swapped relative to their original positions.
