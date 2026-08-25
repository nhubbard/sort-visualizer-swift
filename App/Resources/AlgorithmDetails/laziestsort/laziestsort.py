import math


def binary_insertion_sort(arr, lo, hi):
    for i in range(lo + 1, hi):
        key = arr[i]
        left, right = lo, i
        while left < right:
            mid = (left + right) // 2
            if arr[mid] <= key:
                left = mid + 1
            else:
                right = mid
        j = i
        while j > left:
            arr[j] = arr[j - 1]
            j -= 1
        arr[left] = key


def swap_range(arr, a, b, length):
    for i in range(length):
        arr[a + i], arr[b + i] = arr[b + i], arr[a + i]


def rotate(arr, lo, mid, hi):
    # Swaps the two adjacent blocks arr[lo:mid] and arr[mid:hi] so their order is reversed,
    # using no auxiliary storage: the smaller of the two remaining pieces is always swapped
    # whole against an equal-sized piece of the other, which shrinks one piece to nothing a
    # little at a time until both are exhausted.
    left_len, right_len = mid - lo, hi - mid
    if left_len == 0 or right_len == 0:
        return
    i, j = left_len, right_len
    while i != j:
        if i < j:
            swap_range(arr, mid - i, mid + j - i, i)
            j -= i
        else:
            swap_range(arr, mid - i, mid, j)
            i -= j
    swap_range(arr, mid - i, mid, i)


def gallop(arr, lo, hi, value):
    # First index in [lo, hi) whose element is not less than `value`, found by doubling the
    # step size until it overshoots and then binary-searching the resulting bracket, rather
    # than scanning one element at a time. Assumes arr[lo] < value.
    left = lo
    step = 1
    right = lo + step
    while right < hi and arr[right] < value:
        left = right
        step *= 2
        right = lo + step
    right = min(right, hi)
    while right - left > 1:
        mid = (left + right) // 2
        if arr[mid] < value:
            left = mid
        else:
            right = mid
    return right


def merge(arr, lo, mid, hi):
    # Merges the sorted run arr[lo:mid] into the sorted run arr[mid:hi] in place. `left`
    # tracks the first not-yet-placed element of the left run, and `right` tracks the start
    # of the not-yet-consumed remainder of the right run.
    left, right = lo, mid
    while left < right < hi:
        if arr[left] <= arr[right]:
            left += 1
        else:
            boundary = gallop(arr, right, hi, arr[left])
            rotate(arr, left, right, boundary)
            left += boundary - right
            right = boundary


def sort(arr):
    n = len(arr)
    if n <= 16:
        binary_insertion_sort(arr, 0, n)
        return

    block_size = max(16, math.isqrt(n))
    lo = 0
    while lo < n:
        binary_insertion_sort(arr, lo, min(lo + block_size, n))
        lo += block_size

    # Merge blocks back to front: the already-sorted run always starts at `merged_start`,
    # and each step folds the block immediately before it into that run.
    num_blocks = (n + block_size - 1) // block_size
    merged_start = (num_blocks - 1) * block_size
    for i in range(num_blocks - 2, -1, -1):
        left_start = i * block_size
        merge(arr, left_start, merged_start, n)
        merged_start = left_start


if __name__ == "__main__":
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
    ]
    sort(array)
    print(array)
