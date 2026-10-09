Fifth merge sort is a stable [merge sort](https://en.wikipedia.org/wiki/Merge_sort) variant that
divides the array into five runs. It sorts each run, then combines pairs of the four equal-sized
runs into the space vacated by the first run. A backward merge combines those two results from the
end of the array. The saved first run is merged back from an external buffer to complete the sort.

The first run contains the remainder when the length is not divisible by five, so the external
buffer holds about one fifth of the array. Forward merges choose the left run when keys compare
equal. The backward merge chooses the right run on equal keys because it writes from right to
left. These choices retain the original order of equal elements.

Fifth merge sort takes **O(n log n)** time in the best, average, and worst cases. Its external
buffer uses **O(n)** auxiliary space. The reference implementations use a direct five-way merge
with a scratch array; this expresses the same five-run division and stability rule with less
language-specific index manipulation.
