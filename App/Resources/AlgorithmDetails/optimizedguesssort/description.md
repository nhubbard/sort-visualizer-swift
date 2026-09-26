Optimized Guess Sort plays the same "guess an index for every output position" game as Random Guess Sort, but replaces
the random draw with a deterministic one: the guessed indices are treated as an odometer, a counter in base n with n
digits, incremented by one every time a guess fails the same non-decreasing-with-a-tie-break check Random Guess Sort
uses. Where Random Guess Sort might redraw the same bad guess twice by chance, this variant is guaranteed to try every
one of the nⁿ possible index sequences exactly once, in a fixed order, before it could ever repeat itself.

The search still covers every possible sequence of index guesses rather than only the n! permutations. Deterministic
enumeration gives the number of attempts a finite upper bound instead of making it an open-ended random variable.
