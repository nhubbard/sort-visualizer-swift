*From Wikipedia, the free encyclopedia*

Introspective Circle Sort is a hybrid variant of the iterative Circle Sort algorithm that adds a fixed pass budget on
top of Circle Sort's ordinary "repeat until a pass makes no swaps" loop, and a guaranteed fallback to finish the job if
that budget runs out first. The word "introspective" describes this same trick as it appears in Introsort: rather than
trusting an algorithm to always behave well, a second, slower-but-dependable algorithm stands ready to take over the
moment the first one has used up its allotted effort without finishing.

Plain iterative Circle Sort folds each shrinking window of the array inward from both ends, comparing and swapping
out-of-order pairs, and keeps repeating that whole sweep until one sweep completes with no swaps at all. In practice
this tends to converge within roughly as many sweeps as the array's size has binary digits, but nothing about the sweep
itself proves that every possible arrangement of values converges that quickly — only that it eventually must, since a
finite array has a finite number of arrangements. Introspective Circle Sort does not wait to find out how long "
eventually" might take for a given input. Before running a single sweep, it computes a budget from the array's length
alone: how many times the length can be doubled from one up to and past that length, halved again. That number bounds
how many sweeps the algorithm is willing to attempt.

Each sweep still runs the exact same fold-inward comparisons as plain Circle Sort. If a sweep ever finishes having made
no swaps, the array is already sorted and the algorithm stops right there, exactly as it would without any budget at
all — an array that Circle Sort resolves quickly is not made to do any extra work. But if the budget of sweeps is
exhausted before that happens, the algorithm gives up on further sweeps entirely and instead runs one complete binary
insertion sort over the whole array: a search-then-shift pass with a well-understood worst case, and no risk of running
longer than that no matter how the earlier, abandoned sweeps left the data.

This combination trades a small amount of typical-case performance — the budget occasionally cuts off a sweep-based
approach that might have finished the job in only slightly more sweeps — for a hard ceiling on how much total work the
algorithm can ever do. Circle Sort by itself has no such ceiling; its total running time depends entirely on how many
sweeps a particular input happens to need, a number that is only ever bounded by the requirement that it must terminate,
not by a specific proven limit. Introspective Circle Sort closes that gap by making sure a dependable fallback is always
waiting in the wings.

Because a sweep that gets abandoned partway through the algorithm's overall run has already applied every swap it made
for real, and Circle Sort's fold-inward comparisons can shift two equal elements out of their original relative order
without ever comparing them directly to each other, Introspective Circle Sort inherits Circle Sort's own lack of
stability. The binary insertion sort that finishes the job is stable on its own, but it can only preserve whatever order
the array is already in by the time it starts running — it cannot undo reordering that earlier sweeps already committed.
It sorts in place, using only a constant amount of extra bookkeeping beyond the array itself.
