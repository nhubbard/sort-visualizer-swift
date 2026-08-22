Quick Bogosort takes Quicksort's pivot-and-partition idea and hands the partitioning over to chance: it picks the first
element of a range as the pivot, then repeatedly shuffles the whole range at random — carefully tracking which position
the pivot's value ends up at through every shuffle — until the shuffle happens to leave everything before the pivot no
greater than it and everything after no less. Once that partition is found, it recurses into each side independently,
exactly as ordinary Quicksort would.

The tracking is what keeps this from being nonsensical: a shuffle scrambles every element's position, so without
following the pivot value specifically, there would be no way to know which element to partition around afterward.
Everything else about *finding* that partition is left entirely to luck — there's no scanning, no comparison-driven
placement, just repeated random reshuffling until the arrangement happens to satisfy the one condition Quicksort
actually needs from its partition step.
