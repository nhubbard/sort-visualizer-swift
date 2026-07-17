def compare3(arr, a, b):
    if arr[a] == arr[b]:
        return 0
    return 1 if arr[a] > arr[b] else -1


def select_pivot(arr, lo, hi):
    mid = (lo + hi) // 2
    c_lo_mid = compare3(arr, lo, mid)
    if c_lo_mid == 0:
        return lo
    c_lo_hi = compare3(arr, lo, hi - 1)
    c_mid_hi = compare3(arr, mid, hi - 1)
    if c_lo_hi == 0 or c_mid_hi == 0:
        return hi - 1

    if c_lo_mid < 0:
        return mid if c_mid_hi < 0 else (hi - 1 if c_lo_hi < 0 else lo)
    else:
        return mid if c_mid_hi > 0 else (lo if c_lo_hi < 0 else hi - 1)


def partition_ternary_ll(arr, lo, hi):
    p = select_pivot(arr, lo, hi)
    arr[p], arr[hi - 1] = arr[hi - 1], arr[p]
    pivot_index = hi - 1

    i = lo
    k = hi - 1

    j = lo
    while j < k:
        cmp = compare3(arr, j, pivot_index)
        if cmp == 0:
            k -= 1
            arr[k], arr[j] = arr[j], arr[k]
            j -= 1
        elif cmp < 0:
            arr[i], arr[j] = arr[j], arr[i]
            i += 1
        j += 1

    for s in range(hi - k):
        arr[i + s], arr[hi - 1 - s] = arr[hi - 1 - s], arr[i + s]

    return i, i + (hi - k)


def quicksort_ternary_ll(arr, lo, hi):
    if lo + 1 < hi:
        first, second = partition_ternary_ll(arr, lo, hi)
        quicksort_ternary_ll(arr, lo, first)
        quicksort_ternary_ll(arr, second, hi)


def sort(arr):
    quicksort_ternary_ll(arr, 0, len(arr))


if __name__ == "__main__":
    array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56]
    sort(array)
    print(array)
