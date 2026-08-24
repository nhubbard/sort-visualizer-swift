*From Wikipedia, the free encyclopedia*

Introspective Circle Sort (Recursive) is a hybrid variant of the recursive form of Circle Sort that adds a fixed pass
budget on top of Circle Sort's ordinary "keep recursing until a full pass makes no swaps" behavior, plus a guaranteed
fallback to finish the job if that budget runs out first. The word "introspective" describes this same trick as it
appears in Introsort: rather than trusting an algorithm to always behave well, a second, slower-but-dependable
algorithm stands ready to take over the moment the first one has used up its allotted effort without finishing.

Plain recursive Circle Sort works on a range of the array bounded by two indices. It folds that range inward from
both ends toward the middle, comparing and swapping each mirrored pair of positions it meets along the way, then
splits the range in half at its midpoint and recurses into each half using the exact same fold-inward step. The
recursion bottoms out once a call is handed a range containing only a single position, at which point there is
nothing left to fold. One entire top-level call over the whole array — the initial fold plus every nested call it
spawns — is one "pass." Whether that pass swapped anything at all is discovered by summing the swap counts every
recursive call returns; a pass that swaps nothing means the array is already sorted, since no fold at any level of
recursion found a pair worth exchanging. In practice this tends to converge within roughly as many passes as the
array's size has binary digits, but nothing about the recursion itself proves that every possible arrangement of
values converges that quickly — only that it eventually must, since a finite array has a finite number of
arrangements. Introspective Circle Sort (Recursive) does not wait to find out how long "eventually" might take for a
given input. Before running a single pass, it computes a budget from the array's length alone: how many times the
length can be doubled from one up to and past that length, halved again. That number bounds how many passes the
algorithm is willing to attempt.

Each pass still runs the exact same fold-and-recurse structure as plain recursive Circle Sort. If a pass ever
finishes having made no swaps, the array is already sorted and the algorithm stops right there, exactly as it would
without any budget at all — an array that Circle Sort resolves quickly is not made to do any extra work. But if the
budget of passes is exhausted before that happens, the algorithm gives up on further passes entirely and instead
runs one complete binary insertion sort over the whole array: a search-then-shift pass with a well-understood worst
case, and no risk of running longer than that no matter how the earlier, abandoned passes left the data.

This combination trades a small amount of typical-case performance — the budget occasionally cuts off a
recursion-based approach that might have finished the job in only slightly more passes — for a hard ceiling on how
much total work the algorithm can ever do. Left to run to completion, recursive Circle Sort converges in O(n log n)
comparisons on favorable input and in O(n log^2 n) on average, the extra log n factor coming from how many passes a
typical arrangement needs before a pass finally swaps nothing. Introspective Circle Sort (Recursive)'s pass budget is
sized to cut off right around where that average case would otherwise land, so best- and average-case behavior track
plain recursive Circle Sort's own O(n log n) and O(n log^2 n) figures closely. Once the budget is actually exhausted,
though, the binary insertion sort fallback takes over, and its own shifting step degrades to O(n^2) on an input that
is still far from sorted — the one case where this algorithm's total work departs from Circle Sort's and lands on a
hard, provable ceiling instead of an open-ended one.

Because a pass that gets abandoned partway through the algorithm's overall run has already applied every swap it
made for real, and Circle Sort's fold-inward comparisons can shift two equal elements out of their original relative
order without ever comparing them directly to each other, Introspective Circle Sort (Recursive) inherits Circle
Sort's own lack of stability. The binary insertion sort that finishes the job is stable on its own, but it can only
preserve whatever order the array is already in by the time it starts running — it cannot undo reordering that
earlier passes already committed. Its recursive calls consume stack space proportional to the depth of the
range-splitting, but beyond that it sorts in place, using no auxiliary array of its own.
