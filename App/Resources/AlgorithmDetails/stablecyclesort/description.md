*From Wikipedia, the free encyclopedia*

Stable Cycle Sort is a variant of [Cycle Sort](https://en.wikipedia.org/wiki/Cycle_sort) that restores the relative
order of equal elements, a property ordinary Cycle Sort does not have. Cycle Sort is notable for making the theoretical
minimum number of writes to the array of any comparison-based in-place sort — each element is written to the array at
most once, directly into its final resting place — by factoring the permutation to be sorted into disjoint cycles and
rotating each cycle into place. That same minimal-writes property is what makes its ordinary duplicate handling
unstable: when several equal elements exist, plain Cycle Sort resolves ties by skipping forward past any array slot that
already holds the same value, without regard for which occurrence of that value originally came first.

Stable Cycle Sort fixes this by tracking, in a separate `flagged` array parallel to the data being sorted, which
positions have already been settled into their final place by an earlier cycle. When computing the destination for the
value currently held at the start of a cycle, it counts not only how many elements are strictly smaller (as ordinary
Cycle Sort does) but also how many equal, not-yet-flagged duplicates lie between the start of the current cycle and the
position that started it. That second count lets each occurrence of a repeated value be placed after every other
occurrence of the same value that appeared earlier in the original array and hasn't been resolved yet, while skipping
past occurrences that have already been flagged into position by a prior step of the same cycle.

Because this bookkeeping only ever needs to distinguish "already placed" from "not yet placed," it can be represented as
a single array of booleans the size of the input, rather than as anything richer. This is a modest amount of extra
memory compared to plain Cycle Sort's few scalar variables, trading Cycle Sort's O(1) auxiliary space for O(n) space in
exchange for stability. The comparison-count and rotation structure otherwise mirrors ordinary Cycle Sort exactly, so
Stable Cycle Sort retains the same O(n) best case, O(n^2) average and worst-case running time, and it remains an
in-place sort in the sense that the flagged bookkeeping aside, no auxiliary copy of the data itself is ever made.
