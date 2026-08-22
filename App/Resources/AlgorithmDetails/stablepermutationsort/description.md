Stable Permutation Sort walks through permutations of the array using the same recursive swap-based scheme as Heap's
algorithm, but with one deliberate twist: instead of stepping from one arrangement to the next with a plain swap, it
steps by *rotating* a chain of positions one place over. An index array tracks which original slot each position
currently holds, so the rotation can be undone and redone as the recursion backtracks, and the search still stops the
moment the array happens to be sorted.

The rotation, rather than a swap, is the whole point of the "stable" in the name: it's meant to reach a sorted
arrangement that also keeps equal elements in their original relative order, without the extra bookkeeping a true stable
sort usually needs. In practice, whether that guarantee actually holds for every input is a separate question from
whether the algorithm sorts correctly — it always produces a sorted array, but the specific enumeration order this
rotation trick walks through doesn't reliably land on the *stable* arrangement first.
