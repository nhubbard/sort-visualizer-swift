Guess Sort is the plainest member of the guessing family it lent its name to: the same base-`n` odometer of index
guesses as Optimized Guess Sort and Smart Guess Sort, but checked with a deliberately brute-force validity test instead
of a quick adjacent-pair scan. For every guess, it counts, over every pair of output positions, how many guessed indices
coincide (catching a guess that reuses the same source index twice), and separately counts how many pairs come out of
order in either direction. A guess is only accepted once both counts land on exactly the value that means "every index
is used once, and nothing is out of order."

Unlike its two descendants, this version never stops early once it finds a working guess — it keeps incrementing the
odometer all the way through the entire `n^n` space, remembering only the *last* valid guess it happened to pass along
the way, and applies that one at the very end. When the array has repeated values there can be several equally-valid
guesses scattered through that space; which one this algorithm lands on is simply whichever the odometer reaches last,
not necessarily the first it could have stopped at.
