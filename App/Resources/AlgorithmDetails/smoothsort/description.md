*From Wikipedia, the free encyclopedia*

Smoothsort, devised by [Edsger Dijkstra](https://en.wikipedia.org/wiki/Edsger_W._Dijkstra) in 1981, is a comparison
sort built on the same idea as [Heapsort](https://en.wikipedia.org/wiki/Heapsort) — repeatedly extract the largest
remaining value from a heap-shaped arrangement of the array — but with a heap shape designed to be much cheaper to
maintain when the input is already close to sorted. Ordinary heapsort's implicit heap always has a size one less than
a power of two, and every extraction pays a full logarithmic sift back down to a fixed-shape tree no matter how
orderly the data already was. [Smoothsort](https://en.wikipedia.org/wiki/Smoothsort) instead treats the array as a
sequence of adjacent sub-heaps whose sizes come from the *Leonardo numbers*, a Fibonacci-like sequence defined by
`L(0) = L(1) = 1` and `L(k) = L(k - 1) + L(k - 2) + 1`. Each sub-heap is itself shaped like a small binary heap sized
to a Leonardo number, and the run of sub-heaps covering the array so far is tracked with a compact bitmap recording
which sizes are currently present — the same binary-carry bookkeeping that appears in the bottom-up construction of
an ordinary heap, just generalized to a variable-width run of differently sized heaps instead of one fixed heap.

Building this structure up one element at a time mirrors ordinary heap construction: each new element either starts
its own trivial one-element sub-heap or, when two adjacent sub-heaps happen to be consecutive Leonardo sizes, merges
them into the next larger Leonardo-sized sub-heap, at which point a "sift" operation restores that single sub-heap's
internal heap order by walking the new root down toward whichever child is larger, exactly like an ordinary sift-down.
The more distinctive operation is "trinkle," which runs after a value has been swapped out of the front of the array
during the extraction phase: rather than restoring just one sub-heap, it walks backward across the *entire* remaining
run of sub-heaps, comparing the displaced value against each sub-heap's root in turn and stopping the moment it finds
one it doesn't need to disturb. On data that is already sorted or nearly so, that early stop happens almost
immediately, which is exactly why smoothsort is described as *adaptive*: its best-case running time is `O(n)`, better
than the `O(n log n)` best case of ordinary heapsort, while its worst case remains `O(n log n)` like any other
comparison sort bounded by that limit.

Smoothsort sorts in place using only a constant amount of extra bookkeeping beyond the array itself — the running
bitmap of sub-heap sizes and a handful of index variables — so, like heapsort, it needs no auxiliary array. Also like
heapsort, it is not a stable sort: both the sift and trinkle repair steps can freely swap equal elements past one
another while restoring heap order, so two equal elements are not guaranteed to keep their original relative
positions.
