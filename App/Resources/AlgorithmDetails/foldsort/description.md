Fold Sort is a [sorting network](https://en.wikipedia.org/wiki/Sorting_network) in the same broad
family as Batcher's Bitonic Sort — a comparator-based sort whose sequence of compare-and-swap
operations is fixed in advance and never depends on the data being sorted, built from comparators
designed to be independently evaluable and therefore suitable for parallel or pipelined hardware.
It has no dedicated Wikipedia article of its own under this exact name.

The whole network is built out of one repeated operation: a "halver" pass that walks two pointers
inward from both ends of a range, comparing and swapping each mirrored pair until the pointers
meet — folding the range onto itself, which gives the algorithm its name. The construction
conceptually pads the real array length up to the next power of two and runs the classic
three-nested-loop bitonic shape on top of that padded size: an outer pass over halving block sizes,
a middle pass folding progressively smaller sub-blocks within each of those blocks, and an inner
sweep of halver calls across the whole padded range, with every individual comparator still
bounds-checked against the real, unpadded array length.

That triple-nested loop shape — a doubling/halving pass nested inside another doubling/halving
pass, both wrapped around a linear sweep — is what gives this network its O(n log²n) best-case,
average-case, and worst-case running time, all identical since the comparator schedule depends only
on the (padded) length of the input. Every comparator only ever swaps on a strict "greater than"
test, and this network never lets two equal elements cross paths without an intervening comparison
establishing their order, so it is a stable sort.
