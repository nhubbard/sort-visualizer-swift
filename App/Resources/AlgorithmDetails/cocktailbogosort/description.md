*From Wikipedia, the free encyclopedia*

Cocktail Bogo Sort is a bidirectional variant of Less Bogo Sort. Where Less Bogo Sort only ever shrinks an unsorted
suffix from the front of the array, Cocktail Bogo Sort maintains a shrinking window `[lo, hi)` and inspects both ends of
that window on every iteration: if the window's first element is already less than or equal to every other element still
inside the window, it is confirmed as the window's minimum and `lo` advances past it; otherwise, if the window's last
element is already greater than or equal to every other element inside the window, it is confirmed as the window's
maximum and `hi` retreats past it. Only when neither end can be confirmed does the algorithm reshuffle the entire
current window and check again.

This two-sided check is the algorithm's whole contribution over its ancestor: on any given pass it can make progress
from either end, so a lucky shuffle that happens to seat the correct minimum at the front and the correct maximum at the
back in the same pass shrinks the window from both sides at once. In practice this changes nothing about the algorithm's
fundamentally random, guess-and-check nature — the window still only shrinks when a fresh shuffle happens to land a
boundary element correctly, and the number of reshuffles needed to sort even a small array remains governed by the same
factorial-growth randomness that makes every member of the Bogosort family impractical.

Despite living in ArrayV's `sorts/distribute/` package for implementation convenience, Cocktail Bogo Sort belongs
squarely to ArrayV's "Impractical Sorts" family alongside Bogosort, Bozosort, and Less Bogo Sort itself — it shares
their defining trait of relying on random chance rather than any deterministic comparison strategy to make progress, and
offers no meaningful improvement to the underlying algorithm's astronomical expected running time.
