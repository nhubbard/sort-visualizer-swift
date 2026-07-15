def sort(arr):
    n = len(arr)
    flags = [False] * n

    def merge(i, j):
        if arr[i] < arr[j]:
            flags[j] = not flags[j]
            arr[i], arr[j] = arr[j], arr[i]

    for i in range(n - 1, 0, -1):
        j = i
        while (j & 1) == (1 if flags[j >> 1] else 0):
            j >>= 1
        gparent = j >> 1
        merge(gparent, i)

    for i in range(n - 1, 1, -1):
        arr[0], arr[i] = arr[i], arr[0]
        x = 1
        while True:
            y = 2 * x + (1 if flags[x] else 0)
            if y >= i:
                break
            x = y
        while x > 0:
            merge(0, x)
            x >>= 1
    arr[0], arr[1] = arr[1], arr[0]

array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
print(array)
