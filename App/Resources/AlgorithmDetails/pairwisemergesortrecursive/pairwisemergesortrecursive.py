def comp_swap(arr, a, b, end):
    if b < end and arr[a] > arr[b]:
        arr[a], arr[b] = arr[b], arr[a]


def pairwise_merge(arr, a, b, end):
    m = (a + b) // 2
    m1 = (a + m) // 2
    g = m - m1

    for i in range(m - m1):
        j = m1
        k = g
        while k > 0:
            comp_swap(arr, j + i, j + i + k, end)
            k >>= 1
            j -= k - (i & k)
    if b - a > 4:
        pairwise_merge(arr, m, b, end)


def pairwise_merge_sort(arr, a, b, end):
    m = (a + b) // 2
    i, j = a, m
    while i < m:
        comp_swap(arr, i, j, end)
        i += 1
        j += 1
    if b - a > 2:
        pairwise_merge_sort(arr, a, m, end)
        pairwise_merge_sort(arr, m, b, end)
        pairwise_merge(arr, a, b, end)


def sort(arr):
    length = len(arr)
    end = length

    n = 1
    while n < length:
        n <<= 1

    pairwise_merge_sort(arr, 0, n, end)


if __name__ == "__main__":
    array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56]
    sort(array)
    print(array)
