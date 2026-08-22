*From Wikipedia, the free encyclopedia*

[Shellsort](https://en.wikipedia.org/wiki/Shellsort) generalizes insertion sort by first comparing and exchanging
elements that are far apart, then progressively narrowing the gap between compared elements until it reaches one, at
which point the final pass is an ordinary adjacent-element pass. Which sequence of gaps to use is the whole art of the
algorithm, and one of the most celebrated choices is V. Pratt's sequence: every gap of the form `2^a * 3^b` below the
array's length — a so-called *3-smooth* number, meaning it has no prime factors other than 2 and 3. Pratt proved that
running exactly one compare-and-swap pass for every 3-smooth gap, in decreasing order, is sufficient to fully sort any
input, turning Shellsort into a genuine, fixed, data-independent sorting network rather than a heuristic.

3-Smooth Comb Sort (Iterative) computes this same gap sequence, but through a different mechanism than its sibling, the
Classic 3-Smooth Comb Sort. The Classic variant walks every integer from `length - 1` down to `1` and tests each
candidate directly for 3-smoothness, repeatedly dividing out factors of 2 and 3 until nothing but a leftover 1 remains.
This iterative variant instead generates the gaps by construction: two nested loops range directly over the two
exponents themselves. The outer loop counts an exponent `k` down from the largest power of two not exceeding
`length - 1`; for each `k`, an inner loop counts an exponent `j` down from the largest value such that `2^k * 3^j` still
stays below `length`. Every `(k, j)` pair the loops visit produces exactly one gap, `2^k * 3^j`, and the array receives
one full left-to-right compare-and-swap pass at that gap before the next pair is tried. Because the loops are driven
purely by exponents rather than by testing candidate integers one at a time, this variant never inspects a single gap
value that turns out *not* to be 3-smooth — every iteration of the nested loops corresponds to a real, useful gap.

Although the two variants visit the exact same set of 3-smooth gaps below the array's length, they do not visit them in
the same order: the Classic sibling's simple integer countdown produces a strictly decreasing sequence of gap values,
while this iterative variant's outer-`k`/inner-`j` traversal does not — a smaller gap belonging to a larger power of two
can be visited before a larger gap belonging to a smaller power of two. This has no bearing on correctness whatsoever:
Pratt's theorem only requires that every 3-smooth gap below the array's length receive its one guaranteed pass at some
point during the run, not that the passes happen in any particular order, and both variants' passes cover the identical
set of gaps.

Because there are only `Θ(log² n)` distinct 3-smooth gaps below `n` — a consequence of the two independent exponents
each ranging over only `O(log n)` values — and each of those gaps costs a `Θ(n)` pass across the whole array, the total
work is `Θ(n log² n)` in the best, average, and worst case alike; there is no data-dependent early exit the way an
adaptive comb sort has, since the entire gap sequence and pass count are fixed functions of the array's length alone.
This algorithm is also not a [stable sort](https://en.wikipedia.org/wiki/Sorting_algorithm#Stability): a pass at a gap
greater than one compares and can swap two elements that sit far apart in the array, without ever directly comparing
either of them to an equal-valued element resting somewhere in between — so two equal elements can cross paths during a
large-gap pass with no way to recover their original relative order once the sequence winds down to the final gap-one
pass.
