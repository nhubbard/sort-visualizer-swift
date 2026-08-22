Hanoi Sort takes the Tower of Hanoi puzzle and repurposes its own move sequence as a sorting
method. Two auxiliary stacks stand in for two of the puzzle's three pegs; the array being sorted
plays the role of the third, consumed a value at a time from the front and rebuilt a value at a
time from the back. The central operation replays the classic Hanoi maneuver of walking a "tower"
of disks from one peg to another one disk at a time, except here it runs iteratively rather than
recursively: a genuine Hanoi tower move of height k always takes exactly 2^k - 1 individual disk
moves, and since the height of the tower being moved isn't known ahead of time, the algorithm just
keeps making legal one-at-a-time moves between pegs until a stopping condition — checked after
every move — reports that the move it's replaying has finished.

Because real input arrays contain duplicate values, a plain reading of the Hanoi puzzle would
break down the moment two equal elements needed to sit on the same peg without violating its
ordering: nothing in the classic puzzle says what "smaller" means for two disks of identical size.
Hanoi Sort resolves this by moving whole runs of consecutive equal elements together as a single
unit whenever one is relocated, so a peg's ordering constraint only ever has to hold between
genuinely distinct values. With that adjustment in place, the overall structure is recognizably an
insertion sort: each step removes the next value from the front of the array and finds its place
among the values already moved aside, except that "shifting elements to make room" is carried out
by relocating entire towers between pegs instead of shifting array cells directly.

The puzzle's own recursion-depth argument suggests this should cost something like O(n log n)
comparisons, but that argument describes the depth of a single simulated tower move, not the total
work of repeating the whole apparatus once per element — and measuring the algorithm's actual
operation count against growing input sizes shows it climbing far faster than that, entering
exponential territory well before arrays reach a few dozen elements. In practice this makes Hanoi
Sort a novelty: it always finishes with a correctly sorted array on small inputs, but the
operation count explodes quickly enough that it is impractical at any real-world scale. It is also
not a stable sort — the way runs of equal elements get shuffled between pegs and reassembled can
leave two originally-adjacent equal elements in the opposite of their original relative order.
