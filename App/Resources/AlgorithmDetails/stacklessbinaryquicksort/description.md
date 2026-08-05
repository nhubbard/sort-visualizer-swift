Binary quicksort is a variant of quicksort that partitions elements according to the bits of their
keys rather than by comparing them against a chosen pivot value. Starting from the most significant
bit that any key in the array actually needs, every element is routed to one side of a partition or
the other depending on whether that bit is clear or set — elements with the bit clear move to the
left, elements with the bit set move to the right — using the same two-pointer, swap-in-place scan
an ordinary quicksort partition uses, just testing a bit instead of comparing against a pivot value.
Each of the two resulting halves is then partitioned again by the next bit down, and so on, until
either every bit has been consumed or a range has shrunk to a single element. Because every key is
split into a "bit clear" group and a "bit set" group at each level, and the two groups are always
fully separated once a bit has been used to distinguish them, the array ends up completely sorted
once the least significant bit has been processed. This makes binary quicksort equivalent to a
most-significant-bit-first binary radix sort, just phrased in the language of quicksort's in-place
partitioning step.

This variant reaches the same result without a call stack or an explicit list of pending ranges to
process. It keeps only a small, fixed amount of state: a pair of indices marking the start and end
of whichever range is currently active, the bit currently being partitioned on, and a running
counter. After partitioning the active range on the current bit, the algorithm always continues
immediately into that range's left half at the next bit down — a preorder, depth-first descent
through the same binary recursion tree an ordinary recursive binary quicksort would build with
function calls, just carried out with a pair of variables standing in for the call stack. When a
descent bottoms out at the lowest bit, the running counter is advanced and inspected one bit at a
time: each of its own low-order bits that is already set means that level of the tree has already
been fully visited on both sides, so the search keeps climbing until it reaches a level with an
unvisited right sibling still waiting. A short scan then widens the active range forward to pick up
every element that belongs to that sibling but was left outside the range when it was first carved
out, and the descent resumes from there, back down to the lowest bit.

The net result is identical to an ordinary recursive binary quicksort: a most-significant-bit-first
radix partition that fully sorts non-negative integer keys once every bit down to the least
significant one has been used to split the array. The difference is purely in how the recursion
tree is walked — no stack frame, work queue, or heap-allocated list of pending ranges ever grows
with the depth of the recursion, since the counter's own bit pattern carries enough information to
reconstruct which branch to visit next. Because the number of bits needed is proportional to the
logarithm of the largest key, and every element is touched a constant number of times at each bit
level, the running time is `O(n log n)` for keys of a size proportional to the number of elements
being sorted, matching ordinary quicksort's average case, though key distributions where most
elements share the same leading bits can still leave a level's partition badly unbalanced, the same
way an ordinary quicksort degrades when its pivot choices are poor. Like other partition-based
sorts, it is not stable — two equal keys that begin already in relative order can still be swapped
across a partition boundary during the bit scan.
