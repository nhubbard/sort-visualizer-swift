Drop-Merge Sort is an [adaptive sorting
algorithm](https://en.wikipedia.org/wiki/Adaptive_sort) built specifically for input that is
*already almost sorted* — re-sorting a mostly-sorted list after a handful of small edits, for
example. Where most general-purpose sorts treat every input the same way, this one bets that the
data is nearly in order already, and is built to win big on that bet while still finishing
correctly, just less spectacularly, when the bet turns out wrong.

The core idea is a single left-to-right pass that greedily keeps every element already in order
and "drops" everything else into a side list, rather than paying to shift the array around every
time something is out of place. An element is kept if it's at least as large as the last element
kept; anything smaller gets set aside instead. Because dropping an element costs one write and
no comparisons against everything after it, this pass is very cheap for input that's mostly in
order.

A few refinements keep the dropped list from growing pointlessly large:

- **Quick undo.** If a dropped element would have fit right after the *second-to-last* accepted
  element instead, the algorithm un-accepts the last element (dropping it) and puts the new one in
  its place. This resolves an isolated pair of adjacent elements that got swapped without needing
  to fall back to the general drop mechanism at all.
- **Backtracking.** If eight elements in a row get dropped, whichever element was accepted right
  before that streak was probably a mistake — it was just barely small enough to block eight
  otherwise-orderly elements behind it. The algorithm undoes that whole streak, and un-accepts
  further already-kept elements too, for as long as they're bigger than the largest element in the
  streak being undone.
- **Giving up early.** After examining a quarter of the array, if well over half of it has already
  been dropped, the input clearly isn't "mostly sorted" at all. Rather than keep paying for the
  overhead of tracking drops, the algorithm flushes what's been set aside back into the array and
  falls back to an ordinary general-purpose sort of the whole thing.

Once the left-to-right pass finishes (assuming it didn't give up early), the dropped list — usually
short — gets sorted on its own with a general-purpose sort, then merged back together with the
already-sorted run of kept elements using a standard two-pointer merge, worked from the end of the
array backward so the merge can be done in place without a second full-size buffer.

Drop-Merge Sort is an in-place [comparison
sort](https://en.wikipedia.org/wiki/Comparison_sort) and is not
[stable](https://en.wikipedia.org/wiki/Sorting_algorithm#Stability): elements can end up
reordered relative to their original positions as they move between the kept run and the dropped
list. Its best case is O(n) — a single pass with nothing ever dropped — and its worst case matches
whatever general-purpose sort it falls back to, since the early-out check guarantees it never
spends much more effort than that fallback would have cost on its own. In between, its total work
scales with how much of the input is actually out of order, not with its size alone: a large but
nearly-sorted array can sort dramatically faster than an equally large, thoroughly shuffled one.
