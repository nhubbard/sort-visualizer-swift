New Shuffle Merge Sort is a variant of [Merge Sort](https://en.wikipedia.org/wiki/Merge_sort) that merges two
adjacent sorted runs with no auxiliary array at all — not even the handful of temporary slots that in-place
merge techniques based on rotations or repeated shifting rely on. Instead, it borrows a published technique from
the study of in-place permutation algorithms: the **perfect shuffle**, also called a riffle or Faro shuffle,
the same interleaving a card player performs when splitting a deck in half and merging the two halves back
together one card at a time, alternating sides — `a1, b1, a2, b2, a3, b3, ...`.

Interleaving two sorted runs this way turns the hard part of an in-place merge — figuring out which elements are
already in relative order and which need to move — into a purely local pattern-matching problem. In the shuffled
sequence, a stretch where the two runs are already correctly merged looks like an alternating comparison pattern
where each left-run element compares no greater than its neighboring right-run element; a stretch where several
consecutive elements from one run all belong before the elements around them shows up as a short run of
same-direction comparisons instead. A single forward scan comparing each adjacent pair is therefore enough to find
every place the merge still has work to do, without ever comparing across the width of either original run.

Whenever the scan finds such a mismatched stretch, only that stretch needs fixing: the algorithm **un-shuffles**
just that chunk — reversing the interleaving to recover two short plain runs — and then uses a **block rotation**
to swap those two runs into their correct relative order, exactly as a rotation-based in-place merge would for a
tiny sub-problem. Because the chunk being fixed is always small relative to the whole merge, and every element is
touched a bounded number of times overall, the total work stays proportional to an ordinary merge.

The perfect shuffle itself is also performed without any extra storage, using a classic trick for applying a
permutation in place: follow the cycles of the mapping that sends each position to where its value belongs, writing
each value directly into its destination as the cycle is walked, until the cycle closes back on its starting point.
A single riffle shuffle of an arbitrary number of elements does not decompose into cycles that close cleanly on
their own, so the algorithm instead shuffles in chunks sized to the largest power of three that fits the remaining
range — a family of sizes for which the cycle structure is well understood and closes after a bounded number of
steps — and glues each chunk to the next with a small block rotation before continuing. Un-shuffling later, to
recover a plain run for the rotation step above, runs those same cycles in reverse.

Every operation involved — the shuffle, the un-shuffle, and the rotations that connect chunks and reorder fixed-up
stretches — is built entirely out of swaps and cycle-following writes back into the original array, so the
algorithm needs no auxiliary buffer of any size, only a constant amount of bookkeeping. Locating each chunk that
needs fixing still costs comparisons proportional to an ordinary merge, and the shuffle/un-shuffle/rotation
machinery moves each element only a bounded number of times per level of the merge, so the algorithm keeps the
familiar `O(n log n)` time bound of merge sort while running in genuinely `O(1)` auxiliary space.

This "shuffle, then locally un-shuffle and rotate" strategy is a real, published technique for merging in place —
distinct from the more common approach of locating a single split point (by binary search) and rotating the two
runs into place in one step. Its distinguishing feature is that the comparisons needed to drive the merge and the
data movement needed to complete it happen in the same local pass over the shuffled array, rather than as two
separate phases.
