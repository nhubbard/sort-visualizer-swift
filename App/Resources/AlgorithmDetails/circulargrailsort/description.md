Circular Grail Sort is an in-place block merge sort. It reserves a power-of-two block of
the input as an internal rolling buffer, builds sorted runs in the remaining logical range, and
then combines progressively larger runs. Logical positions are allowed to advance past the end of
the array; taking every access modulo the array length turns the physical array into a ring.

Small inputs use insertion sort. For larger inputs, the block length is the smallest power of two
whose square is at least the input length. Initial merges move data through that block. Later
merges order whole blocks by their first elements, breaking ties with their last elements, before
performing stable element-level merges. A final rotation removes the ring's accumulated offset.

The algorithm uses only swaps within the input array, so it requires constant auxiliary space.
Its element-level merges choose from the left run on equal keys, but the block-selection phase can
swap whole blocks containing equal values across one another. The complete algorithm is therefore
not stable.

Its best, average, and worst-case running time is O(n log n), and it uses O(1) auxiliary space.
