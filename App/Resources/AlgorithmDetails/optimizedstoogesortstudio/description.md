Optimized Stooge Sort (the "Studio" version, named for the distinction from the similarly
named `OptimizedStoogeSort`) reworks plain [Stooge Sort](https://en.wikipedia.org/wiki/Stooge_sort)'s
recursive structure to bring the exponent down from `O(n^2.71)` to a genuine `O(n^2)` worst case,
with `O(n)` best-case behavior on already-nearly-sorted data — a real complexity improvement, not
just a constant-factor tweak. It's credited to EilrahcF's original concept, aphitorite's
sorting-network optimizations, and Anonymous0726's range-flagging refinements.

The recursive routine, `stoogeSort(a, m, b, merge)`, partitions the range `[a, b)` at two points —
`a2` and `b2`, each roughly a third of the way across — rather than Stooge Sort's simple midpoint
split, and tracks whether either partition actually changed anything. That change-tracking is what
gives the algorithm its `O(n)` best case: if a recursive call reports "nothing moved," the
optimized version skips a follow-up re-verification pass that plain Stooge Sort would have to
perform unconditionally, since there's nothing left to settle.

Unlike most of the other "impractical" and exchange-family sorts covered here, this one is
explicitly documented — in the original source code — as a *stable* sort. That claim is taken
seriously but not on faith: an empirical fuzz test that replays the algorithm's actual recorded
swaps against randomized duplicate-heavy input, confirming equal-valued elements never cross their
original relative order, backs up the documented stability rather than assuming it from the name
or comment alone.
