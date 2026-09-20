def sort(arr):
    quick_sort(arr, 0, len(arr) - 1)

def partition(array, start, end):
    i, j = start, end
    while i < j:
        while i < j and array[i] <= array[start]:
            i += 1
        while array[j] > array[start]:
            j -= 1
        if i < j:
            array[i], array[j] = array[j], array[i]
    array[start], array[j] = array[j], array[start]
    return j


def quick_sort(array, start, end):
    if start >= end:
        return
    p = partition(array, start, end)
    quick_sort(array, start, p - 1)
    quick_sort(array, p + 1, end)




if __name__ == "__main__":
    array = [
        0, 39, 21, 62, 91, 77, 14, 23,
        90, 69, 51, 81, 68, 83, 32, 56,
    ]
    sort(array)
    print(array)
