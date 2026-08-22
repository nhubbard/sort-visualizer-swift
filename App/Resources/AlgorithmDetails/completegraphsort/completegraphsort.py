import math


def comp_swap(arr, a, b):
    if arr[a] > arr[b]:
        arr[a], arr[b] = arr[b], arr[a]


def split(arr, a, m, b):
    if b - a < 2:
        return
    c, len1 = 0, (b - a) // 2
    odd = (b - a) % 2 == 1
    if odd:
        if m - a > b - m:
            c, a = a, a + 1
        else:
            b -= 1
            c = b
    for s in range(len1):
        i = a
        for j in range(s, len1):
            comp_swap(arr, i, m + j)
            i += 1
        for j in range(s):
            comp_swap(arr, i, m + j)
            i += 1
    if odd:
        if c < m:
            for j in range(len1):
                comp_swap(arr, c, m + j)
        else:
            for j in range(len1):
                comp_swap(arr, a + j, c)


def sort(arr):
    n = len(arr)
    d, end = 2, 1 << int(math.log(n - 1) / math.log(2) + 1)
    while d <= end:
        i, dec = 0, 0
        while i < n:
            j = i
            dec += n
            while dec >= d:
                dec -= d
                j += 1
            k = j
            dec += n
            while dec >= d:
                dec -= d
                k += 1
            split(arr, i, j, k)
            i = k
        d *= 2


if __name__ == "__main__":
    array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56]
    sort(array)
    print(array)
