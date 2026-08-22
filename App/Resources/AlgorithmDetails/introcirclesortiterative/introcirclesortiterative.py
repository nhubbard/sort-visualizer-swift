def circle_sort_routine(array, length, end):
    swap_count = 0
    gap = length // 2
    while gap > 0:
        start = 0
        while start + gap < end:
            low = start
            high = start + 2 * gap - 1
            while low < high:
                if high < end and array[low] > array[high]:
                    array[low], array[high] = array[high], array[low]
                    swap_count += 1
                low += 1
                high -= 1
            start += 2 * gap
        gap //= 2
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
        if circle_sort_routine(arr, n, end) == 0:
            return


if __name__ == "__main__":
    array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56]
    sort(array)
    print(array)
