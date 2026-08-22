def comp_swap(arr, a, b, end):
    if b < end and arr[a] > arr[b]:
        arr[a], arr[b] = arr[b], arr[a]


def sort(arr):
    length = len(arr)
    end = length

    n = 1
    while n < length:
        n <<= 1

    k = n >> 1
    while k > 0:
        j = 0
        while j < length:
            for i in range(k):
                comp_swap(arr, j + i, j + k + i, end)
            j += k << 1
        k >>= 1

    k = 2
    while k < n:
        m = k >> 1
        while m > 0:
            j = 0
            while j < length:
                p = m
                while p < ((k - m) << 1):
                    for i in range(m):
                        comp_swap(arr, j + p + i, j + p + m + i, end)
                    p += m << 1
                j += k << 1
            m >>= 1
        k <<= 1


if __name__ == "__main__":
    array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56]
    sort(array)
    print(array)
