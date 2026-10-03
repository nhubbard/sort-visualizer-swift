Bubble sort is a stable comparison sort that repeatedly compares adjacent elements and exchanges a pair when it is out
of order. Each pass moves the largest remaining value to the end of the unsorted part of the array. The next pass can
therefore stop one position earlier. Once all passes are complete, every value is in order.

This fixed-pass variant makes the same number of comparisons regardless of the initial order. It does not stop early
when a pass makes no swaps, so even an already sorted array takes quadratic time. Average and worst-case time are also
O(n²). Only loop counters are needed outside the array, giving constant auxiliary space. Equal values are not swapped
with one another, so their original relative order is preserved. Variants that track whether a pass made any swaps can
finish earlier on sorted input, but that early-exit rule is absent here.
