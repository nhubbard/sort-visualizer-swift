def partition(array, low, high):
    if array[low] > array[high]:
        array[low], array[high] = array[high], array[low]
    j = low + 1
    g = high - 1
    k = low + 1
    p = array[low]
    q = array[high]
    while k <= g:
        if array[k] < p:
            array[k], array[j] = array[j], array[k]
            j = j + 1
        elif array[k] >= q:
            while array[g] > q and k < g:
                g = g - 1
            array[k], array[g] = array[g], array[k]
            g = g - 1
            if array[k] < p:
                array[k], array[j] = array[j], array[k]
                j = j + 1
        k = k + 1
    j = j - 1
    g = g + 1
    array[low], array[j] = array[j], array[low]
    array[high], array[g] = array[g], array[high]
    return j, g


def dual_pivot_quick_sort(array, low, high):
    if low < high:
        j, g = partition(array, low, high)
        dual_pivot_quick_sort(array, low, j - 1)
        dual_pivot_quick_sort(array, j + 1, g - 1)
        dual_pivot_quick_sort(array, g + 1, high)


def sort(arr):
    dual_pivot_quick_sort(arr, 0, len(arr) - 1)


if __name__ == "__main__":
    array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56]
    sort(array)
    print(array)
