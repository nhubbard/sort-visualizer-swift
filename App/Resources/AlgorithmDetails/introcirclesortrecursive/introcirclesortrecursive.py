def circle_sort_routine(array, lo, hi, end):
    if lo == hi:
        return 0
    low, high = lo, hi
    mid = (hi - lo) // 2
    swap_count = 0
    while lo < hi:
        if hi < end and array[lo] > array[hi]:
            array[lo], array[hi] = array[hi], array[lo]
            swap_count += 1
        lo += 1
        hi -= 1
    swap_count += circle_sort_routine(array, low, low + mid, end)
    if low + mid + 1 < end:
        swap_count += circle_sort_routine(array, low + mid + 1, high, end)
    return swap_count


def binary_insertion_sort(array, end):
    for i in range(1, end):
        value = array[i]
        lo = 0
        hi = i
        while lo < hi:
            mid = lo + (hi - lo) // 2
            if value < array[mid]:
                hi = mid
            else:
                lo = mid + 1
        j = i
        while j > lo:
            array[j] = array[j - 1]
            j -= 1
        array[lo] = value


def sort(arr):
    end = len(arr)
    if end <= 1:
        return
    n = 1
    threshold = 0
    while n < end:
        n <<= 1
        threshold += 1
    threshold //= 2

    iterations = 0
    while True:
        iterations += 1
        if iterations >= threshold:
            binary_insertion_sort(arr, end)
            return
        if circle_sort_routine(arr, 0, n - 1, end) == 0:
            return


if __name__ == "__main__":
    array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56]
    sort(array)
    print(array)
