Classic Tournament Sort is a selection sort built around a tournament tree: a complete binary tree
whose leaves are the array's indices and whose internal nodes each remember which of their two
children currently holds the smaller value. The name comes from single-elimination sports
brackets — every internal node is a "match" between the winners of the two matches beneath it, the
smaller value always advancing, so the root of the tree ends up holding the index of the overall
smallest remaining value the moment the tree finishes filling in.

Building the tree happens once, bottom-up. Every array index starts out as a leaf holding itself.
Working level by level from the leaves toward the root, each internal node is filled in by
comparing its two children's current winners and keeping the index of the smaller one — exactly
one comparison per node, for a total proportional to the number of leaves. Once this pass reaches
the root, reading the root's stored index immediately gives the position of the smallest value in
the whole array, with no scan required.

The interesting part is what happens after that value is read off and copied to the output. A
naive approach would rebuild the entire tree from scratch to find the next-smallest value, but
that throws away almost all of the work the tree already encodes. Instead, only the single root
value just consumed could possibly still be sitting anywhere along the path from its original leaf
up to the root — every other subtree hanging off that path was untouched by the extraction and its
cached winner is still valid. So the algorithm walks that one path, marks the just-used leaf as
retired, and replays only the comparisons between each node on the path and its sibling, propagating
whichever value should win now that one contender is gone. A tree holding *n* leaves has a height
proportional to the logarithm of *n*, so each of these replay walks touches only a logarithmic
number of nodes rather than the whole tree, and one full extraction — replaying the path plus
reading the new root — costs the same. Doing this once for each of the *n* elements gives a total
running time proportional to *n* times the logarithm of *n*, the same asymptotic bound as heapsort
or mergesort, but arrived at by treating selection as a tournament that only needs its affected
bracket re-played rather than as a structure that needs re-heapifying after every removal.

This efficiency comes at the cost of memory: alongside the original array, the algorithm needs
tree storage roughly proportional to the array's own size to hold every internal node's cached
winner, an amount of extra space that ordinary heapsort — which reuses the input array itself as
its heap — does not need. Classic Tournament Sort is also not a stable sort. Two equal values can
easily end up as leaves on opposite sides of the tree, and which one is recorded as the "winner" of
a tie depends entirely on the arbitrary shape of the bracket they happen to fall into, not on which
one appeared first in the original array — so equal elements are not guaranteed to keep their
relative order after sorting.
