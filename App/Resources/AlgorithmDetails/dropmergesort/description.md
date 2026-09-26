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

A few refinements keep the dropped list from growing pointlessly large. A **quick undo** handles an
isolated swapped pair: if a dropped element would have fit right after the *second-to-last* accepted
element, the algorithm un-accepts the last element and puts the new one in its place.

**Backtracking** responds when eight elements in a row get dropped. The element accepted immediately
before that streak was probably a mistake, so the algorithm undoes the streak and continues
un-accepting earlier elements while they are larger than the greatest element being restored.

The algorithm may also **give up early**. After examining a quarter of the array, if well over half
of it has already been dropped, the input is not mostly sorted. The algorithm then restores the
dropped elements and falls back to branched pattern-defeating quicksort (PDQSort) for the whole array.

Once the left-to-right pass finishes (assuming it didn't give up early), the dropped list — usually
short — gets sorted with the same branched PDQSort, then merged back together with the
already-sorted run of kept elements using a standard two-pointer merge, worked from the end of the
array backward so the merge can be done in place without a second full-size buffer.

Drop-Merge Sort is a [comparison
sort](https://en.wikipedia.org/wiki/Comparison_sort) and is not
[stable](https://en.wikipedia.org/wiki/Sorting_algorithm#Stability): elements can end up
reordered relative to their original positions as they move between the kept run and the dropped
list. Its best case is O(n) — a single pass with nothing ever dropped — and its worst case matches
the O(n log n) PDQSort fallback, since the early-out check guarantees it never
spends much more effort than that fallback would have cost on its own. It uses O(n) auxiliary
space for dropped values and the merge buffer. In between, its total work
scales with how much of the input is actually out of order, not with its size alone: a large but
nearly-sorted array can sort dramatically faster than an equally large, thoroughly shuffled one.
