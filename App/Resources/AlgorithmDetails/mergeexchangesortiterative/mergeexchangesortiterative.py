import math


def merge_exchange_sort(array):
    n = len(array)
    if n <= 1:
        return
    t = int(math.log2(n - 1)) + 1
    p0 = 1 << (t - 1)
    p = p0
    while p > 0:
        q = p0
        r = 0
        d = p
        while True:
            for i in range(n - d):
                if (i & p) == r and array[i] > array[i + d]:
                    array[i], array[i + d] = array[i + d], array[i]
            if q == p:
                break
            d = q - p
            q >>= 1
            r = p
        p >>= 1


def sort(arr):
    merge_exchange_sort(arr)


if __name__ == "__main__":
    array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56]
    sort(array)
    print(array)
