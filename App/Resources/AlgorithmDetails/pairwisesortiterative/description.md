*From Wikipedia, the free encyclopedia*

A [sorting network](https://en.wikipedia.org/wiki/Sorting_network) is a comparator-based sorting algorithm whose
sequence of compare-and-swap operations is fixed in advance and does not depend on the input data — the same wires fire
in the same order no matter what values are being sorted, so only the outcome of each comparison (whether it triggers a
swap) is data-dependent, never the sequence of positions being compared. This makes sorting networks especially
attractive for hardware and parallel implementations, where a predetermined schedule of independent comparisons can be
pipelined or evaluated concurrently.

The [pairwise sorting network](https://en.wikipedia.org/wiki/Pairwise_sorting_network) was discovered by Ian Parberry
and published in 1992, and has exactly the same size (comparator count) and depth as Ken Batcher's earlier odd-even
mergesort network, despite arriving at that same efficiency by a very different route. Parberry's construction is guided
by the zero-one principle — since a comparison network sorts every sequence of arbitrary values correctly if and only if
it sorts every sequence of 0s and 1s correctly, it suffices to design and verify the network purely in terms of bits.
Conceptually, the input is first divided into pairs and each pair is internally sorted; those pairs are then merged into
lexicographic order (all "00" pairs before all "01"/"10" pairs before all "11" pairs) by a further sequence of
comparators.

Where Batcher's odd-even mergesort repeatedly divides the input, recursively sorts the halves, and merges each pair of
sorted halves before moving on to the next level, Parberry's network structures the same total work differently: it
performs all of its subdivision first, and only afterward performs all of its merging, in the reverse order the
subdivision happened in. The two constructions end up mathematically equivalent in cost, but the pairwise network's
distinctive two-phase shape — a forward doubling pass followed by a separate cleanup pass with shrinking strides — is
what gives this family of networks its name and its somewhat less immediately recognizable structure compared to
Batcher's more familiar recursive-merge presentation.

This iterative implementation is notable for working correctly at any array length, not merely at exact powers of two.
Sorting-network constructions are ordinarily defined only for power-of-two input sizes, and porting a fixed network to
an arbitrary size typically means conceptually building the network over the next power of two above the real length and
discarding every comparator that would touch an out-of-range index — the same technique this codebase's Bose-Nelson port
uses. Here, by contrast, every loop bound in both phases is already written in terms of the real length directly, so no
separate padding step or out-of-range guard is needed at all — the loop conditions that advance the comparator cursor
are themselves what keeps every comparison in bounds.

As with other fixed comparator networks, the total comparator count depends only on the input's length, never on the
values themselves, so best-case, average-case, and worst-case running time are identical. Comparators only ever swap on
a strict "greater than" test, but — as with other networks built from many indirect comparator chains rather than one
direct comparison per pair of equal elements — two equal elements that are never compared against each other directly
can still end up transposed as a side effect of each one separately swapping against a third, unequal element elsewhere
in the network, so this is not a stable sort.
