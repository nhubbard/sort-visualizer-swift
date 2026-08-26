Stackless Hybrid Quicksort is a variant of [Quicksort](https://en.wikipedia.org/wiki/Quicksort)
that sorts an entire array with a single loop instead of recursive calls — hence "stackless." Where
an ordinary quicksort recurses into each side of a partitioned range, this variant processes the
array as a sequence of segments from left to right, using two plain integer cursors to track where
the next unsorted segment begins and ends instead of a call stack.

Before that loop starts, every element equal to the array's largest value is moved to the very end
in one pass. Those elements are already exactly where they belong relative to everything else, so
the rest of the algorithm can ignore them completely and treat the boundary in front of them as a
fixed wall it never has to sort past.

The main loop repeatedly partitions and shrinks the segment immediately to its left. Each pivot is
chosen by [median-of-three](https://en.wikipedia.org/wiki/Quicksort#Choice_of_pivot) selection — the
first, middle, and last elements of the current segment are rearranged so their median value ends
up at the front — then a classic two-pointer [Hoare
partition](https://en.wikipedia.org/wiki/Quicksort#Hoare_partition_scheme) splits the rest of the
segment around it: one pointer advances from the left until it finds something at least as large as
the pivot, the other retreats from the right until it finds something smaller, the two are swapped,
and this repeats until the pointers meet. This continues until a segment shrinks to sixteen elements
or fewer, small enough to finish with a plain [binary insertion
sort](https://en.wikipedia.org/wiki/Insertion_sort#Variants) instead of partitioning further.

Once the pivot lands in its final position, it gets swapped out to the fixed boundary at the far end
of the region this pass of the algorithm is responsible for — the wall of largest-value elements
found at the very start, or a pivot boundary left behind by an earlier segment's own partitioning.
Whatever was sitting at that boundary moves into the pivot's old spot instead. Because that boundary
position always holds a value already known to belong at or after everything in the current
segment, swapping it in doesn't disturb the ordering the algorithm is building — it simply gives the
just-placed pivot a permanent resting place outside the region still being sorted, without needing a
call stack to remember to come back to it later.

Once a segment is fully sorted, the algorithm doesn't recurse into whatever comes next — it just
moves its left cursor past the segment and starts the same loop again on the remainder. A binary
search first finds how many elements immediately following the cursor are exact duplicates of the
value now sitting just behind it (the pivot most recently dropped into place); those duplicates are
already correctly positioned and get skipped as a single group rather than re-examined one at a
time, which matters most on inputs with only a few distinct values repeated many times over. A small
flag tracks whether the upcoming median-of-three selection should be given a fresh third candidate
or reuse ones already known to be tied to each other, avoiding a pointless repeat comparison.

Like other quicksort variants, this one is an in-place [comparison
sort](https://en.wikipedia.org/wiki/Comparison_sort) and is not
[stable](https://en.wikipedia.org/wiki/Sorting_algorithm#Stability): elements with equal values can
still cross paths during partitioning and end up in a different relative order than they started
in. Median-of-three selection makes the classic already-sorted or reverse-sorted worst case far less
likely to occur by accident than a fixed-position pivot choice would, though a deliberately
adversarial input can still force O(n²) behavior — but avoiding recursion means it never risks
exhausting a call stack, no matter how it's fed.
