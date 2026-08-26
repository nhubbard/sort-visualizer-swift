RECENCY = 8
EARLY_OUT_TEST_AT = 4
EARLY_OUT_DISORDER_FRACTION = 0.6


def quicksort(arr, lo, hi):
    """A plain general-purpose sort for arr[lo:hi], used both as the early-out fallback and to
    sort the leftover "dropped" elements before the final merge. Any decent O(n log n) sort
    works here — the algorithm doesn't depend on which one."""
    if hi - lo <= 1:
        return
    pivot = arr[lo + (hi - lo) // 2]
    less, equal, greater = [], [], []
    for i in range(lo, hi):
        if arr[i] < pivot:
            less.append(arr[i])
        elif arr[i] > pivot:
            greater.append(arr[i])
        else:
            equal.append(arr[i])
    quicksort(less, 0, len(less))
    quicksort(greater, 0, len(greater))
    arr[lo:hi] = less + equal + greater


def sort(arr):
    length = len(arr)
    if length < 2:
        return

    dropped = []
    num_dropped_in_a_row = 0
    read = 0
    write = 0
    iteration = 0
    early_out_stop = length // EARLY_OUT_TEST_AT

    while read < length:
        iteration += 1
        if (
            iteration == early_out_stop
            and len(dropped) > read * EARLY_OUT_DISORDER_FRACTION
        ):
            # Too disordered for the adaptive approach to be worth it: flush what's been
            # dropped so far back into the array and fall back to a plain full sort.
            for value in dropped:
                arr[write] = value
                write += 1
            dropped.clear()
            quicksort(arr, 0, length)
            return

        if write == 0 or arr[read] >= arr[write - 1]:
            # In order — keep it.
            arr[write] = arr[read]
            write += 1
            read += 1
            num_dropped_in_a_row = 0
        elif num_dropped_in_a_row == 0 and write >= 2 and arr[read] >= arr[write - 2]:
            # Quick undo: the element two back would have accepted this one just fine, so
            # drop the one right before it instead of the new element.
            dropped.append(arr[write - 1])
            arr[write - 1] = arr[read]
            read += 1
        elif num_dropped_in_a_row < RECENCY:
            dropped.append(arr[read])
            read += 1
            num_dropped_in_a_row += 1
        else:
            # Accepting something `num_dropped_in_a_row` elements back made every subsequent
            # element drop — that accept was a mistake. Undo it, and any other recently
            # accepted elements bigger than the dropped run's maximum.
            del dropped[len(dropped) - num_dropped_in_a_row :]
            read -= num_dropped_in_a_row

            num_backtracked = 1
            write -= 1

            max_of_dropped = arr[read]
            for i in range(read + 1, read + num_dropped_in_a_row + 1):
                max_of_dropped = max(max_of_dropped, arr[i])

            while write >= 1 and max_of_dropped < arr[write - 1]:
                write -= 1
                num_backtracked += 1

            for i in range(write, write + num_backtracked):
                dropped.append(arr[i])

            num_dropped_in_a_row = 0

    for offset, value in enumerate(dropped):
        arr[write + offset] = value

    quicksort(arr, write, length)

    # Copy the now-sorted dropped tail before the final backward merge starts overwriting
    # arr[write:] in place.
    buffer = arr[write : write + len(dropped)]

    i = len(buffer) - 1
    j = write - 1
    k = length - 1

    while i >= 0:
        if j < 0 or buffer[i] > arr[j]:
            arr[k] = buffer[i]
            k -= 1
            i -= 1
        else:
            arr[k] = arr[j]
            k -= 1
            j -= 1


array = [
    0,
    1,
    2,
    3,
    4,
    9,
    6,
    7,
    8,
    5,
    10,
    11,
    12,
    13,
    14,
    15,
    21,
    17,
    18,
    19,
    20,
    16,
    22,
    23,
    24,
    28,
    26,
    27,
    25,
    29,
]
sort(array)
print(array)
