Simplistic Gravity Sort is a variant of Bead Sort (Gravity Sort) that simulates falling beads one
bead at a time rather than computing settled column heights all at once. Bead Sort's usual mental
picture represents each value as a row of beads threaded onto vertical rods, one rod per array
position; when released, every bead falls until it lands on the ground or on top of another bead,
and reading off the height of each rod afterward yields the values in ascending order.

This variant makes that falling process literal, one bead at a time, using a single shared row of
"columns" as scratch space. First, every array position sheds its beads: for as long as its value
is still above the array's minimum, it decrements itself by one and hands that unit off to the next
free column in the shared row, moving left to right along that row. Once every position has been
drained down to the minimum, the shared row holds every bead that needs to be redistributed. The
array is then walked once more, this time from the last position to the first, and each position
pulls beads back from the front of the shared row — incrementing itself and decrementing the
row's leftmost still-occupied column — until it hits a column that's already empty.

Because later positions (processed first, since the second pass runs backward) can only ever pull
from the front of the shared row, and the row's columns are only ever filled and drained in a
fixed left-to-right order, elements that started out equal end up drawing from the same stretch of
the row in the same relative order they were shed in — so equal elements never cross paths, making
this a stable sort. Its running time and memory use scale with both the number of elements and the
spread between the smallest and largest value, the same trade-off ordinary Bead Sort makes.
