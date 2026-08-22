Matrix Sort is a recursive generalization of ShearSort, a mesh-sorting algorithm originally
designed for parallel hardware: arrange the elements into a two-dimensional grid, alternately sort
every row (in alternating left-to-right and right-to-left direction, row by row) and every column
(always in the same direction), and repeat until a full round of row-and-column sorting changes
nothing at all. On real mesh-connected hardware every row and every column can be sorted
simultaneously, which is the appeal of the approach; this implementation runs the same logical
passes sequentially.

Choosing a grid shape for an arbitrary array length is the first wrinkle: the algorithm picks the
largest divisor of the current length that is no bigger than that length's square root as the row
width, keeping the grid as close to square as the length allows. Some lengths don't cooperate — a
prime number's only qualifying divisor is 1, and a length exactly one more than a perfect square
needs special handling too — and in those cases the algorithm falls back to sorting everything
except the last element and then inserting that one leftover element into its correct place with a
plain insertion step, the same kind of held-key, shift-and-place technique the algorithm also uses
directly whenever a row or column shrinks to 16 elements or fewer.

The recursive part is what separates this from a textbook ShearSort: a "row" or "column" longer
than that 16-element floor doesn't get a single linear insertion pass — it gets its own smaller
grid, sorted by this same algorithm applied to a narrower stride through the array. Every other row
is pre-reversed before the row-and-column convergence loop begins (and un-reversed again once it
finishes), which is what turns a set of independently-sorted alternating-direction rows into one
coherent ascending order for the column passes to build on.

Because the element being inserted during a shift-and-place step is only ever moved past elements
strictly less than it, elements that compare equal keep their original relative order, making this
a stable sort. Its running time depends heavily on how many elements are already in place: an
already-sorted input converges after one verification pass with almost no data movement, landing
close to O(n log n), while a more adversarial input needs proportionally more of that grid
convergence to settle, measuring out to roughly O(n^1.5) for average and worst-case input.
