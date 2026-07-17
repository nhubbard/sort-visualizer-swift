*From Wikipedia, the free encyclopedia*

Static Sort is a distribution sorting algorithm that classifies every element into one of as many buckets as there are
elements to sort, using a single linear formula based on where each element's value falls between the smallest and
largest values present. Unlike [Counting Sort](https://en.wikipedia.org/wiki/Counting_sort), whose bucket count is tied
to the size of the input's value range, Static Sort always allocates exactly `n` buckets regardless of how wide or
narrow that range is — hence "static": the bucket layout is fixed by the element count alone, decided once up front
rather than adapted to the data.

The algorithm proceeds in three stages. First, it scans the input once to find the minimum and maximum values present,
then tallies how many elements classify into each bucket and turns those tallies into cumulative boundaries, the same
running-total technique Counting Sort and Flash Sort both use to know exactly which slice of the array each bucket owns.
Second, it permutes every element into its bucket's boundary in a single in-place pass: each out-of-place element is
evicted from its current slot, dropped into its bucket's next free slot, and whatever value already occupied that slot
is evicted in turn, with the chain of displacements followed until it loops back to where it started. This is the same
eviction-and-placement idea used by [Cycle Sort](https://en.wikipedia.org/wiki/Cycle_sort) and Flash Sort, adapted here
to use two arrays — one holding each bucket's remaining count, the other its next write position — as shrinking
per-bucket cursors instead of a single shared scan.

Once every element sits inside its own bucket's contiguous region, the array is sorted *by bucket* but not yet sorted
overall — the classification formula can only guarantee non-decreasing bucket membership, not that individual elements
sharing a bucket land in order. A short finishing pass tidies up each bucket's own small amount of leftover disorder:
buckets small enough that comparison overhead outweighs quadratic cost are finished with Insertion Sort, while larger
buckets are finished with Heap Sort, whose guaranteed `O(k log k)` behavior on a single oversized bucket prevents a
skewed input from degrading the whole sort as badly as Insertion Sort alone would.

Because the number of buckets scales with the element count rather than the value range, Static Sort avoids the
potentially huge memory footprint Counting Sort or Pigeonhole Sort would need on a widely spread input, at the cost of
needing an explicit finishing sort within each bucket. When values are close to uniformly distributed across the input's
range, each bucket ends up holding very few elements, the finishing passes stay cheap, and the whole sort runs close to
linear time. Heavily skewed or clustered distributions can leave a small number of buckets holding most of the elements,
pushing the cost of finishing those buckets — and therefore the sort as a whole — toward the worst case of whichever
finishing algorithm handles them.
