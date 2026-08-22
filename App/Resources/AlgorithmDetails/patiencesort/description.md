*From Wikipedia, the free encyclopedia*

Patience sorting is a sorting technique named for its resemblance to the card game patience, or
solitaire. It works in two distinct phases: dealing the cards into piles, and then collecting them
back up in order.

In the dealing phase, each value is placed on top of the leftmost pile whose current top card is
greater than or equal to it. If no such pile exists, a new pile is started to its right. This rule
guarantees an invariant: read left to right, the piles' top cards are always non-decreasing, which
is exactly what makes a binary search over the existing piles enough to find each new card's
destination in logarithmic time rather than a linear scan through every pile.

Once every value has been dealt, the piles hold the input rearranged into runs, but not yet in
final sorted order. The collection phase repeatedly finds whichever pile currently has the smallest
top card and removes it, building up the fully sorted sequence one value at a time. Because
removing a card can expose a much larger one underneath — breaking the tidy non-decreasing
arrangement the dealing phase relied on — this phase needs its own efficient way to track the
current minimum across all piles, typically a priority queue, to avoid falling back to a slow
linear search every time.

Patience sorting is closely related to the problem of finding the longest increasing subsequence of
a sequence: the number of piles the dealing phase produces equals the length of the longest
non-increasing subsequence of the input (or, with the opposite tie-breaking convention, the longest
increasing subsequence), a fact that has made variants of this technique useful well beyond sorting
itself, including in some implementations of the Unix `diff` utility.
