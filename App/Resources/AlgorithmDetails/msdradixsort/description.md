*From Wikipedia, the free encyclopedia*

Most-significant-digit (MSD) radix sort is a non-[comparative](https://en.wikipedia.org/wiki/Comparison_sort) sorting
algorithm that, like its LSD counterpart, distributes elements into buckets according to their digits rather than
comparing them directly. Where LSD (least-significant-digit) radix sort processes digits from the last to the first in a
single non-recursive pass per digit, MSD radix sort processes digits from the first to the last and recurses: after
bucketing a range of the array by its current digit, each bucket is itself split further by the next digit, and so on
until either a single digit is left to consider or a bucket has shrunk to at most one element.

This most-significant-first order gives MSD radix sort a property LSD radix sort lacks: once two keys differ in an
earlier digit, they are already correctly ordered relative to each other and never need to be revisited, so a bucket
that has already been fully distinguished from its neighbors can stop recursing early. The trade-off is bookkeeping — a
fresh set of buckets (and their offsets into the array) must be tracked at every level of recursion, and because buckets
are processed and recursed into independently, care must be taken to distribute elements into each bucket in the order
they were encountered so that equal keys retain their relative order and the sort remains stable.

MSD radix sort is also naturally suited to variable-length keys, such as strings, since a bucket with no remaining
digits is finished before a bucket that still has more digits to examine, unlike LSD radix sort, which needs every key
padded or otherwise handled explicitly to a common length before it can begin.
