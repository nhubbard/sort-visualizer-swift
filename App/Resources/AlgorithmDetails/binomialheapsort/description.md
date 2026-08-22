Binomial Heap Sort borrows the *shape* of a binomial heap's indexing scheme without building any actual tree of nodes —
it walks the array as if it were laid out the way a binomial heap's trees would be, using nothing but arithmetic on the
index itself. Starting from the last position and working backward, each element repeatedly merges with a "sibling"
found by shifting its index and checking a flag bit, climbing toward a shared ancestor position; whichever of the two
comparisons wins gets its flag flipped, the same reverse-bit trick Weak Heap Sort uses to defer half its comparisons.
That first backward pass builds the whole implicit structure in one go.

Extraction then repeats the usual heap pattern — take the front, move the last element there, and sift it back down —
except "down" here means following the flag bits outward from the root along whichever branch the bits point to, merging
with each node in turn until there's nowhere further to go. Because every step is computed from the index alone rather
than pointers into a real tree, this stays a pure array algorithm end to end: no extra structure is ever allocated, only
the flag bits threaded alongside the values being sorted.