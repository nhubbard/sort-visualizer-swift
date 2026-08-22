Lazy Heap Sort isn't actually built on a heap, despite the name — it's a sqrt-decomposition selection sort. The array is
divided into blocks of roughly `√n` elements each; every block's maximum is moved to the front of that block in one
pass, so there are now `√n` "candidate" maxima sitting at fixed positions. The main loop repeatedly scans just those
candidates (not the whole array) to find the overall maximum, swaps it to the end of the shrinking unsorted range, and
re-establishes a maximum only for the one block that lost an element — the rest of the blocks' candidates are left
untouched.

That's the "lazy" part: after the very first full pass, no block is ever fully rescanned again unless it's the specific
block the last extraction came from. Compared to plain Selection Sort's full O(n) scan for every single extraction,
checking only `√n` block-maxima per step (plus an occasional O(√n) touch-up of one block) trades a little bit of
structure for real savings — the same kind of "block it, then only redo the block that changed" idea a few other
selection-sort variants use, just built around square-root-sized blocks specifically.
