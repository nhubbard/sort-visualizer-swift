Ternary Heap Sort is an ordinary extract-max heapsort with one number changed: every node has three children instead of
two, so a node at position `i` looks after positions `3i + 1`, `3i + 2`, and `3i + 3` instead of the usual pair.
Building the heap and repeatedly extracting its root works exactly the same way it does for a binary heap — sift the
largest child up when it beats its parent, recurse down, then move the root to the end of the shrinking heap and
re-sift.

A wider branching factor means the tree is shallower for the same number of elements, so each sift touches fewer
levels — but each level now costs up to three comparisons to find the largest child instead of one, so the two effects
trade off against each other rather than one straightforwardly beating the other. It's the same idea Base-N Max Heap
Sort generalizes to an arbitrary configurable branching factor, just fixed at three and given its own name.
