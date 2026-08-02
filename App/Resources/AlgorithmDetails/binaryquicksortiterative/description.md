Binary Quick Sort is a most-significant-bit-first radix sort dressed up as a quicksort: instead of
comparing whole values against a chosen pivot element, it partitions a range purely on one bit
position at a time. A Hoare-style partition walks two pointers toward each other from opposite
ends of the range, skipping past every element whose bit at the current position is already on
the correct side — clear on the left, set on the right — and swapping the pair of elements it
finds out of place whenever both pointers stop. Every value in the range ends up grouped into a
"bit clear" half and a "bit set" half, with no other ordering imposed within either half.

Once a range has been split on one bit, the same partitioning step is applied again separately to
each half using the next bit down, continuing until the bit position runs out or a range shrinks
to a single element. The starting bit is the position of the highest set bit in the largest value
in the array, found by shifting until nothing is left; anything above that bit is zero for every
element and would be a wasted pass. Because every element is examined bit by bit from the most
significant bit down, the whole array ends up fully sorted once the lowest bit has been processed
for every range.

This iterative folder drives that process without ever letting the algorithm recurse: each
partitioning step produces two new sub-ranges, and rather than calling itself on each one, the
algorithm pushes both onto the back of an explicit first-in-first-out queue of pending `(start,
end, bit)` tasks. A single loop repeatedly pulls the next task off the front of that queue,
partitions it if it still spans more than one element and there's a bit left to test, and pushes
its two children back on, continuing until the queue drains. The result is identical to the
recursive version, just processed breadth-first through an explicit queue instead of depth-first
through the call stack, so the algorithm never grows a call stack proportional to the number of
bits or sub-ranges being processed.

Binary Quick Sort is classified among the distribution sorts, since it groups elements by
examining a fixed piece of their representation (one bit) rather than by comparing whole values
against each other the way an ordinary quicksort does. It is not a stable sort: the Hoare
partition on a single bit has no tie-break for elements that are identical in every bit, so two
equal values can still be swapped past each other during partitioning and come out in the opposite
of their original relative order.
