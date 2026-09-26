Remi Sort is a stable multiway merge sort that uses cube-root-sized blocks. It first divides the
input into runs of roughly n²⁄³ elements. Each run is sorted through a table of original
positions: a heap orders the positions by their values, breaking ties by original position, and
the resulting permutation is applied in cycles. Equal elements therefore stay in their original
order within each run.

A second heap chooses the smallest current head among all runs. Its tie-breaker is the run number,
so equal values from earlier runs leave the heap first. The first output block is copied to an
auxiliary buffer. Subsequent output reuses locations that the merge has already emptied. A final
set of block-permutation cycles restores the displaced blocks, then the saved first block is put
back. This avoids allocating a full-size merge buffer.

The algorithm uses O(n log n) comparisons in the worst case. Its auxiliary keys and saved block
occupy O(n²⁄³) space. Stability depends on both tie-breakers: original position in each run
and run number across the multiway merge.
