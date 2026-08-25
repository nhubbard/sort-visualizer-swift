*From Wikipedia, the free encyclopedia*

Optimized Dual-Pivot Quicksort takes Vladimir Yaroslavskiy's 2009 dual-pivot partitioning
scheme — the same one behind Java's `Arrays.sort` for primitive-type arrays — and adds two
practical refinements aimed at squeezing more real-world performance out of it, rather than
changing its underlying divide-and-conquer structure.

The core partitioning step is unchanged from plain dual-pivot Quick Sort: two pivots are chosen by
sampling a couple of candidate elements roughly a third of the way in from each end of the range
and comparing them, so the smaller candidate becomes `pivot1` and the larger becomes `pivot2`. A
single left-to-right scan then splits the rest of the range into three parts at once — elements
less than `pivot1`, elements greater than `pivot2` (found by scanning inward from the right and
swapping into place), and everything left over in between — after which the two pivots are dropped
into the boundary positions between their regions and each of the three regions recurses on its
own.

The first optimization is a much larger cutoff to a plain [insertion
sort](https://en.wikipedia.org/wiki/Insertion_sort) for small ranges. A textbook quicksort
typically only special-cases ranges of three or four elements before falling back to insertion
sort; here the cutoff is raised to a few dozen elements instead, because insertion sort's low
constant-factor overhead keeps winning well past that point, and it is not worth paying for
another round of pivot sampling, partitioning, and recursive calls just to sort two dozen items.

The second, more interesting optimization targets the classic weak point of dual-pivot
partitioning: arrays with many repeated values. Every element that lands in the middle region — the
elements no smaller than `pivot1` and no larger than `pivot2` — is not necessarily equal to either
pivot, but on heavily duplicated input, a great many of them usually are. If that middle region
comes back from partitioning unusually large, and the two pivots turned out to be genuinely
different values, the algorithm pauses before recursing into it and runs one more scan that moves
every element exactly equal to `pivot1` to extend the low region, and every element exactly equal to
`pivot2` to extend the high region. Because the moved elements are, by definition, no smaller or
larger than the low or high regions they are joining, this can be done without disturbing the
sorted order those regions already have. Only the genuinely narrower remainder — elements strictly
between the two pivot values — still needs a real recursive sort, which sidesteps the pathological
case where a middle partition packed with pivot-valued duplicates would otherwise get
re-partitioned over and over for no benefit.

Like plain dual-pivot Quick Sort, this variant is an in-place [comparison
sort](https://en.wikipedia.org/wiki/Comparison_sort) that is not
[stable](https://en.wikipedia.org/wiki/Sorting_algorithm#Stability) — equal elements can still end
up reordered relative to one another as they cross partition boundaries. Its worst case is still
O(n²) in principle, since no fixed pivot-selection rule can be made immune to every adversarial
input, but the equal-elements pass specifically neutralizes the everyday case that trips up plain
dual-pivot quicksort: arrays with a very small number of distinct values repeated many times over.
