Shove Sort scans an array left to right looking for an adjacent pair that's out of order. When it
finds one, it doesn't simply swap the two elements or shift the offender into its correct spot —
it "shoves" it all the way to the end of the range instead, via a chain of adjacent swaps that
walks from the offending position to the last index. The net effect of that chain is a one-step
left rotation of everything from the offending position onward: the too-large element ends up at
the very end, and every element that used to sit after it slides one position to the left.

After a shove, the scan backs up by one position (unless it's already at the start of the range)
to re-examine whatever slid into the spot it just vacated, rather than continuing forward past it.
This gives the algorithm a chance to shove the same trouble spot again if the element that took its
place is also out of order, at the cost of potentially revisiting the same stretch of the array
many times.

Despite living among other exchange sorts and performing the same order of work as a
shift-based insertion sort — every shove costs a pass across the remaining range, and the same
position can be reshoved on a later loop — this algorithm is filed under "Impractical Sorts",
alongside other purpose-built curiosities rather than textbook comparison sorts.
Because a shove can carry an out-of-order element past several other elements at once, including
any that happen to be equal to it, Shove Sort does not preserve the original relative order of
equal elements and is not a stable sort.
