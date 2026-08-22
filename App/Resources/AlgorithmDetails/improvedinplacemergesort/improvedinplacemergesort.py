def push(array, p, a, b):
    if a == b:
        return
    temp = array[p]
    array[p] = array[a]
    for i in range(a + 1, b):
        array[i - 1] = array[i]
    array[b - 1] = temp


def merge(array, a, m, b):
    i, j = a, m
    while i < m and j < b:
        if array[i] > array[j]:
            j += 1
        else:
            push(array, i, m, j)
            i += 1
    while i < m:
        push(array, i, m, b)
        i += 1


def merge_sort(array, a, b):
    m = a + (b - a) // 2
    if b - a > 2:
        if b - a > 3:
            merge_sort(array, a, m)
        merge_sort(array, m, b)
    merge(array, a, m, b)


def sort(arr):
    n = len(arr)
    merge_sort(arr, 0, n)


if __name__ == "__main__":
    array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56]
    sort(array)
    print(array)
