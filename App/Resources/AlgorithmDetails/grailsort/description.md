Grail Sort, devised by Andrey Astrelin, is the classic in-place, stable block-merge sort that
achieves O(n log n) worst-case time while using only O(1) extra memory, no matter how large the
input gets. It starts by scanning for a handful of distinct values already present in the array
and pulling them to the front as a small "key" buffer — a movement-tracking device rather than a
scratch workspace. The rest of the array is then chopped into blocks, sorted bottom-up in doubling
passes, and reordered by a selection sort that compares each block's first and last elements
against its neighbors, using rotations (repeated block-swaps of the smaller side) to physically
move blocks into place instead of copying them out to auxiliary storage the way an ordinary merge
sort would.

What makes this the *stable* member of the Grail Sort family is a marker element carried through
every block swap during that selection-sort phase. Each block is tagged with which side of a
merge it originally came from, and when two blocks trade places, the algorithm carefully re-points
that marker (via an index swap tracked through XOR bookkeeping) so it keeps identifying the same
logical boundary even after the blocks around it have moved. That bookkeeping is threaded all the
way down into the merge step itself, where a block's "fragment" (which original side it belongs
to) determines the direction of a tie-breaking comparison. The net effect is that whenever two
equal elements would otherwise land in ambiguous order, the algorithm always resolves the tie in
favor of whichever one appeared first in the original array — which is the whole reason this
variant earns the "stable" name where a leaner sibling doesn't.

Like most block-merge sorts, Grail Sort doesn't fit neatly into a single traditional family — it
borrows the divide-and-conquer merge structure of merge sort, run-detection and block-building
ideas common to hybrid sorts like Timsort, and in-place rotation techniques more commonly seen in
specialized array-rearrangement algorithms. It's best categorized as a hybrid sort: a purpose-built
combination of ideas assembled specifically to get merge sort's guaranteed O(n log n) behavior and
full stability without merge sort's usual O(n) space cost. It's also the reference algorithm behind
many "block sort" implementations that have found their way into real-world standard libraries,
prized precisely because it needs no heap allocation to sort arbitrarily large inputs.
