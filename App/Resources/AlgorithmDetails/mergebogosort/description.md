Merge Bogosort follows Merge Sort's divide-and-conquer outline exactly — recursively sort each half, then merge the two
sorted halves back together — but leaves the merge step itself to chance. Rather than comparing the fronts of the two
sorted runs and picking the smaller one at each step, it repeatedly guesses a random interleaving of the two
already-sorted runs and checks whether the result happens to come out sorted, keeping the guess only once it does.

Since both runs are genuinely sorted by the time the guessing starts, there's always at least one interleaving that
works — the same one an ordinary merge would compute directly — so this never gets stuck. What it gives up is the
certainty of finding that interleaving on the first try: a real merge takes it in one deliberate pass, while this
version is betting on a random guess landing on one of the (possibly several, if there are ties) correct interleavings
out of every way the two runs could be woven together.
