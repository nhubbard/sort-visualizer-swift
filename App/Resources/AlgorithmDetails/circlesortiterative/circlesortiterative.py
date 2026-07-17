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


def sort(arr):
    end = len(arr)
    if end <= 1:
        return
    n = 1
    while n < end:
        n <<= 1

    number_of_swaps = 1
    while number_of_swaps != 0:
        number_of_swaps = circle_sort_routine(arr, n, end)


if __name__ == "__main__":
    array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56]
    sort(array)
    print(array)
