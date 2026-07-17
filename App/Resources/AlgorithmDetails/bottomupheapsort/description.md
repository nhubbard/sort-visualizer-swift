Bottom-up heapsort (sometimes called "heapsort with bounce") is a variant built around a simple observation: ordinary
heapsort's sift-down step spends two comparisons per level it descends — one to find the larger of two children, one to
check that child against the value being sifted — but the second comparison is often unnecessary. This variant instead
treats the value being sifted as if it were negative infinity while descending, so it only ever needs the one comparison
per level to always follow the larger child, all the way down to a leaf. Only once it reaches that leaf does it climb
back up, now comparing the real value against each ancestor in turn, to find the exact level where it actually belongs —
and it's the climb, not the descent, that finally moves anything.

That trade cuts the average number of comparisons roughly in half compared to plain top-down heapsort, since descending
is now unconditional rather than a comparison-and-branch at every step; the saving only shows up on average, though,
since the worst case still needs the same order of comparisons plain heapsort does. It matters most when each comparison
is expensive — comparing by a function call rather than a raw integer check — which is also why it's framed as an
optimization rather than a different algorithm.
