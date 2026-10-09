Lazierest Stable Sort is an in-place merge sort organized into cube-root-sized blocks. It first
sorts short runs with binary insertion, merges neighboring runs into groups of roughly the square
of the block size, and then folds those groups into the sorted suffix. Compared with a simple
doubling merge sort, the group pass can skip over long stretches that are already in order.

Its merges search exponentially outward for the next insertion boundary, then rotate adjacent
pieces of the array instead of copying them to an external merge buffer. When the right run is
shorter, the merge scans backward to reduce the number of rotations. A final fragmented merge
weaves whole sorted blocks into the suffix before finishing their boundary with an ordinary
in-place merge. These details make the algorithm considerably more involved than a standard
merge sort, but allow it to work with **O(1)** auxiliary storage.

Equal values preserve their order: binary insertion places a new tie after existing ones; a
forward merge rotates only when its left element is strictly larger; and a backward merge
searches past equal values. The block operations are stable rotations, so the entire sort is
stable. Depending on the input, repeated in-place rotations can dominate the running time;
the conservative worst-case bound is **O(n²)**.
