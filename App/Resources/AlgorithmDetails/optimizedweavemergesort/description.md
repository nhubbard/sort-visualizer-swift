*From Wikipedia, the free encyclopedia*

Optimized Weave Merge Sort is a bottom-up, in-place merge sort. Like any bottom-up merge sort, it
treats the array as a collection of single-element runs, merges adjacent runs into pairs, then
repeats on the doubled run size until the whole array is one sorted run. What sets it apart is how
it merges: rather than comparing values from both runs all the way through, the way an ordinary
merge does, it splits the work into two very different phases, one of them entirely free of
comparisons.

The first phase interleaves the two runs' *positions* using nothing but index arithmetic. A block
rotation lines the runs up so a perfect-shuffle permutation can be applied to them, and that
shuffle is carried out through a bit-reversal pattern: swapping each index with the index obtained
by reversing its bits within the block. Repeating this rotate-and-shuffle step over a shrinking
window interleaves the two runs' elements the same way riffle-shuffling two halves of a deck of
cards interleaves them, purely by position, without ever looking at what value sits at any given
position. Because no comparisons happen here, this phase is cheap and its cost is easy to reason
about: it only ever moves elements around, and it does so through simple swaps and block copies.

The second phase is a single linear cleanup pass over the freshly interleaved range, using an
insertion-sort-like scan that shifts each element left just far enough to sit in order relative to
its neighbors. This pass is the only place in the entire algorithm where two elements are ever
compared to each other. Because the interleave phase already positioned same-valued runs close to
where they belong, this cleanup pass only has to fix up local disorder rather than resolve the
merge from scratch, which is what allows the overall merge to avoid a second full comparison pass
over the data.

The cleanup pass alternates between two shift conditions as it works: on one side of the
interleave it shifts elements that are less-than-or-equal-to their neighbor, and on the other side
it shifts only elements that are strictly less than their neighbor. This alternation is what makes
the algorithm stable. A cleanup pass that used only one of those two conditions throughout could
let an element that arrived from the second run slide in front of an equal element that arrived
from the first run, reordering them. Switching conditions depending on which run an element's
neighborhood descends from ensures equal elements are only ever shifted past each other in the
direction that preserves their original relative order, so no such crossing can occur.

Because the algorithm always performs the same fixed sequence of splits, interleaves, and cleanup
passes regardless of how the input is arranged, its running time does not depend on the input's
initial order: best, average, and worst case are all O(n log n). It sorts entirely in place,
using only a constant amount of extra bookkeeping beyond the array itself, so its space complexity
is O(1).
