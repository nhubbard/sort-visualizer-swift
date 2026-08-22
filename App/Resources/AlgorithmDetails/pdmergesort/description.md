Pattern-defeating merge sort belongs to the family of **natural merge sorts**: variants of ordinary
merge sort that first look for order already present in the input, rather than blindly splitting the
array in half regardless of its contents. Real-world data is very often partially sorted — nearly
sorted logs, a handful of out-of-place records, or the concatenation of several already-sorted
batches — and a sort that recognizes and reuses that existing order can finish in a single linear
pass instead of paying for a full divide-and-conquer from scratch every time.
[Timsort](https://en.wikipedia.org/wiki/Timsort), the hybrid sort used by several mainstream language
runtimes, is built on this same underlying idea of detecting runs of existing order and merging them.

A **run**, here, is a maximal stretch of the array where every adjacent pair of elements steps in the
same direction: either every step is non-decreasing, or every step is strictly decreasing. A single
left-to-right scan of the array finds every one of these maximal runs. Whenever a run turns out to be
descending, it is reversed in place before moving on — an O(k) operation for a run of length k — which
turns it into an ascending run without disturbing any other run's boundaries. This scan produces a
list of run-boundary indices: an array that is already fully sorted collapses to exactly one run
spanning the whole array, while a fully shuffled array degenerates to as many runs as elements, one
per position, matching an ordinary merge sort's starting point.

Once every run has been identified, the algorithm repeatedly walks the boundary list, merges each
adjacent pair of runs into one larger sorted run, and then compacts the list down to just the
surviving run starts. This halves the number of runs on every pass, exactly like the merge phase of an
ordinary bottom-up [merge sort](https://en.wikipedia.org/wiki/Merge_sort) — except it starts from
however many runs the input actually contains instead of always starting from one run per element.
Each individual merge copies only the smaller of its two runs into a scratch buffer — at most half of
the two runs' combined length — and merges that buffer against the untouched larger run back into the
original array, either forward from the low end or backward from the high end, whichever direction
needs the smaller copy. This keeps the extra memory the algorithm needs proportional to the size of
the array rather than to the number of runs.

Because the number of passes needed depends on the logarithm of the *run count* rather than the
logarithm of the element count, an input that arrives as one or a few long runs finishes far faster
than a plain merge sort would. In the best case — the input is already sorted, or sorted in one long
descending stretch that a single reversal fixes — the run-finding scan discovers just one run and the
merge loop never executes at all, giving a genuine **O(n)** best case. In the worst case, where no two
adjacent elements share a direction, every run is a single element and the algorithm falls back to the
same **O(n log n)** behavior as an ordinary merge sort, which is also its average case. The scratch
buffer used while merging is never larger than half the array, so the algorithm uses **O(n)**
auxiliary space overall, and careful tie-breaking during both the forward and backward merge keeps it
stable: equal elements keep their original relative order.
