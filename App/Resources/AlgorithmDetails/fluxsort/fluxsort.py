INSERTION_THRESHOLD = 16


def insertion_sort(arr, lo, hi):
    for i in range(lo + 1, hi):
        key = arr[i]
        j = i - 1
        while j >= lo and arr[j] > key:
            arr[j + 1] = arr[j]
            j -= 1
        arr[j + 1] = key


def median_of_three(arr, a, b, c):
    # Returns whichever of a, b, c indexes the middle value of the three.
    if arr[a] > arr[b]:
        a, b = b, a
    if arr[b] > arr[c]:
        b = c
        if arr[a] > arr[b]:
            b = a
    return b


def flux_sort_range(arr, lo, hi, swap):
    n = hi - lo
    if n <= INSERTION_THRESHOLD:
        insertion_sort(arr, lo, hi)
        return

    mid = lo + n // 2
    pivot = arr[median_of_three(arr, lo, mid, hi - 1)]

    # Partition into arr (elements <= pivot) and swap (elements > pivot). Ties go to the low
    # side, which is what keeps the sort stable.
    low_write = lo
    high_write = 0
    for read in range(lo, hi):
        value = arr[read]
        if value > pivot:
            swap[high_write] = value
            high_write += 1
        else:
            arr[low_write] = value
            low_write += 1

    for i in range(high_write):
        arr[low_write + i] = swap[i]

    if low_write == hi:
        # Every element in range was <= pivot -- a run of duplicates around the pivot
        # value can cause this. There's no split to recurse into, so finish directly.
        insertion_sort(arr, lo, hi)
        return

    flux_sort_range(arr, lo, low_write, swap)
    flux_sort_range(arr, low_write, hi, swap)


def sort(arr):
    n = len(arr)
    if n < 2:
        return
    swap = [0] * n
    flux_sort_range(arr, 0, n, swap)


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
