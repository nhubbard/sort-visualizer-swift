*From Wikipedia, the free encyclopedia*

Cocktail Shaker Sort, also known as bidirectional bubble sort, cocktail sort, shaker sort, ripple sort, shuffle sort, or
shuttle sort, is an extension of [Bubble Sort](https://en.wikipedia.org/wiki/Bubble_sort). The algorithm extends bubble
sort by operating in two directions: each pass sweeps forward through the unsorted portion of the array carrying the
largest remaining value to the end, then immediately sweeps backward carrying the smallest remaining value to the
beginning.

Like bubble sort, Cocktail Shaker Sort is a comparison sort that repeatedly steps through the list, compares adjacent
pairs of elements, and swaps them if they are in the wrong order. Because it shrinks the unsorted window from both ends
on every full pass rather than only one end, it tends to move a few out-of-place elements — so-called "turtles" that sit
near the wrong end of the array — into position considerably faster than a plain one-directional bubble sort would.

The sort terminates early whenever a complete forward-and-backward pass makes no swaps, since that means the array is
already sorted. In the best case, when the input is already sorted, this happens on the very first pass, giving the
algorithm a best-case running time of O(n). In the average and worst cases it still degrades to the same O(n^2)
comparisons and swaps as bubble sort, since neither algorithm changes the fundamental number of adjacent-swap operations
needed to sort an arbitrary permutation.

Cocktail Shaker Sort is stable, since it only ever swaps adjacent elements and only does so when the earlier element
compares strictly greater than the later one, leaving equal elements in their original relative order. It sorts in place
and requires no auxiliary storage beyond a handful of loop counters.
