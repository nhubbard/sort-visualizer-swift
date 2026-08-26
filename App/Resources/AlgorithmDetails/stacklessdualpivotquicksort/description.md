Stackless Dual-Pivot Quicksort is a variant of [Quicksort](https://en.wikipedia.org/wiki/Quicksort)
that sorts an entire array with a single loop instead of recursive calls — hence "stackless." Where
an ordinary quicksort recurses into each half (or, with two pivots, each third) of a partitioned
range, this variant processes the array as a sequence of segments from left to right, using two
plain integer cursors to track where the next unsorted segment begins and ends instead of a call
stack.

Before that loop starts, every element equal to the array's largest value is moved to the very end
in one pass. Those elements are already exactly where they belong relative to everything else, so
the rest of the algorithm can ignore them completely and treat the boundary in front of them as a
fixed wall it never has to sort past — and, as a side effect, that wall's position can later be
borrowed as scratch space (see below).

The main loop repeatedly partitions and shrinks the segment immediately to its left. Each
partitioning step samples two candidates roughly a third of the way in from either end of the
current segment, uses the larger as an upper cutoff and the smaller as a lower cutoff, and scans
the segment once, sending anything below the lower cutoff to the front and anything at or above the
upper cutoff to the back — an ordinary [dual-pivot](https://en.wikipedia.org/wiki/Quicksort#Dual-pivot_quicksort)
partition, just with the two cutoff values assigned to opposite ends of the range from where a
textbook description usually puts them. This repeats until the segment shrinks to two dozen
elements or fewer, small enough to finish with a plain [binary insertion
sort](https://en.wikipedia.org/wiki/Insertion_sort#Variants) instead of partitioning further.

Once a segment is fully sorted, the algorithm doesn't recurse into whatever comes next — it just
moves its left cursor past the segment and starts the same loop again on the remainder. A binary
search first finds how many elements immediately following the cursor are exact duplicates of the
value now sitting just behind it (the pivot most recently dropped into place); those duplicates are
already correctly positioned and get skipped as a single group rather than re-examined one at a
time, which matters most on inputs with only a few distinct values repeated many times over.

Each partitioning step ends by rotating the newly placed low pivot into the boundary immediately
outside the current segment — momentarily borrowing that position as a scratch slot for one value,
then immediately restoring whatever had been sitting there. Because that boundary is either the
fixed wall of largest-value elements found at the very start, or a pivot boundary left behind by a
previous segment's own partitioning, the value being displaced there for an instant is always one
this segment has already finished with, so the borrow never disturbs anything the algorithm still
needs.

Like other quicksort variants, this one is an in-place [comparison
sort](https://en.wikipedia.org/wiki/Comparison_sort) and is not
[stable](https://en.wikipedia.org/wiki/Sorting_algorithm#Stability): elements with equal values can
still cross paths during partitioning and end up in a different relative order than they started
in. Its average performance matches other well-tuned quicksort variants, and its worst case is
still O(n²) in principle, since no fixed sampling rule for choosing pivots can be made immune to
every adversarial input — but avoiding recursion means it never risks exhausting a call stack, no
matter how it's fed.
