*From Wikipedia, the free encyclopedia*

Circle Sort is a comparison-based sorting algorithm built around a simple symmetric idea: compare the first element of a
range against the last, the second against the second-to-last, and so on, swapping any out-of-order pair as the two
pointers converge toward the middle. A single such pass never fully sorts the array on its own, but repeating it enough
times drives every element into place, in the same spirit as [Bubble Sort](https://en.wikipedia.org/wiki/Bubble_sort)
repeating its own single-direction pass until no swap occurs.

This **recursive** formulation reaches smaller ranges by genuine recursion rather than by iterating over explicitly
shrinking gap sizes: after a range's converging compare-and-swap pass finishes, the algorithm recurses once into the
first half and once into the second half, each of which performs its own converging pass before recursing further still.
The recursion bottoms out at ranges of a single element, where there is nothing left to compare. Because the two
recursive calls only ever operate on strictly smaller ranges, the whole recursive sweep still amounts to one "round" of
Circle Sort, exactly like a single pass of the iterative version — and, just as with the iterative form, a full
recursive sweep must be repeated until one of them completes without performing a single swap.

Circle Sort conventionally treats its working range as a power of two, since the converging pass divides evenly at every
level. An array whose real length isn't a power of two is handled by conceptually padding the recursion's bound up to
the next power of two while guarding every actual read, write, and comparison against the true array length — positions
beyond that length are skipped rather than accessed, but the pointers are still allowed to converge past them so the
recursive split points land in the same places they would for a same-sized power-of-two array.

Circle Sort is not a [stable sort](https://en.wikipedia.org/wiki/Sorting_algorithm#Stability): its compare-and-swap
pairs can be far apart in the array, so equal elements are not guaranteed to keep their original relative order. It
sorts in place, needing no auxiliary array — its only real memory cost beyond the input is the recursion stack itself.
