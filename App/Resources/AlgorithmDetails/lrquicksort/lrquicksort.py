def quick_sort(array, p, r):
    while p < r:
        pivot = array[p + (r - p + 1) // 2]
        i, j = p, r
        while i <= j:
            while array[i] < pivot:
                i += 1
            while array[j] > pivot:
                j -= 1
            if i <= j:
                array[i], array[j] = array[j], array[i]
                i += 1
                j -= 1
        if j - p < r - i:
            if p < j:
                quick_sort(array, p, j)
            p = i
        else:
            if i < r:
                quick_sort(array, i, r)
            r = j


def sort(arr):
    quick_sort(arr, 0, len(arr) - 1)


if __name__ == "__main__":
    array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56]
    sort(array)
    print(array)
