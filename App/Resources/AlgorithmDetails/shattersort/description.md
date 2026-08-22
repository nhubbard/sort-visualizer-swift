Shatter Sort is a distribution sort: instead of comparing elements pairwise, it scatters the whole
range into buckets based on where each value falls, then cleans up whatever's left inside each
bucket. It starts by finding the smallest and largest values present in the array, which together
define the value span it's working with. That span is divided into a number of equal-width
buckets — enough that, on average, each bucket ends up holding about as many elements as the
caller's chosen bucket-size parameter — and every element is dropped into the bucket that matches
its position within that span: a value near the minimum lands in the first bucket, a value near
the maximum lands in the last one, and everything else falls somewhere in between. The array is
then rewritten by walking the buckets in order and writing out each one's contents in the order
the elements were originally encountered.

Because range-normalized bucketing spreads values out but doesn't guarantee that every bucket ends
up holding only one distinct value — duplicate-heavy or very wide-ranging inputs can easily land
several different values in the same bucket — Shatter Sort finishes with a plain insertion sort
over each bucket's own slice of the array. This backstop is what actually finishes the sort: the
bucketing pass alone only guarantees that every value in an earlier bucket is less than or equal
to every value in a later bucket, not that each bucket is internally sorted.

Shatter Sort is filed among the distribution sorts, alongside algorithms like counting sort,
pigeonhole sort, and flash sort, all of which trade comparisons for arithmetic on the values
themselves. It is a stable sort: which bucket an element lands in depends only on its own value,
so equal values always land in the same bucket and keep their original relative order once the
buckets are flattened back into the array, and the insertion-sort finish only ever moves an
element past ones that are strictly greater, so it never reorders equal elements either.
