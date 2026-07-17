def quick_sort(array, p, r):
    if p >= r:
        return

    pivot = array[p + (r - p + 1) // 2]
    i = p
    j = r

    while i <= j:
        while array[i] < pivot:
            i += 1
        while array[j] > pivot:
            j -= 1
        if i <= j:
            array[i], array[j] = array[j], array[i]
            i += 1
            j -= 1

    if p < j:
        quick_sort(array, p, j)
    if i < r:
        quick_sort(array, i, r)


def sort(arr):
    quick_sort(arr, 0, len(arr) - 1)


if __name__ == "__main__":
    array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56]
    sort(array)
    print(array)
