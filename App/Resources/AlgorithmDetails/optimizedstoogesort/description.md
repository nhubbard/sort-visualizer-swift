Optimized Stooge Sort, despite the name it shares with `OptimizedStoogeSortStudio`, is a distinct
algorithm — refactored from a technique described by Amit Kishor and Pankaj Pratap Singh in
["An Optimized Stooge Sort Algorithm"](https://www.ijitee.org/wp-content/uploads/papers/v8i12/L31671081219.pdf).
Rather than Stooge Sort's recursive divide-and-conquer structure, it reaches a sorted array through
three purely iterative passes.

The first pass, `exchange`, walks two pointers inward from both ends of the array at once,
comparing and swapping `values[left]` against `values[right]` as they converge toward the middle —
settling the array's overall minimum and maximum into their correct end positions in a single
sweep, similar in spirit to a cocktail shaker sort's first pass. The two passes that follow are
shrinking-triangle sweeps: `forward` repeatedly compares `values[left]` against `values[right]`
while `left` climbs toward `right`, then resets `left` back to the start and shrinks `right` by one
before repeating; `backward` is its mirror image, sweeping `right` down toward `left` and resetting
`right` back to its starting point while growing `left` by one each time.

Every compare-and-swap in all three passes operates on a pair of indices that are, in general, far
apart — nothing here ever compares strictly adjacent elements the way an insertion or bubble sort
does. That distant-index pairing means equal-valued elements can easily be carried past one another
during a swap, so Optimized Stooge Sort does not preserve the original relative order of ties and is
not a stable sort.
