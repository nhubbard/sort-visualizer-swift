Bubble Bogosort is Bubble Sort with its deterministic, left-to-right sweep replaced by chance: instead of walking every
adjacent pair in a fixed order, it repeatedly picks a *random* adjacent pair and swaps the two elements if they're out
of order. Every accepted swap strictly fixes one inversion, exactly like ordinary Bubble Sort, but nothing guarantees
*which* inversion gets fixed next or how many draws land on a pair that's already in order.

That single change turns a textbook O(n²) algorithm into one with no fixed bound on its running time — a lucky run might
fix every inversion in a handful of draws, while an unlucky one can spend long stretches re-checking pairs that are
already correct before it happens to land on the one pair still out of place. It terminates with probability 1 (every
inversion is eventually drawn and, once found, is always fixed rather than reintroduced), but the number of draws needed
is an open-ended random variable rather than a guarantee.
