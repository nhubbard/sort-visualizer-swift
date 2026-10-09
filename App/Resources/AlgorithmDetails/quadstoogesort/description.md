Quad Stooge Sort generalizes [Stooge Sort](https://en.wikipedia.org/wiki/Stooge_sort)'s recursive
"swap the ends, then recurse on overlapping sub-ranges" idea from three recursive calls covering
two thirds of the range each to six recursive calls covering roughly half the range each. After settling
array[pos] and array[pos + len − 1] (the current range's endpoints) with a single
compare-and-swap, it recurses into three overlapping windows, the first half, the second half,
and a third window straddling the midpoint, in a specific order (first half, second half, middle,
second half again, first half again, and, for ranges bigger than 3, middle again), so that every
element gets a chance to move across the midpoint boundary more than once.

Six recursive calls each on a range of about half the size gives the recurrence
T(n) = 6 × T(n ÷ 2) + O(1), which resolves to O(nˡᵒᵍ₂ ⁶) ≈ O(n²·⁵⁸⁵). That is a *better*
exponent than plain Stooge Sort's O(nˡᵒᵍ ³ ⁄ ˡᵒᵍ ¹·⁵) ≈ O(n²·⁷¹), even though Quad Stooge
Sort makes twice as many recursive calls per level, halving a range shrinks the problem faster
than splitting it into thirds does, and that effect outweighs the extra calls as the array grows.

Like Stooge Sort, this is still a purpose-built impractical sort rather than a competitive
comparison sort and is categorized accordingly among the Impractical Sorts, despite its source
file living alongside the ordinary exchange sorts. The repeated swapping of distant range endpoints
across overlapping windows means equal-valued elements are not guaranteed to keep their original
relative order, so Quad Stooge Sort is not a stable sort.
