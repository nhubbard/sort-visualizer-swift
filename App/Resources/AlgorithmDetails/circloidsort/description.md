*From Wikipedia, the free encyclopedia*

Circloid Sort is a variant of Circle Sort, a comparison-based sorting algorithm built around a simple symmetric idea:
compare the first element of a range against the last, the second against the second-to-last, and so on, swapping any
out-of-order pair as the two pointers converge toward the middle. Circloid Sort itself has no dedicated Wikipedia
article — it originates as a community-contributed sorting-visualizer variant rather than a textbook algorithm, but it
follows the same converging compare-and-swap idea, recursively applied, as its better-known relative.

Where this variant departs from the ordinary recursive Circle Sort is in how it handles ranges that are not themselves a
power of two in length. Rather than padding the working range up to the next power of two and guarding every access
against the true array length, Circloid Sort recurses directly on the real range: given a range `[left, right]`, it
splits at the midpoint, recurses into the first half and then the second half — both of which are always real, non-empty
sub-ranges, never conceptually padded ones — and only once both of those recursive calls return does it perform this
level's own converging compare-and-swap pass over the *entire* `[left, right]` range. A range with an odd number of
elements has its two converging pointers meet at the same middle index; rather than comparing that element against
itself, the algorithm nudges the trailing pointer one step further so the final comparison in that pass is between the
middle element and its immediate neighbor. As with the ordinary recursive form, one full top-to-bottom recursive sweep
is only a single "round"; the whole sweep is repeated until one of them completes without a single swap anywhere in the
recursion, at which point the array is sorted.

Splitting the real range exactly in half at every level, rather than an artificially padded one, makes each full sweep
cost O(n log n): every level of the recursion does O(n) total work across all of that level's sub-ranges, and there are
O(log n) levels before the recursion bottoms out at single-element ranges. Classic Circle Sort's own analysis — a full
sweep is guaranteed to resolve at least one additional level of remaining disorder — carries over directly, so at most
O(log n) sweeps are ever needed, giving an average- and worst-case running time of O(n log² n). The best case, an
already-sorted input, still needs one complete sweep just to confirm that no swap is necessary, so its running time is
that single sweep's own cost, O(n log n). No auxiliary array is ever allocated; the only real memory cost beyond the
input is the recursion stack itself, which is bounded by the same O(log n) depth as the sweep's own level count.

Circloid Sort is not a [stable sort](https://en.wikipedia.org/wiki/Sorting_algorithm#Stability). Its converging
compare-and-swap pairs, like ordinary Circle Sort's, can be arbitrarily far apart in the array, so even though no
individual swap is ever triggered by two elements comparing equal, two equal elements can still be indirectly reordered
relative to each other: each can swap against a different, unequal third element at a different point in the recursion (
or in a later sweep), shifting the two equal elements past one another without either one ever being compared directly
against the other.