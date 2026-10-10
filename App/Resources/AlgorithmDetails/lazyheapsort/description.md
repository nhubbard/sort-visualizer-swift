Despite its name, Lazy Heap Sort is a square-root-decomposition selection sort rather than a heap sort. The array is
divided into blocks of roughly √n elements each; every block's maximum is moved to the front of that block in one
pass, so there are now √n "candidate" maxima sitting at fixed positions. The main loop repeatedly scans just those
candidates (not the whole array) to find the overall maximum, swaps it to the end of the shrinking unsorted range, and
re-establishes a maximum only for the one block that lost an element, the rest of the blocks' candidates are left
untouched.

After the first full pass, a block is rescanned only when the preceding extraction came from that block. The
block the last extraction came from. Compared to plain Selection Sort's full O(n) scan for every single extraction,
checking only √n block-maxima per step (plus an occasional O(√n) touch-up of one block) trades a little bit of
structure for reduced work. Other selection-sort variants use related block-update methods; this variant uses blocks
whose size is proportional to the square root of the input length.
