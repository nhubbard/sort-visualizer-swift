Deterministic Bogosort keeps Bogosort's defining "try an arrangement, check if it is sorted, try another" shape but drops
the coin flip: it walks every permutation of the array using Heap's algorithm, a classic method for generating all n!
permutations one swap at a time with no repeats, checking after each swap whether the array happens to be sorted yet.
Where classic Bogosort's random reshuffle might land on the same wrong arrangement twice and has no memory of what it is
already tried, this version is guaranteed to reach every possible arrangement exactly once before it could ever cycle
back to where it started.

Unlike randomized Bogosort, this procedure reaches every permutation without repetition and therefore terminates after
at most n! permutation checks. It remains impractical because the number of permutations grows factorially.
