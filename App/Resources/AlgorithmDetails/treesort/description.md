*From Wikipedia, the free encyclopedia*

A tree sort builds a binary search tree from the elements of the input, then produces the sorted
result by walking that tree in order. Inserting into a binary search tree is itself a simple
recursive process: compare the new value against the value at the current node, then recurse into
the left subtree if it's smaller or the right subtree otherwise, until an empty spot is found. Once
every element has been inserted this way, an in-order traversal — visit the left subtree, then the
current node, then the right subtree — reads every value back out in ascending order, because that
is precisely the ordering property a binary search tree maintains at every node.

This unbalanced (or "naive") form of tree sort makes no attempt to keep the tree's height under
control, unlike a self-balancing variant such as a red-black tree or a splay tree. For random input
this tends not to matter much, since a randomly-built binary search tree is balanced enough in
expectation to give the same O(n log n) running time an efficient comparison sort achieves.
Adversarial or already-sorted input is a different story: inserting values in increasing order into
an unbalanced tree produces a tree that is really just a linked list leaning entirely to one side,
with height equal to the number of elements, which drags the running time down to O(n²) — the same
degradation an unbalanced binary search tree suffers for lookups generally.

Whether new elements that compare equal to an existing node are sent left or right is a free choice
in the general algorithm, but it isn't an arbitrary one: consistently sending equal elements to one
particular side, rather than deciding arbitrarily on a per-insertion basis, is what makes an in-order
traversal preserve their original relative order and gives the sort its stability.
