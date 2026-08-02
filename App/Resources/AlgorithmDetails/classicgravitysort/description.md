Classic Gravity Sort is another variant of Bead Sort (Gravity Sort), one that makes the algorithm's
usual "columns of beads settling under gravity" picture completely literal instead of shortcutting
it with arithmetic. Ordinary Bead Sort imagines each value as a row of beads threaded onto vertical
rods, one rod per array position; letting every bead fall under gravity and reading off each rod's
final height yields the values in ascending order.

This variant builds an explicit table of columns — one entry per possible height, up to the array's
largest value — and fills it in exactly the way a real bead rack would be loaded: for every element,
walk up its own height one row at a time, and mark that a bead now occupies that row's column.
Once every element has contributed its beads, the table holds, column by column, how many elements
were tall enough to reach that height — precisely the shape a settled bead rack would have.

Reading the sorted result back out reverses the loading direction. For each output position, filled
from the last position back to the first, the algorithm counts how many columns in the table still
have a bead left in them at all; that count is this position's final value, since it reflects
exactly how many of the original elements were tall enough to still be contributing to the rack
at this pass. Every column is then knocked down by one bead before moving to the next, shorter
position, so each pass only ever sees what's left after every taller position has already claimed
its share.
