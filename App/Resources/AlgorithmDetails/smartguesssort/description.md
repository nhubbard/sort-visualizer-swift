Smart Guess Sort is Optimized Guess Sort with one refinement: instead of always incrementing the guessed-index odometer
starting from the very first digit, it first scans backward from the last position to find exactly where the current
guess first goes wrong, then only resets the digits *before* that point back to zero, carrying the increment from there
instead. Digits past the point of failure — the ones that were already fine — are left untouched rather than being reset
and immediately re-derived.

The effect is that it skips over large stretches of the `n^n` guess space that share an already-broken prefix, without
ever changing what counts as a valid final answer. It's still exploring the same enormous space Optimized Guess Sort
does, just walking through it in a way that wastes far fewer steps revisiting guesses that were doomed from the very
first digit — which is why this variant tolerates noticeably larger arrays than its plainer siblings before becoming
impractical.
