Selection Bogosort follows Selection Sort's plan, find the minimum of whatever's left, move it to the front, then
repeat on the remainder, but finds that minimum by luck instead of by scanning. For each position, it repeatedly swaps
in a uniformly random element from the unplaced remainder and checks whether the element that landed in position is now
the smallest one left, giving up and drawing again if it is not.

Each draw targets the position currently being decided rather than reshuffling the full array or swapping an unrelated
pair. Selection Bogosort is therefore a variant of Less
Bogosort, the same "shuffle a range until its front element is the minimum" idea, just narrowed to a single random swap
per attempt instead of reshuffling the whole remaining range each time.
