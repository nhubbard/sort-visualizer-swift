*From Wikipedia, the free encyclopedia*

Classic Tree Sort builds an ordinary, unbalanced [binary search tree](https://en.wikipedia.org/wiki/Binary_search_tree)
over the elements of the input, then reads the sorted order back out by walking that tree in order. The first element
becomes the tree's root without any comparison at all. Every element after it is inserted by starting at the root and
repeatedly comparing the element being inserted against the current node: if it is strictly less, the walk continues
into that node's left child; otherwise — greater than, or equal to — it continues into the right child. Whenever the
walk reaches a child slot that does not exist yet, the element is attached there as a brand-new leaf, and the next
element's insertion begins again from the root. No rotation, rebalancing, or restructuring of any kind ever happens; the
tree simply grows leaf by leaf in whatever shape the input order happens to produce.

Once every element has been inserted, the array is sorted with a textbook in-order traversal: recursively visit a node's
left subtree, then the node itself, then its right subtree, starting from the root. Because every node's left subtree
holds only elements that compared as strictly smaller at insertion time, and its right subtree holds everything that
compared as greater-than-or-equal, this traversal necessarily visits every element from smallest to largest.

Routing ties (equal elements) consistently toward the same side — here, always to the right — combined with an in-order
traversal that always finishes a node's left subtree and the node itself before touching its right subtree, is exactly
what makes this particular arrangement of tree sort a *stable* one. A later-arriving element equal in value to one
already in the tree cannot overtake it: the new arrival retraces the exact same path through the tree that the earlier
element's insertion took, right up until it reaches that earlier element's node, ties against it, and is pushed into
that node's right subtree — which the traversal only visits after the earlier element has already been emitted. Not
every insertion-sort-in-disguise routes ties this cleanly, so this stability property is a direct consequence of the
specific left-strict / right-otherwise comparison rule chosen here, not an automatic feature of "build a BST and read it
back."

The cost of this approach depends entirely on how deep the tree ends up being, which in turn depends on the *order*
elements arrive in, not the sortedness of the final result. A favorable arrival order keeps the tree roughly balanced,
so each of the n insertions costs about O(log n), for an overall O(n log n) — the typical case for randomly ordered
input. An unfavorable arrival order, most notably an input that is already sorted (ascending or descending), makes every
single comparison agree with the last one, degenerating the tree into one long chain no different from a linked list;
the n-th insertion then costs O(n) all by itself, and the total degrades to O(n²), no better than a naive insertion
sort. Unlike some other insertion-family sorts, none of this happens in place — the tree's left/right child pointers and
the output buffer used for the final traversal are all separate arrays sized to the input, so the algorithm uses O(n)
auxiliary space regardless of how the comparisons happen to fall.
