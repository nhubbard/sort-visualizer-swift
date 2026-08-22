Tournament Sort treats every element of the array as a "player" entered into a single-elimination
knockout bracket, built up recursively the same way a real sports bracket is drawn: the players are
split into a left half and a right half, each half plays out its own sub-bracket first, and the two
half-champions then meet in one final match at the top. A "match" is nothing more than a comparison
between the current champions of its two sides, decided by whichever value is smaller. The bracket
itself is stored as a small implicit tree of match records rather than as a web of parent/child
pointers, and each match remembers three things: its current winner, a reference to whichever side
that winner is currently representing, and a reference to the side that lost.

Once the bracket is fully built, the smallest remaining value sits at its root as the overall
champion, so producing the sorted output is simply a matter of reading that champion off, once per
element. The interesting part is what happens immediately afterward. Removing a champion does not
require rebuilding the bracket from scratch — every match the champion never touched is completely
unaffected by its departure, so only the single chain of matches the champion actually won needs to
be revisited. That chain is walked back down toward whichever leaf the champion originally came
from, a fresh champion is found for just that one branch, and then exactly one more match is
replayed at each level between the newly crowned sub-champion and the side that was already sitting
out as a loser there. Because a knockout bracket over n players is only log n rounds deep, replaying
this single chain costs time proportional to the bracket's height rather than its full size — each
extraction runs in O(log n), and producing all n elements of the sorted output comes out to
O(n log n) overall, the same asymptotic bound as heapsort despite the bracket being shaped nothing
like a heap.

The bracket needs one match record for roughly every player, so Tournament Sort spends O(n) extra
space alongside the input array to hold it, rather than sorting in place the way heapsort does. It
is also not a stable sort: which of two equal-valued players ends up representing a given match's
winner is decided purely by the shape of the bracket — effectively, by where in the array each
player started out, since that is what determines which half of the bracket they land in — not by
which of the two appeared first in the original input. Two equal values can therefore easily come
out the other end in the opposite order from how they went in.
