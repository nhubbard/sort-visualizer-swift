Comb sort is an in-place comparison sort that extends bubble sort by comparing elements separated by a shrinking gap.
The gap initially equals the array length. Before each pass, a gap greater than one is divided by 1.3 and rounded
down. The pass compares each element with the element one gap away and exchanges the pair when they are out of order.
Large gaps can move an element across much of the array in a single pass, while later passes examine progressively
closer pairs.

After the gap reaches one, the algorithm continues making adjacent-element passes until a full pass makes no swaps.
This final condition ensures that the array is ordered even when the earlier gap passes leave inversions behind. The
number of shrinking-gap passes is logarithmic in the array length, and each such pass examines a linear number of
pairs. Additional gap-one passes can make the average and worst-case running time quadratic. Only a gap counter and
swap flag are needed outside the array, so auxiliary space is constant. The sort is not stable: a long-distance swap
can move one element past another with an equal key, changing their original relative order.
