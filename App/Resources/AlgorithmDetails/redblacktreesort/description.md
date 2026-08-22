*From Wikipedia, the free encyclopedia*

A red-black tree is a self-balancing binary search tree that keeps its height bounded by attaching
one extra bit of information — a color, red or black — to every node, along with a small set of
rules those colors must satisfy. The root is always black. A red node may never have a red child,
so no two reds ever appear consecutively along any path. And every path from a given node down to
any of its empty (null) descendants passes through the same number of black nodes, a quantity
called that node's black-height. Together, these rules bound the tree's height at roughly twice the
minimum possible for a binary tree holding that many nodes, since the longest possible root-to-leaf
path — alternating red and black — can be at most twice as long as the shortest, all-black one.
That guarantee is what makes a red-black tree sort behave predictably no matter what order its
input arrives in.

Building the tree top-down, one insertion at a time, is what keeps these invariants intact without
ever needing a separate pass to repair them afterward. Each newly inserted node starts out red,
since attaching a red leaf can only ever create a red-red violation, never disturb any path's
black-height. As the insertion recurses downward looking for where the new value belongs, it
performs an eager recolor at any node it passes through that is itself black but has two red
children: that node flips to red, and both of its children flip to black. This looks like it
manufactures exactly the violation the algorithm is trying to avoid, but it's actually a
self-contained fix — flipping a black node with two red children preserves every path's
black-height while trading one potential violation higher up, at that node's own parent, for none
at all further down, and there is never more than one such pending repair at a time. If a red-red
violation does reach a node's own child on the way back up out of the recursion, one or two tree
rotations put it right, and which side of the violation the offending grandchild sits on determines
whether a single rotation suffices or a double rotation is needed first to line the nodes up before
rotating. Once the new value has been inserted and any pending rotation has been applied, the root
is forced back to black, since the rule that the root is always black must hold regardless of what
color it ended up wearing partway through the insertion.

Sorting with a red-black tree follows the same shape as sorting with any other binary search tree:
insert every value one at a time, then read the result back out with a plain in-order traversal,
which visits the left subtree, then the current node, then the right subtree. What the balancing
buys is a worst-case guarantee an ordinary, unbalanced binary search tree cannot offer: because the
tree's height never exceeds a constant multiple of the logarithm of its size, every insertion costs
O(log n) regardless of the order values arrive in, giving the whole sort O(n log n) time in the
best, average, and worst cases alike. An unbalanced tree sort, by contrast, degrades to O(n²) on
already-sorted input, since every insertion there just extends a straight chain. Consistently
sending values that compare equal to an existing node into the right subtree is also what makes
this sort stable: an in-order traversal always emits equal elements in the same relative order they
were inserted, since none of them is ever allowed to end up to the left of an equal predecessor.
