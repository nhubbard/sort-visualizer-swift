Index Sort, also known as Simple Static Sort, is a special-case sorting technique that only works
on one specific kind of input: an array that already holds every integer from some minimum value
up to `minimum + n - 1` exactly once, in some order. Under that condition, a value doesn't need to
be compared against anything else to know where it belongs — subtracting the array's minimum from
a value gives the exact index it should occupy.

The algorithm walks the array from left to right. At each position, it keeps swapping whatever
value currently sits there into the position that value's own index formula names, until the
position finally holds the value it's supposed to hold. Every such swap places at least one value
into its permanent final position for good — the value that used to occupy the target slot is,
by construction, exactly the value the current position needs — so the whole array finishes
sorting in at most `n - 1` swaps total, not per position. That makes Index Sort's real running
time linear in the number of elements, dramatically faster than any comparison-based sort, but
only because it is solving a much narrower problem than general sorting: it has no way to handle
an array that is missing a value, contains a duplicate, or holds anything outside its expected
contiguous range.

Because a swap can place a value many positions away in a single step, Index Sort makes no attempt
to preserve the relative order of equal elements — though the question is moot in practice, since
its own precondition (every value in the range appears exactly once) never gives it any equal
elements to reorder in the first place.
