def sort(arr):
    n = len(arr)

    def sift_down(i, b):
        j = i
        while 2 * j + 1 < b:
            if 2 * j + 2 < b:
                j = 2 * j + 2 if arr[2 * j + 2] > arr[2 * j + 1] else 2 * j + 1
            else:
                j = 2 * j + 1
        while arr[i] > arr[j]:
            j = (j - 1) // 2
        while j > i:
            arr[i], arr[j] = arr[j], arr[i]
            j = (j - 1) // 2

    for i in range((n - 1) // 2, -1, -1):
        sift_down(i, n)

    for i in range(n - 1, 0, -1):
        arr[0], arr[i] = arr[i], arr[0]
        sift_down(0, i)

array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
print(array)
