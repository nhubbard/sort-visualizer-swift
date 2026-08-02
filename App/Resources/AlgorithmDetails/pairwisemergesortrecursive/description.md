The recursive form of Pairwise Merge Sort — see this codebase's iterative version for the general
background on [sorting networks](https://en.wikipedia.org/wiki/Sorting_network) this algorithm
belongs to. The recursive construction splits into two cooperating functions. One recurses into
its two halves, runs a single comparator pass across the midpoint separating them, and then hands
off to the second function to reconcile the two now-independently-sorted halves. That second
function does its own comparator work inline, using a bit-doubling stride pattern that halves a gap
value while a cursor walks backward by the freshly-halved amount, and recurses only into its own
second half to finish the job — the first half's comparator work is already complete by the time
that recursive call happens.

Like its iterative counterpart, this recursive form conceptually pads the real array length up to
the next power of two, with every comparator bounds-checked against the real length so any
comparison that would touch padding is simply skipped. Measuring the number of comparisons each
form performs across a wide range of array sizes shows they use exactly the same total, at every
size tested, despite the very different code shapes.

Like other fixed comparator networks, this one's total comparator count depends only on the
(padded) length of the input, so its best-case, average-case, and worst-case running times are
identical, landing at O(n log²n). Every comparator only ever swaps on a strict "greater than" test,
and this network never lets two equal elements cross paths without an intervening comparison
establishing their order, so it is a stable sort.
