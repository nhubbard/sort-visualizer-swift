*From Wikipedia, the free encyclopedia*

Pancake sorting is the mathematical problem of sorting a disordered stack of pancakes in order of size when a spatula
can be inserted at any point in the stack and used to flip all pancakes above it. A *pancake number* is the minimum
number of flips required for a given number of pancakes. In this form, the problem was first discussed by American
geometer [Jacob E. Goodman](https://en.wikipedia.org/wiki/Jacob_E._Goodman). It gained wider attention after computer
scientist [Bill Gates](https://en.wikipedia.org/wiki/Bill_Gates) co-authored a 1979 paper on the subject
with [Christos Papadimitriou](https://en.wikipedia.org/wiki/Christos_Papadimitriou), describing a bound-improving
strategy that repeatedly brings the largest not-yet-sorted pancake to the top of the stack with one flip, then flips it
again into its final resting place at the bottom of the unsorted portion.

A well-known variant of the problem concerns *burnt* pancakes. Here, every pancake in the stack has one side that has
been burnt, and a properly sorted stack must, in addition to being ordered by size, have every pancake's burnt side
facing down. Because a spatula flip both reverses the order of the pancakes above the insertion point *and* turns each
of those pancakes upside-down, a flip in the burnt variant simultaneously changes relative order and orientation — a
single move that must be reasoned about on two axes at once, rather than one. This makes the burnt pancake problem
meaningfully harder to analyze than the ordinary version, and its
exact [pancake number](https://en.wikipedia.org/wiki/Pancake_sorting) is known only for small stack sizes.

The implementation used in this application is a direct, index-only translation of the "select the largest, then flip it
into place" strategy popularized by the Gates–Papadimitriou paper: on each pass it scans the unsorted prefix of the
stack for the largest remaining pancake, flips the stack so that pancake is on top, and then flips again so it lands in
its correct final position, before shrinking the unsorted portion by one and repeating. It does not separately track or
render pancake orientation, so it substitutes for a full burnt-pancake simulation while still being motivated by, and
named for, that variant of the problem. As with ordinary pancake sort, this selection-and-flip approach requires on the
order of two flips and one linear scan per pancake, giving a worst-case running time
of [O(n²)](https://en.wikipedia.org/wiki/Big_O_notation) comparisons and flips for a stack of *n* pancakes.
