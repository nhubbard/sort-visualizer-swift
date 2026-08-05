Poplar Heap Sort builds its heap not as a single tree spanning the whole array, the way an ordinary
heapsort does, but as a *run* of independent binary max-heaps — "poplars" — laid out side by side.
A poplar's size is always one less than a power of two (`1`, `3`, `7`, `15`, `31`, ...), the same
size a complete binary tree needs to have no partially-filled row, and the sizes of the poplars
covering an *n*-element array follow the binary representation of a running element count, the same
carrying pattern that shows up when adding numbers in binary: two poplars of matching size can
always be merged, together with one extra "spare" slot, into a single poplar exactly twice as big
plus one.

Below a threshold of 15 elements, a poplar has no real structural advantage over a plain sorted
run, so both the initial construction and any small leftover tail at the end fall back to ordinary
insertion sort. Above that threshold, construction proceeds in chunks: each new chunk of 15
elements is insertion-sorted in place, and then, following the binary-carry pattern, adjacent
poplars of equal size are merged upward into larger ones wherever the running chunk count's binary
representation calls for it — mirroring how carrying a `1` during binary addition cascades through
however many trailing `1` bits are already set.

Extraction repeatedly finds the *largest* root among the whole run of poplars — there are only
`O(log n)` of them at any moment — swaps it out to the current end of the array, and re-heapifies
just the one poplar that lost its root, exactly as an ordinary heapsort re-sifts after moving its
own root out of the way. Repeating this once per element gives `O(n log n)` time overall; both
phases work in place, needing only `O(1)` extra bookkeeping beyond the array itself. Poplar Heap
Sort is **not** a stable sort — like any heap-shaped structure, its swaps can freely reorder equal
elements relative to one another.
