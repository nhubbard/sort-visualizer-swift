Buffered Stooge Sort belongs to the same family as Stooge sort — a recursive algorithm whose
combining step relies on dividing a range into thirds rather than halves — but replaces Stooge
sort's "sort the first two-thirds, then the last two-thirds, then the first two-thirds again"
pattern with a genuine merge step, using part of the array itself as scratch space instead of a
separate buffer.

Given a range to sort, the algorithm first swaps the two endpoints if a range of exactly two
elements is out of order. For a larger range, it splits into three roughly equal parts, sorts the
middle and final thirds recursively, and then merges those two already-sorted runs together using
a two-pointer walk: whichever run currently holds the smaller of its two leading elements gets that
element copied into the next open slot, starting from the range's own first third — the "buffer"
in the name, since that stretch of the array is being overwritten with the merge's output rather
than being read as meaningful data anymore. Once the middle and final thirds have been fully merged
into the first two-thirds of the range, the algorithm recursively sorts the final third all over
again — its own values were consumed as source material for the merge, not preserved as a finished
answer — before a closing pass of adjacent swaps, working inward from both ends of the whole range,
reconciles the freshly-merged prefix with the freshly-re-sorted final third into one fully ordered
sequence.

Getting the exact split points requires rounding one-third and two-thirds of the range's width
*upward*, the same subtlety plain Stooge sort's own two-thirds split depends on — an off-by-one
here can misdivide the recursion on certain range widths without necessarily producing an
obviously wrong result. Every comparison in this algorithm only ever decides which of two elements
gets copied next, never allowing one to jump over an equal element without displacing it in a way
that would change their relative order, so equal elements keep their original order and the sort is
stable. Its unusual recursive shape — recursing into a two-thirds-sized range twice (once via the
merge, once via the direct re-sort) alongside a one-third-sized range once — lands on the same O(n²)
growth as an ordinary quadratic sort, despite superficially resembling the much worse O(n^2.71) of
plain Stooge sort.
