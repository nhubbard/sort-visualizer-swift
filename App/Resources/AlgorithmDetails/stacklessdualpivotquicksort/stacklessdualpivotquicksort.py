INSERTION_THRESHOLD = 24


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


def partition(arr, start, end, scratch):
    """Dual-pivot partition of arr[start:end]. `scratch` is a fixed index outside this range,
    borrowed briefly as scratch space by the closing rotation and immediately restored. Returns
    the boundary between the low region and everything at or above the smaller of the two
    pivots."""
    m1 = (start + start + end) // 3
    m2 = (start + end + end) // 3

    if arr[m1] > arr[m2]:
        arr[m1], arr[start] = arr[start], arr[m1]
        end -= 1
        arr[m2], arr[end] = arr[end], arr[m2]
    else:
        arr[m2], arr[start] = arr[start], arr[m2]
        end -= 1
        arr[m1], arr[end] = arr[end], arr[m1]

    low = start
    high = end
    # Reversed from the usual low/high naming: after the swaps above, `start` holds the larger
    # of the two chosen medians and `end` the smaller. Neither position moves again until the
    # closing rotation below, so their values are safe to hold onto directly.
    pivot_max = arr[start]
    pivot_min = arr[end]

    k = low + 1
    while k < high:
        if arr[k] < pivot_min:
            low += 1
            arr[k], arr[low] = arr[low], arr[k]
        elif arr[k] >= pivot_max:
            while True:
                high -= 1
                if not (high > k and arr[high] >= pivot_max):
                    break
            arr[k], arr[high] = arr[high], arr[k]
            if arr[k] < pivot_min:
                low += 1
                arr[k], arr[low] = arr[low], arr[k]
        k += 1

    arr[start], arr[low] = arr[low], arr[start]
    # Three-way rotation: the value at `end` moves to `scratch`, whatever was borrowed from
    # `scratch` moves to `high`, and whatever was at `high` moves to `end`.
    displaced = arr[end]
    arr[end] = arr[high]
    arr[high] = arr[scratch]
    arr[scratch] = displaced

    return low


def quick_sort(arr, start, end):
    """Sorts arr[start:end] in place with no recursion: a single loop processes one segment at
    a time, shrinking and partitioning it down to INSERTION_THRESHOLD elements, finishing with
    binary_insertion_sort, then advancing past it to the next segment."""
    # Move every copy of this range's maximum value to the very end first. Those elements are
    # already correctly placed relative to everything else, so the rest of the algorithm never
    # has to look at them again — and the boundary in front of them becomes fixed scratch space
    # `partition` can borrow from.
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
    # refresh one of its two candidates, since reusing them would just compare equal again.
    reuse_median_candidates = True

    while True:
        while segment_end - a > INSERTION_THRESHOLD:
            if not reuse_median_candidates:
                m = (a + a + segment_end) // 3
                arr[a], arr[m] = arr[m], arr[a]
            segment_end = partition(arr, a, segment_end, tail)

        binary_insertion_sort(arr, a, segment_end)

        a = segment_end + 1
        if a >= tail:
            if a - 1 < tail:
                arr[a - 1], arr[tail] = arr[tail], arr[a - 1]
            return

        segment_end = lower_bound_index(arr, a, tail, a - 1)
        arr[a - 1], arr[tail] = arr[tail], arr[a - 1]

        reuse_median_candidates = True
        while a < segment_end and arr[a - 1] == arr[a]:
            reuse_median_candidates = False
            a += 1
        if a == segment_end:
            reuse_median_candidates = True


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
