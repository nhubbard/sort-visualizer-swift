Smart Bogo Bogosort is built on an observation about what a sorted array needs: if the first n − 1 elements
are already sorted, the whole array is sorted the moment the last element is no smaller than the one before it. So this
algorithm recursively sorts the first n − 1 elements using this very method, then just checks that one final
comparison, and if it fails, reshuffles the *entire* range at random and starts the recursive sort of the prefix over
again from scratch.

The method is intentionally inefficient. Rather than moving the last element into place once the
prefix is sorted, a failed check throws away all the work of sorting the prefix and gambles on a fresh shuffle producing
both a sorted prefix *and* a correctly-placed last element at the same time. Each level of the recursion repeats the
same random trial at a smaller scale. This structure is related to Bogo Bogo Sort but avoids its recursive sortedness
test.
