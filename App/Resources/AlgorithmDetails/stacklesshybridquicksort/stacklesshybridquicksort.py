INSERTION_THRESHOLD = 16


def median_of_three(arr, start, end):
    """Arranges arr[start], arr[mid], arr[end - 1] so the median of the three ends up at
    `start`, ready to serve as partition's pivot."""
    mid = start + (end - 1 - start) // 2
    if arr[start] > arr[mid]:
        arr[start], arr[mid] = arr[mid], arr[start]
    if arr[mid] > arr[end - 1]:
        arr[mid], arr[end - 1] = arr[end - 1], arr[mid]
        if arr[start] > arr[mid]:
            return
    arr[start], arr[mid] = arr[mid], arr[start]


def partition(arr, start, end):
    """Classic two-pointer Hoare partition against the pivot median_of_three just placed at
    `start`. Returns the pivot's final resting index."""
    median_of_three(arr, start, end)
    pivot = arr[start]
    i, j = start, end

    while True:
        i += 1
        while i < j and arr[i] < pivot:
            i += 1
        j -= 1
        while j >= i and arr[j] >= pivot:
            j -= 1
        if i < j:
            arr[i], arr[j] = arr[j], arr[i]
        else:
            arr[start], arr[j] = arr[j], arr[start]
            return j


def lower_bound_index(arr, start, end, target_index):
    """Finds where the value at target_index belongs among arr[start:end], ties resolving
    toward the front (a plain lower-bound binary search)."""
    lo, hi = start, end
    while lo < hi:
        mid = lo + (hi - lo) // 2
        if arr[target_index] <= arr[mid]:
            hi = mid
        else:
            lo = mid + 1
    return lo


def binary_insertion_sort(arr, start, end):
    """Sorts arr[start:end] in place using a plain binary-search insertion sort — the base case
    once a segment shrinks small enough that further partitioning isn't worth it."""
    for i in range(start, end):
        value = arr[i]
        lo, hi = start, i
        while lo < hi:
            mid = lo + (hi - lo) // 2
            if value < arr[mid]:
                hi = mid
            else:
                lo = mid + 1
        j = i - 1
        while j >= lo:
            arr[j + 1] = arr[j]
            j -= 1
        arr[lo] = value


def quick_sort(arr, start, end):
    """Sorts arr[start:end] in place with no recursion: a single loop processes one segment at
    a time, shrinking and partitioning it down to INSERTION_THRESHOLD elements, finishing with
    binary_insertion_sort, then advancing past it to the next segment."""
    # Move every copy of this range's maximum value to the very end first. Those elements are
    # already correctly placed relative to everything else, so the rest of the algorithm never
    # has to look at them again — and the boundary in front of them becomes the fixed resting
    # place `partition` sends each finished pivot out to.
    max_value = arr[start]
    for i in range(start + 1, end):
        max_value = max(max_value, arr[i])

    tail = end
    for i in range(end - 1, start - 1, -1):
        if arr[i] == max_value:
            tail -= 1
            arr[i], arr[tail] = arr[tail], arr[i]

    a = start
    segment_end = tail
    # False right after skipping a run of duplicates below means the next median-of-three should
    # refresh its candidates, since reusing them would just compare equal again.
    refresh_median = True

    while True:
        while segment_end - a > INSERTION_THRESHOLD:
            if refresh_median:
                median_of_three(arr, a, segment_end)
            pivot_index = partition(arr, a, segment_end)
            arr[pivot_index], arr[tail] = arr[tail], arr[pivot_index]
            segment_end = pivot_index

        binary_insertion_sort(arr, a, segment_end)

        a = segment_end + 1
        if a >= tail:
            if a - 1 < tail:
                arr[a - 1], arr[tail] = arr[tail], arr[a - 1]
            return

        segment_end = lower_bound_index(arr, a, tail, a - 1)
        arr[a - 1], arr[tail] = arr[tail], arr[a - 1]

        refresh_median = True
        while a < segment_end and arr[a - 1] == arr[a]:
            refresh_median = False
            a += 1
        if a == segment_end:
            refresh_median = True


def sort(arr):
    n = len(arr)
    if n < 2:
        return
    quick_sort(arr, 0, n)


array = [
    55,
    12,
    84,
    3,
    47,
    91,
    26,
    68,
    8,
    73,
    40,
    97,
    15,
    62,
    34,
    79,
    21,
    88,
    5,
    51,
    66,
    29,
    44,
    12,
    78,
    33,
    91,
    6,
    58,
    12,
]
sort(array)
print(array)
