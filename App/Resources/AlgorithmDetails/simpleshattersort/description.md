Simple Shatter Sort is a variant of Shatter Sort that runs the same range-normalized bucketing
pass several times instead of once, at progressively finer granularity, before doing the final
cleanup. Each pass finds the current minimum and maximum of the whole array, splits that span into
buckets sized by a shrinking divisor, and rewrites the array bucket by bucket, just like a single
Shatter Sort bucketing pass would. The divisor starts at the caller's chosen bucket-size parameter
and is repeatedly divided by a fixed rate until it drops to 1, at which point one last bucketing
pass is done with each element effectively getting its own narrow slot.

Repeating the bucketing pass doesn't change what the algorithm is fundamentally capable of — a
single sufficiently fine bucketing pass followed by an insertion-sort finish would already produce
a correct result, exactly as it does in Shatter Sort. What repeated bucketing buys is a head start
for that final finish: each pass narrows the spread of values sharing a bucket, so by the time the
last bucketing pass and the insertion-sort backstop run, there's less local disorder left to clean
up. It's a performance refinement layered on top of the same core distribution-sort idea, not a
correctness requirement — the insertion sort at the end is still what actually guarantees every
bucket ends up sorted.

Like Shatter Sort, Simple Shatter Sort is categorized as a distribution sort and is stable: every
bucketing pass places an element based only on its own value relative to the current min/max span,
so equal values always travel through the same sequence of buckets together and come out
flattened in their original relative order, and the concluding insertion sort never swaps two
equal elements past each other.
