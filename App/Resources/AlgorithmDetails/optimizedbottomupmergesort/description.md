*From Wikipedia, the free encyclopedia*

Optimized Bottom-Up Merge Sort is Sartaj Sahni's iterative merge sort, the same style of
algorithm the C++ standard library's `std::stable_sort` is modeled on. Like plain
[bottom-up merge sort](https://en.wikipedia.org/wiki/Merge_sort), it never recurses — it builds
progressively longer sorted runs by repeatedly merging adjacent pairs of them — but it adds two
refinements that a textbook bottom-up merge sort skips.

The first is a pre-pass that never touches merging at all. Rather than starting from runs of a
single element, as a plain bottom-up merge sort would, the array is first split into fixed-size
blocks of sixteen elements, and each block is sorted independently with a [binary insertion
sort](https://en.wikipedia.org/wiki/Insertion_sort#Variants): every element still finds its
insertion point by binary search instead of a linear scan, but the point it finds is always the
first index holding a value no smaller than itself, so an element is never moved ahead of one that
already compares equal to it — this is what keeps the whole sort stable. Once every block is
internally sorted, the merge phase starts from runs of sixteen already-ordered elements instead of
one, which skips exactly the first four merge passes a plain bottom-up merge sort would otherwise
spend re-deriving what a cheap insertion sort already produced at that scale — merging sixteen
runs of one element into eight runs of two, then four of four, then two of eight, then one of
sixteen, all by comparisons alone, is far more expensive than sorting each block of sixteen
directly.

The second refinement is how the merge phase manages its scratch space. A single auxiliary buffer,
the same size as the input, is allocated once up front, and each merge pass alternates which side
holds the current data: one pass merges every adjacent pair of runs from the main array into the
scratch buffer, doubling the run length, and the next pass merges back from the scratch buffer into
the main array, doubling again. Passes are always evaluated in this alternating order, one
direction and then the other, which is what makes the very last pass's home buffer predictable from
nothing but a count of how many passes ran — an even number of passes lands the fully sorted result
back in the main array on its own, while an odd number leaves it sitting in the scratch buffer
instead, needing one explicit copy back at the very end to put it where the caller expects it. A
naive implementation that always merges into scratch and then unconditionally copies the whole
buffer back after every pass gets the same result, but at the cost of an extra full-array copy on
every single pass rather than, at most, one.

Whenever a pass's final pair of runs doesn't divide evenly — the array length isn't a clean
multiple of the current run size — the leftover is handled the same way a plain bottom-up merge
sort handles it: a leftover shorter than a full run is merged together with the run right before
it (a merge naturally tolerates its second run being shorter than its first), and a leftover that
is already one complete, sorted run with nothing left to pair it against is simply carried forward
to the next pass untouched, since there is nothing to merge it with yet.

If the whole input has fewer than sixteen elements to begin with, the merge phase never runs at
all — the binary insertion pre-pass sorts the entire array directly, since a merge phase would have
nothing left to do once its single starting run already spans everything.

Because binary insertion sort never reorders equal elements and every merge favors its left run on
a tie, Optimized Bottom-Up Merge Sort is a stable [comparison
sort](https://en.wikipedia.org/wiki/Comparison_sort). Its time complexity is
[O(n log n)](https://en.wikipedia.org/wiki/Time_complexity) in the best, average, and worst case
alike — nothing about it shortcuts based on the data's shape — and it needs O(n) auxiliary space
for its one scratch buffer, the same bound a plain bottom-up merge sort needs, just used more
efficiently.
