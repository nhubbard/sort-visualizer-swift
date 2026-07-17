def next_power_of_two(n):
    k = 1
    while k < n:
        k <<= 1
    return k


def circle_sort_routine(array, lo, hi, end):
    if lo == hi:
        return 0
    low = lo
    high = hi
    mid = (hi - lo) // 2
    swaps = 0
    while lo < hi:
        if hi < end and array[lo] > array[hi]:
            array[lo], array[hi] = array[hi], array[lo]
            swaps += 1
        lo += 1
        hi -= 1
    swaps += circle_sort_routine(array, low, low + mid, end)
    if low + mid + 1 < end:
        swaps += circle_sort_routine(array, low + mid + 1, high, end)
    return swaps


def sort(arr):
    end = len(arr)
    if end == 0:
        return
    padded_length = next_power_of_two(end)
    swaps = None
    while swaps != 0:
        swaps = circle_sort_routine(arr, 0, padded_length - 1, end)


if __name__ == "__main__":
    array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56]
    sort(array)
    print(array)
