*From Wikipedia, the free encyclopedia*

American flag sort is an in-place, most-significant-digit (MSD) radix sort. It takes its name from
an early formulation that split a collection into just three groups at each pass — conceptually
"red," "white," and "blue," after the stripes and canton of the American flag — before generalizing
the same idea to any number of buckets. Like other MSD radix sorts, it processes the most
significant digit of each key first and recurses into each resulting bucket to resolve the next
digit, but unlike a typical MSD radix sort, it never allocates a full auxiliary array to hold the
redistributed elements. Every element ends up in its correct bucket by being moved directly within
the original array.

The algorithm proceeds in two passes per digit. The first is an ordinary counting pass: it walks
the active range of the array once, tallying how many elements have each digit value. Those counts
are then turned into a table of starting offsets — one per digit value — that give the exact index
range each bucket will occupy once the elements are correctly placed, without ever moving anything
yet.

The second pass is what sets American flag sort apart from a plain counting-based radix sort: it
places every element into its bucket in place by following chains of displacement. To fill a
bucket's next open slot, the algorithm picks up whatever value already happens to be sitting there
and looks at *that* value's own digit. It then goes to the next open slot in *that* value's correct
bucket, and swaps in the value it displaces there, continuing the chain. Each step advances the
open-slot pointer for whichever bucket it just filled, so the chain never revisits a slot that has
already been finalized. Because every element belongs to exactly one bucket, this process traces
out a closed cycle: it must eventually return to the very slot it started from, at which point that
bucket's next element (if any remain unplaced) starts a new cycle. This is the same permutation
technique used by in-place cycle sorts, applied here bucket by bucket instead of element by element.

Once every element for the current digit has been placed into its bucket, each bucket's sub-range
is refined recursively using the next less significant digit, exactly as in any MSD radix sort.
Recursion for a given bucket stops once its digits are exhausted or once it shrinks to zero or one
elements, since a range that small is already sorted by definition.

Because the placement pass only ever needs the small, fixed-size count and offset tables — never a
second copy of the data being sorted — American flag sort's auxiliary memory use does not grow with
the size of the input, only with the number of buckets. This is its principal advantage over radix
sorts that redistribute elements into freshly allocated buckets on every pass. The trade-off is that
following displacement chains touches memory in a much less predictable pattern than copying
elements into contiguous per-bucket storage, and the order in which a chain revisits equal-valued
elements bears no particular relationship to their original order, so the algorithm is not stable.
For an input of `n` elements, `b` buckets, and `d` digit positions, the counting and placement work
at every level of recursion together visit each active element a constant number of times, giving a
running time of `O(d * (n + b))`.
