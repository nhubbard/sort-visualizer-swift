Splay Sort inserts the input into a splay tree and retrieves the values through an in-order traversal. A splay tree is a self-adjusting binary search tree in which every time a node is
accessed, the tree restructures itself so that node moves all the way up to become the new root.
This restructuring, called splaying, happens through a sequence of tree rotations chosen based on
the accessed node's position relative to its parent and grandparent, and it applies whether the
access was a search, an insertion, or a deletion. Splay trees do not track any separate balance
information the way Adelson-Velsky and Landis (AVL) or red-black trees do. The splaying operation keeps the
tree from staying badly skewed for long, in an amortized sense, even though any single operation
can briefly leave it unbalanced.

Sorting with a splay tree follows a simple recipe: insert every value one at a time, each
insertion first splays the tree toward the new value's position, then attaches the new node at the
root, and finally read the values back out with a plain in-order traversal. Because splaying
brings recently- or nearby-accessed values close to the root, this approach is adaptive: an input
that arrives already sorted, or nearly so, tends to keep inserting new extreme values right at the
root with very little tree traversal, giving those cases close to linear running time. A random insertion order still costs logarithmic time per insertion on average, in the same amortized
sense that makes any splay tree operation efficient over a long enough sequence, even though the
tree offers no worst-case guarantee for any single access in isolation.
