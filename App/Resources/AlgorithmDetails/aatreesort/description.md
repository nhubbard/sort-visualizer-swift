*From Wikipedia, the free encyclopedia*

An AA tree is a form of balanced binary search tree, designed as a simplification of the
red-black tree. Rather than coloring each node red or black and reasoning about a handful of
recoloring and rotation cases, an AA tree gives every node a single integer "level," and enforces
balance through just two restructuring operations, skew and split, applied uniformly on the way
back up from every insertion. The result is a tree with the same logarithmic height guarantee as a
red-black tree, but with an implementation that is noticeably shorter and easier to get right.

The level of a node roughly tracks the number of left-leaning "horizontal" links between it and
the leaves below it; a missing child is treated as having level -1 so that every real leaf sits at
level 0. Two invariants keep the tree balanced: a left child must have a strictly smaller level
than its parent, and a right child's level must be no greater than its parent's, with a right
grandchild's level required to be strictly smaller than its grandparent's. Skew fixes a left
child that has crept up to the same level as its parent by rotating right, promoting that left
child to take the parent's place. Split fixes a right-leaning chain of three nodes at the same
level by rotating left and bumping the new subtree root's level up by one. Every insertion walks
down the tree in the usual binary-search-tree fashion to find where the new value belongs, then
unwinds back up the recursion applying skew followed by split at each node it passes through,
which is enough to restore both invariants everywhere without needing to look more than one level
away from the current node.

Sorting with an AA tree is the same recipe as any other binary-search-tree sort: insert every
value one at a time, then read the result back out with an in-order traversal that visits each
node's left subtree, then the node itself, then its right subtree. What sets it apart from a plain
unbalanced tree sort is that the skew and split rebalancing keeps the tree's height proportional to
the logarithm of the number of elements no matter what order the values arrive in, so insertion,
and therefore the whole sort, runs in O(n log n) time in the best, average, and worst case alike —
there is no adversarial or already-sorted input that degrades an AA tree into the linked-list-like
shape that ruins an unbalanced binary search tree's running time.

Because new values that compare equal to an existing node are always sent into the right subtree
during insertion, an in-order traversal reads equal elements back out in the same relative order
they were inserted in, making this a stable sort.
