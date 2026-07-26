*From Wikipedia, the free encyclopedia*

Exchange Bogo Sort is a randomized sorting algorithm that repeatedly picks two uniformly random indices into the array
and swaps the elements they hold, but only when that particular swap would actually fix a genuine inversion between the
two — that is, only when the element at the lower index is greater than the element at the higher index. Every other
draw of indices, including one where the pair already sits in the correct relative order or where the two indices happen
to be equal, is simply discarded and a new pair is drawn on the next iteration. This continues, iteration after
iteration, until a full pass over the array finds every adjacent pair already in non-decreasing order.

This makes Exchange Bogo Sort meaningfully less chaotic than its namesake: classic Bogosort gambles on shuffling the
*entire* array into a fresh random permutation each round and hoping the whole thing lands sorted at once, while a
single blind random swap, as used by Bozosort, has no requirement that the swap improve anything at all. Exchange Bogo
Sort instead only ever accepts a swap that is already known to reduce disorder between the two positions it touches, so
unlike either of those, no single accepted move can ever make the array less sorted than it was a moment before. What it
retains from its relatives is the complete absence of any strategy for *which* pair of positions to examine next — the
choice of indices is always uniform and memoryless, so a run can spend an arbitrarily long stretch drawing pairs that
are already in order, or that are equal, before it happens to land on a real inversion.

Exchange Bogo Sort is categorized among the "Impractical Sorts," grouped with Bogosort, Bozosort, Less Bogosort, and
Cocktail Bogosort — sorts that, whatever their mechanics, share no practical use beyond illustrating what an algorithm
without any real search strategy looks like in practice.

Because no accepted swap is guaranteed to bring the array meaningfully closer to sorted — a swap fixing one inversion
can easily be followed by many rounds of draws that touch already-ordered or coincident positions before another genuine
inversion is found and fixed — the number of iterations Exchange Bogo Sort needs is a genuinely open-ended random
variable with no fixed upper bound. This sets it apart from deterministic exchange sorts such as Bubble Sort, whose
comparison-and-swap passes are guaranteed to terminate within a fixed number of passes bounded by the array's length,
regardless of how the input happens to be arranged.
