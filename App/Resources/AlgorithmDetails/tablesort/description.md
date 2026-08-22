Table Sort is a median-of-three quicksort dressed up so that it never actually moves the array
being sorted until the very last step. Instead of partitioning and swapping the real elements, it
builds a separate table of indices — one entry per array position, initialized so `table[i]`
starts out equal to `i` — and quicksorts that table instead. Every comparison the partitioning
logic makes looks up `array[table[a]]` and `array[table[b]]` rather than `array[a]` and `array[b]`
directly, so all the pivot selection, partitioning, and recursive splitting happens purely in
terms of index bookkeeping. By the time the recursion bottoms out, `table` holds a permutation
that, if applied to the original array, would put it in sorted order.

That permutation is applied in a single closing pass rather than through any of the swaps that
happened during partitioning. For each position whose table entry doesn't already point to
itself, the algorithm follows the chain of indices it belongs to — a permutation cycle — swapping
each element directly with the one that belongs in its place as it walks around the cycle, until
it arrives back where it started. Because a cycle of length k is closed by exactly k - 1 swaps,
every array element still ends up in its final resting place using far fewer swaps than an
ordinary in-place quicksort would need for the same rearrangement.

Because comparisons break ties by falling back to the compared table entries' original index
order rather than treating equal elements as interchangeable, Table Sort preserves the relative
order of equal elements and is a genuinely stable sort, despite being built on the same
partitioning shape as an unstable in-place quicksort. The underlying algorithm is still
fundamentally a comparison-and-swap partitioning scheme — it's just the table of indices being
exchanged instead of the array's own contents, until the very last pass applies that exchange to
the real data.
