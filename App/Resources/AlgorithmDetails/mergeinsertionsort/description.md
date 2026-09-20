*From Wikipedia, the free encyclopedia*

Merge-insertion sort, also known as the Ford-Johnson algorithm after its 1959 discoverers, is a
comparison sort built to minimize the number of comparisons it performs rather than to minimize
running time. For decades it held the record for the fewest comparisons needed to sort small
arrays in the worst case, and it remains the standard example used to show that comparison sorts
can, with enough care, get closer to the
[information-theoretic lower bound](https://en.wikipedia.org/wiki/Comparison_sort) of
log₂(n!) comparisons than a naive merge sort or quicksort ever will.

The algorithm starts by pairing up adjacent elements and comparing each pair, sorting every pair
into a smaller half and a larger half. The larger elements form a "chain," which is recursively
sorted the same way, while the smaller elements are set aside as a "pending" list, each one still
remembering which chain element it was originally paired with. Once the chain comes back fully
sorted from the recursive call, one pending element can be placed for free: the one paired with
the smallest chain element is guaranteed to be smaller than every other chain element too, so it
is simply placed at the front of the sequence with no comparison needed.

Every other pending element still has to be merged into the growing sorted sequence, and this is
where the algorithm earns its reputation: rather than inserting them in a straightforward
left-to-right order, it inserts them following the Jacobsthal numbers — 1, 3, 5, 11, 21, 43, and
so on, each roughly double the one before — which determines both the order pending elements are
handled in and how large a slice of the sequence each one's binary search needs to cover. A
pending element never has to be compared against part of the sequence that is already known, from
the pairing step, to be larger than it. Choosing this particular ordering, rather than any other,
is what keeps the total comparison count of the whole sort as close to optimal as possible; a
plain left-to-right binary insertion would still finish correctly, just with a few more
comparisons along the way.

Because pairing and chain-building can freely reorder equal elements relative to each other,
merge-insertion sort is not a stable sort. Its comparison count is close to the theoretical
optimum, but that economy comes from the bookkeeping of pending elements and chain partners, not
from a low-overhead inner loop, so it is mostly of theoretical and educational interest today: on
real hardware, its constant-factor overhead and heavy use of extra bookkeeping make it slower in
practice than simpler
[O(n log n)](https://en.wikipedia.org/wiki/Comparison_sort) sorts for anything but small arrays,
even though its comparison count is smaller.
