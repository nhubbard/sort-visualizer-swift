*From Wikipedia, the free encyclopedia*

An AVL tree is a self-balancing binary search tree, generally credited as the first such structure
described in the literature, and named for the initials of the two researchers who introduced it.
Every node carries a balance factor: the height of its right subtree minus the height of its left
subtree, which in a valid AVL tree is always -1, 0, or 1. AVL tree sort inserts each input value
into an initially empty AVL tree one at a time, then reads the sorted result back out with a plain
in-order traversal — the same finishing step any binary-search-tree-based sort relies on.

The balancing work happens during insertion itself. A new value walks down from the root the way
it would in any binary search tree, recursing into the left subtree if it compares smaller or the
right subtree otherwise, until it reaches an empty spot where a new node is created. Unwinding back
up that same recursive path, each ancestor updates its balance factor to reflect that one of its
subtrees just grew taller. Most of the time this only nudges the factor by one, and if that
ancestor's own height grew as a result, the growth is reported upward so the next ancestor in line
does the same check. Once an ancestor's balance factor would move to +-2, the invariant would be
broken, so a rotation is performed instead: a single rotation if the overweight subtree leans the
same direction as the node it hangs from, or a double rotation — two single rotations performed in
sequence — if it leans the opposite way. Either kind of rotation restores the subtree's height to
exactly what it was before the insertion, which is why the rebalancing effect never needs to
propagate past the first ancestor that required fixing.

Because a rotation always restores the affected subtree's pre-insertion height, an AVL tree's
overall height stays bounded at O(log n) relative to the number of nodes it holds, regardless of
the order values arrive in. That worst-case guarantee is what separates it from a plain, unbalanced
binary search tree, whose height can degrade to O(n) on already-sorted input and drag the resulting
sort down to O(n^2). Since insertion and the final traversal are each bounded by the tree's height,
AVL tree sort runs in O(n log n) time in the best, average, and worst case alike, at the cost of the
extra per-node bookkeeping and occasional rotation that an unbalanced tree sort doesn't need.

Whether a value equal to one already in the tree is sent left or right during insertion is a free
choice in the general algorithm, but it isn't an arbitrary one in practice: consistently sending
equal values to the same side — here, to the right — is what allows an in-order traversal to
preserve their original relative order, which is what gives the sort its stability.
